//
//  Copyright (Change Date see Readme), gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//
//  *******
//
//  For additional notes and disclaimer from gematik and in case of changes by gematik find details in the "Readme" file.
//

import ASN1Kit
import CryptoKit
import Foundation
import OpenAPIClientAttest
import OpenSSL
import Security

/// Service for building Trust for the current device
public protocol TrustService {
    /// Starts the registration process for the device
    ///
    /// If the device is not enrolled, this must be used to create initial mTLS certificate and the corresponding
    /// enrollment.
    @discardableResult
    func registration() async throws -> MTLSCert

    /// Request device attestation
    /// - Returns: A device token to prove attestation of this device, throws otherwise
    func requestAttestation() async throws -> DeviceToken

    /// Reset attestation
    func resetAttestation() async throws

    /// Retrieve a list of all registered devices for the user.
    /// - Parameter identifier: The user identifier
    /// - Returns: The list of devices
    func getDevices(for identifier: String) async throws -> [OpenAPIClientAttest.Components.Schemas.DeviceRegistration]

    /// Delete a device for a user
    /// - Parameters:
    ///   - userIdentifier: The user identifier to delete the device for
    ///   - deviceIdentifier: The device identifier to delete
    func deleteDevice(userIdentifier: String, deviceIdentifier: String) async throws
}

public enum TrustServiceError: Error {
    case readingCertificateFailed
    case storingMTLSCertificateFailed
    case genericAttestationError(String)
    case noKeypair
}

/// Default implementation for using GMS to build trust for the current device
/// See https://dsr.gematik.solutions/docs/rfcs/ for the concepts of this implementation
public class DefaultTrustService: TrustService {
    public init(client: TrustClient, osAttestationService: OSAttestationService) {
        self.client = client
        self.osAttestationService = osAttestationService
    }

    let client: TrustClient
    let osAttestationService: OSAttestationService
    var keypair: PrivateKeyContainer?
    var mtlsCert: MTLSCert?

    @MainActor
    @discardableResult
    public func registration() async throws -> MTLSCert {
        // 03 -> 05
        let nonce = try await client.getNonce()

        print(nonce.base64EncodedString())
        // 06
        let nonceContainer = NonceContainer(with: nonce)

        // 11
        let keypairmTLS: PrivateKeyContainer

        if let keypair = try? PrivateKeyContainer(with: "keypair.mTLS") {
            keypairmTLS = keypair
        } else {
            keypairmTLS = try PrivateKeyContainer.createFromSecureEnclave(with: "keypair.mTLS")
        }

        let csrContent = [
            CSRHelper.OID.countryName: "DE",
            .organizationName: "TRUST_CLIENT",
            .commonName: "TRUST_CLIENT",
            .challengePassword: nonceContainer.csrMTLS.base64EncodedString(),
        ]
        let csr = try CSRHelper.createCSR(keypair: keypairmTLS, content: csrContent)

        // 12 -> 13
        let challenge = try nonceContainer.integrity + Data(SHA256.hash(data: keypairmTLS.publicKeyData()))

        let attestationResult = try await osAttestationService.attest(challenge: challenge)

        // 14
        let jwtTokenPayload = DeviceRegistrationToken(
            pubkey: Data(SHA256.hash(data: try keypairmTLS.publicKeyData())),
            iat: Date(),
            nonce: nonce,
            csr: csr,
            keyId: attestationResult.keyId,
            attestation: attestationResult.attestation
        )

        let signer = try Brainpool256r1Signer(
            x5c: try Bundle.module.path(forResource: "x509-ec-bp256r1", ofType: "cer")?.readFileContents() ?? Data(),
            key: try Bundle.module.path(forResource: "x509-ec-key-bp256r1", ofType: "bin")?.readFileContents() ?? Data()
        )

        let header = JWT.Header(alg: .bp256r1, x5c: signer.certificates, typ: nil, kid: nil, cty: nil, jti: nil)

        let unsignedJWT = try JWT(header: header, payload: jwtTokenPayload)

        // 15
        // Sign JWT with smartcard
        let jwt = try unsignedJWT.sign(with: signer)

        let request = jwt.serialize().data(using: .utf8) ?? Data()

        // 17 -> 36
        let result = try await client.registerDevice(jwt: request)

        try storeCertificate(result as Data)
        keypair = keypairmTLS
        mtlsCert = result

        return result
    }

    private func storeCertificate(_ mTLSCertificate: Data) throws {
        guard let mTLSSecCertificate = SecCertificateCreateWithData(nil, mTLSCertificate as CFData) else {
            throw TrustServiceError.storingMTLSCertificateFailed
        }

        _ = SecItemAdd(
            [
                kSecValueRef: mTLSSecCertificate,
                kSecReturnPersistentRef: true,
            ] as [CFString: Any] as CFDictionary, nil
        )
    }

    // RFC 02
    public func requestAttestation() async throws -> DeviceToken {
        // 09 -> 11
        let nonce = try await client.getNonce()

        // 12
        var buffer = [UInt8](repeating: 0, count: 64)
        _ = SecRandomCopyBytes(kSecRandomDefault, buffer.count, &buffer)
        let pkceCodeVerifier = buffer.data.base64EncodedString()
        let pkceCodeChallenge = Data(SHA256.hash(data: pkceCodeVerifier.data(using: .ascii) ?? Data()))

        // 13
        let nonceAttest = SHA256.hash(data: nonce + ("1".data(using: .utf8) ?? Data()))

        // 17
        guard let keypair = keypair else {
            throw TrustServiceError.noKeypair
        }
        let fingerprint = Data(SHA256.hash(data: try keypair.publicKeyData()))
        let attestationChallenge = Data(SHA256.hash(data: nonceAttest + fingerprint))

        let attestation = try await osAttestationService.generateAssertion(challenge: attestationChallenge)

        // 18
        let attestationAttributes = AttestationToken.Attributes()
        let attestationToken = AttestationToken(
            pubkey: fingerprint,
            iat: Date(),
            nonce: nonce,
            assertion: attestation,
            deviceAttributes: attestationAttributes
        )

        let attestationHeader = JWT.Header(
            alg: .secp256r1,
            x5c: [
                mtlsCert ?? Data(),
            ],
            typ: "JWT"
        )

        let unsignedJWT = try JWT(header: attestationHeader, payload: attestationToken)

        // 19
        let jwt = try unsignedJWT.sign(with: keypair)

        // 20 -> 24
        let request = jwt.serialize().data(using: .utf8) ?? Data()

        print("PKCE Challenge:")
        print(pkceCodeChallenge.encodeBase64urlsafe().utf8string ?? "-")
        print("PKCE Verifier:")
        print(pkceCodeVerifier)

        print("Resource Access Token:")
        print(request.utf8string ?? "")

        let authCode = try await client.deviceAttestation(jwt: request, challenge: pkceCodeChallenge)

        sleep(2) // should be implemented by polling instead of plain sleeping

        print("AuthCode:")
        print(authCode.base64EncodedString())
        let deviceToken = try await client.deviceToken(authCode: authCode, verifier: pkceCodeVerifier)

        print("DeviceToken:")
        print(authCode.base64EncodedString())

        return deviceToken
    }

    public func resetAttestation() async throws {
        _ = try PrivateKeyContainer.deleteExistingKey(for: "keypair.mTLS")
    }

    public func getDevices(for identifier: String) async throws
        -> [OpenAPIClientAttest.Components.Schemas.DeviceRegistration] {
        try await client.devices(for: identifier)
    }

    public func deleteDevice(userIdentifier: String, deviceIdentifier: String) async throws {
        try await client.deleteDevice(userIdentifier: userIdentifier, deviceIdentifier: deviceIdentifier)
    }
}

public class MTLSSessionDelegate: NSObject, URLSessionDelegate {
    override public init() {}

    public weak var trustService: DefaultTrustService?

    public func urlSession(
        _: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        handleAuthenticationChallenge(challenge: challenge, completionHandler: completionHandler)
    }

    func handleAuthenticationChallenge(
        challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let protectionSpace = challenge.protectionSpace
        guard protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let identity = try? trustService?.keypair?.findSecIdentity() else {
            completionHandler(.useCredential, nil)
            return
        }

        let credential = URLCredential(identity: identity, certificates: nil, persistence: .forSession)

        completionHandler(.useCredential, credential)
    }
}

extension PrivateKeyContainer: JWTSigner {
    func sign(message: Data) throws -> Data {
        try sign(data: message).derToConcat()
    }
}

struct NonceContainer {
    let plain: Data
    let keypairMTLS: Data
    let csrMTLS: Data
    let integrity: Data
    let smartCard: Data

    init(with nonce: Data) {
        plain = nonce
        keypairMTLS = Data(SHA256.hash(data: nonce + ("KEYPAIR_MTLS".data(using: .utf8) ?? Data())))
        csrMTLS = Data(SHA256.hash(data: nonce + ("CSR_MTLS".data(using: .utf8) ?? Data())))
        integrity = Data(SHA256.hash(data: nonce + ("INTEGRITY".data(using: .utf8) ?? Data())))
        smartCard = Data(SHA256.hash(data: nonce + ("SMARTCARD".data(using: .utf8) ?? Data())))
    }
}
