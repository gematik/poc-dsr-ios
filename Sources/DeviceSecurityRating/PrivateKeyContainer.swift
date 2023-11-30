//
//  Copyright (c) 2023 gematik GmbH
//
//  Licensed under the Apache License, Version 2.0 (the License);
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an 'AS IS' BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import ASN1Kit
import Foundation
import Security

/// Represents a (SecureEnclave) private key, namely `PrK_SE_AUT`, secured by iOS Biometrics.
///
/// [REQ:gemSpec_IDP_Frontend:A_21590] This is the container to represent biometric keys. Usage is limited to
/// authorization purposes
struct PrivateKeyContainer {
    // sourcery: CodedError = "108"
    enum Error: Swift.Error {
        // sourcery: errorCode = "01"
        case keyNotFound(String)
        // sourcery: errorCode = "02"
        case unknownError(String)
        // sourcery: errorCode = "03"
        case retrievingPublicKeyFailed
        // sourcery: errorCode = "04"
        case creationFromBiometrie(Swift.Error?)
        // sourcery: errorCode = "05"
        case creationWithoutBiometrie(Swift.Error?)
        // sourcery: errorCode = "06"
        case convertingKey(Swift.Error?)
        // sourcery: errorCode = "07"
        case signing(Swift.Error?)
        // sourcery: errorCode = "08"
        case canceledByUser
    }

    let privateKey: SecKey
    let publicKey: SecKey

    let tag: String

    /// Initializes a `PrivateKeyContainer` for a given tag. Throws `PrivateKeyContainer.Error` in case of a failure.
    /// - Parameter tag: The `tag` or identifier of the key.
    /// - Throws: `PrivateKeyContainer.Error` in case of a failure.
    init(with tag: String) throws {
        let privateKey = try Self.findExistingKey(for: tag)

        try self.init(withTag: tag, privateKey: privateKey)
    }

    private init(withTag tag: String,
                 privateKey: SecKey) throws {
        self.tag = tag
        self.privateKey = privateKey
        publicKey = try Self.publicKeyForPrivateKey(privateKey)
    }

    private static func findExistingKey(for tag: String) throws -> SecKey {
        // Keychain Query
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                    kSecAttrKeySizeInBits as String: 256,
                                    kSecAttrApplicationTag as String: tag,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            let message = SecCopyErrorMessageString(status, nil).map { String($0) } ?? "Not Found"

            if status == errSecItemNotFound {
                throw Error.keyNotFound(message)
            }

            throw Error.unknownError(message)
        }

        return (item as! SecKey) // swiftlint:disable:this force_cast
    }

    func findSecIdentity() throws -> SecIdentity {
        // Keychain Query
        let query: [String: Any] = [kSecClass as String: kSecClassIdentity,
                                    kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                                    kSecAttrKeySizeInBits as String: 256,
                                    kSecAttrApplicationTag as String: tag,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnRef as String: true]
        var item: CFTypeRef?
        let status: OSStatus = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess else {
            let message = SecCopyErrorMessageString(status, nil).map { String($0) } ?? "Not Found"

            if status == errSecItemNotFound {
                throw Error.keyNotFound(message)
            }

            throw Error.unknownError(message)
        }

        return (item as! SecIdentity) // swiftlint:disable:this force_cast
    }

    /// Deletes an existing secure enclave key.
    /// - Parameter tag: The `tag` or identifier of the key.
    /// - Throws: `PrivateKeyContainer.Error` in case of a failure or a missing key.
    /// - Returns: `true` in case of a success, `throws` otherwise.
    static func deleteExistingKey(for tag: String) throws -> Bool {
        // Keychain Query
        let query: [String: Any] = [kSecClass as String: kSecClassKey,
                                    kSecAttrApplicationTag as String: tag]

        let status: OSStatus = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess else {
            let message = SecCopyErrorMessageString(status, nil).map { String($0) } ?? "Not Found"

            if status == errSecItemNotFound {
                throw Error.keyNotFound(message)
            }

            throw Error.unknownError(message)
        }

        return true
    }

    private static func publicKeyForPrivateKey(_ privateKey: SecKey) throws -> SecKey {
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            throw Error.retrievingPublicKeyFailed
        }
        return publicKey
    }

    /// Creates a `PrivateKeyContainer` with a given tag. Throws `PrivateKeyContainer.Error` in case of a failure.
    /// - Parameter tag: The `tag` or identifier of the key.
    /// - Throws: `PrivateKeyContainer.Error` in case of a failure or a missing key.
    /// - Returns: An instance of `PrivateKeyContainer` if successful.
    static func createFromSecureEnclave(with tag: String) throws -> Self {
        var error: Unmanaged<CFError>?

        guard let access =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            // [REQ:gemSpec_IDP_Frontend:A_21586] prevents migration to other devices
                                            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                                            // [REQ:gemSpec_IDP_Frontend:A_21582] method selection
                                            // [REQ:gemSpec_IDP_Frontend:A_21587] via `.privateKeyUsage`
                                            [.privateKeyUsage],
                                            &error) else {
            guard let error = error else {
                throw Error.unknownError("Access Control creation failed")
            }
            throw Error.creationFromBiometrie(error.takeRetainedValue() as Swift.Error)
        }

        let attributes: [String: Any] = [
            // [REQ:gemSpec_IDP_Frontend:A_21581,A_21589] Algorithm selection
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            // [REQ:gemSpec_IDP_Frontend:A_21589] Key length
            kSecAttrKeySizeInBits as String: 256,
            // [REQ:gemSpec_IDP_Frontend:A_21578,A_21579,A_21580,A_21583] Enforced via access attribute
            kSecAttrTokenID as String: kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access,
            ] as [String: Any],
        ]

        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw Error.creationFromBiometrie(error?.takeRetainedValue())
        }
        return try Self(withTag: tag, privateKey: privateKey)
    }

    /// key creation without secure enclave for integration tests. Only available for simulator builds to enable
    /// integration tests.
    static func createFromKeyChain(with tag: String) throws -> Self {
        var error: Unmanaged<CFError>?

        guard let access =
            SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                            kSecAttrAccessibleWhenUnlocked,
                                            [.privateKeyUsage],
                                            &error) else {
            guard let error = error else {
                throw Error.unknownError("Access Control creation failed")
            }
            throw Error.creationWithoutBiometrie(error.takeRetainedValue() as Swift.Error)
        }

        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: tag,
                kSecAttrAccessControl as String: access,
            ] as [String: Any],
        ]

        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw Error.creationWithoutBiometrie(error?.takeRetainedValue())
        }
        return try Self(withTag: tag, privateKey: privateKey)
    }

    func publicKeyData() throws -> Data {
        var error: Unmanaged<CFError>?

        let keyData = SecKeyCopyExternalRepresentation(publicKey, &error)

        guard let unwrappedKeyData = keyData else {
            throw Error.convertingKey(error?.takeRetainedValue())
        }

        return unwrappedKeyData as Data
    }

    func asn1PublicKey() throws -> ASN1Object {
        let asn1 = ASN1Data.constructed(
            [
                create(tag: .universal(.sequence), data: ASN1Data.constructed(
                    [
                        try ObjectIdentifier.from(string: "1.2.840.10045.2.1").asn1encode(),
                        try ObjectIdentifier.from(string: "1.2.840.10045.3.1.7").asn1encode(),
                    ]
                )),

                try publicKeyData().asn1bitStringEncode(),
            ]
        )
        return create(tag: .universal(.sequence), data: asn1)
    }

    /// Sign the given `Data` with the private key.
    /// - Parameter data: Data to sign with the private key.
    /// - Throws: `PrivateKeyContainer.Error` in case of a failure or a missing key.
    /// - Returns: Data in concat format containing the Signature `r` | `s`.
    func sign(data: Data) throws -> Data {
        let algorithm: SecKeyAlgorithm = .ecdsaSignatureMessageX962SHA256

        guard SecKeyIsAlgorithmSupported(privateKey, .sign, algorithm) else {
            throw Error.unknownError("Algorithm not supported")
        }

        var error: Unmanaged<CFError>?

        // [REQ:gemSpec_IDP_Frontend:A_21584] private key usage triggers biometric unlock
        guard let signature = SecKeyCreateSignature(privateKey,
                                                    algorithm,
                                                    data as CFData,
                                                    &error) as Data? else {
            let error = error?.takeRetainedValue()

            if let error = error,
               CFErrorGetDomain(error) as String? == "com.apple.LocalAuthentication" {
                throw Error.canceledByUser
            }

            throw Error.signing(error)
        }

        return signature
    }
}

// sourcery: CodedError = "107"
public enum ConversionError: Swift.Error {
    // sourcery: errorCode = "01"
    case generic(String?)
}

extension Data {
    // From jose4j EcdsaUsingShaAlgorithm.java
    func derToConcat() throws -> Data {
        let wholeASN1 = try ASN1Decoder.decode(asn1: self)
        let sequence = try Array(from: wholeASN1)

        guard sequence.count == 2 else {
            throw ConversionError.generic("Error converting EC signature. Expected 2 elements, found \(sequence.count)")
        }

        let signatureR = try Data(from: sequence[0]).dropLeadingZeroByte.padWithLeadingZeroes(totalLength: 32)
        let signatureS = try Data(from: sequence[1]).dropLeadingZeroByte.padWithLeadingZeroes(totalLength: 32)

        return signatureR + signatureS
    }

    func asn1encoded() throws -> Data {
        let wholeASN1 = try ASN1Decoder.decode(asn1: self)
        let sequence = try Array(from: wholeASN1)

        guard sequence.count == 2 else {
            throw ConversionError.generic("Error converting EC signature. Expected 2 elements, found \(sequence.count)")
        }

        let signatureR = try Data(from: sequence[0]).dropLeadingZeroByte.padWithLeadingZeroes(totalLength: 32)
        let signatureS = try Data(from: sequence[1]).dropLeadingZeroByte.padWithLeadingZeroes(totalLength: 32)

        let asn1Obj: ASN1Object = create(tag: .universal(.sequence), data: ASN1Data.constructed([
            signatureR.asn1encode(tag: .universal(.integer)),
            signatureS.asn1encode(tag: .universal(.integer)),
        ]))
        return try Data([0x00]) + asn1Obj.serialize()
    }
}

extension Data {
    var dropLeadingZeroByte: Data {
        if first == 0x0 {
            return dropFirst()
        } else {
            return self
        }
    }

    func padWithLeadingZeroes(totalLength: Int) -> Data {
        if count >= totalLength {
            return self
        } else {
            return Data(count: totalLength - count) + self
        }
    }
}
