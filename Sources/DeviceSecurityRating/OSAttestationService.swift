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

import CryptoKit
import DeviceCheck
import Foundation

/// Result of an attestation
public struct OSAttestationServiceResult {
    /// Constructor for an attestation result
    /// - Parameters:
    ///   - keyId: The key identifier the attestation is made for
    ///   - attestation: The actual attestation
    public init(keyId: String, attestation: Data) {
        self.keyId = keyId
        self.attestation = attestation
    }

    /// The key identifier the attestation is made for
    public let keyId: String

    /// The actual attestation
    public let attestation: Data
}

/// Protocol wrapping native attestation services
///
/// In order to mock the attestation behaviour, this protocol is used as a system attestation wrapper.
public protocol OSAttestationService {
    /// Runs key attestation with the given challenge
    func attest(challenge: Data) async throws -> OSAttestationServiceResult

    /// generate an assertion for the given challenge
    func generateAssertion(challenge: Data) async throws -> Data
}

enum OSAttestationServiceError: Error {
    case attestationIsUnsupported
    case contextLoss
    case keyCreationFailed
    case keyMissingUseAttestFirst
}

public class DefaultOSAttestationService: OSAttestationService {
    let userDefaults = UserDefaults.standard

    var keyId: String? {
        didSet {
            userDefaults.set(keyId, forKey: "DefaultOSAttestationService.key")
        }
    }

    let service = DCAppAttestService.shared

    public init() {
        keyId = userDefaults.string(forKey: "DefaultOSAttestationService.key")
    }

    public func attest(challenge: Data) async throws -> OSAttestationServiceResult {
        guard service.isSupported else { throw OSAttestationServiceError.attestationIsUnsupported }

        let keyId: String
        if let tmpKeyId = self.keyId {
            keyId = tmpKeyId
        } else {
            keyId = try await generateKey()
        }

        self.keyId = keyId

        let hash = Data(SHA256.hash(data: challenge))

        do {
            return try OSAttestationServiceResult(
                keyId: keyId,
                attestation: await service.attestKey(keyId, clientDataHash: hash)
            )
            // One retry if the key is invalid
        } catch DCError.invalidKey {
            let keyId = try await generateKey()
            self.keyId = keyId

            let hash = Data(SHA256.hash(data: challenge))

            return try OSAttestationServiceResult(
                keyId: keyId,
                attestation: await service.attestKey(keyId, clientDataHash: hash)
            )
        }
    }

    public func generateAssertion(challenge: Data) async throws -> Data {
        guard service.isSupported else { throw OSAttestationServiceError.attestationIsUnsupported }

        guard let keyId = keyId else {
            throw OSAttestationServiceError.keyMissingUseAttestFirst
        }

        return try await service.generateAssertion(keyId, clientDataHash: challenge)
    }

    func generateKey() async throws -> String {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
            service.generateKey { [weak self] keyId, _ in
                guard let self = self else {
                    continuation.resume(throwing: OSAttestationServiceError.contextLoss)
                    return
                }
                guard let keyId = keyId else {
                    continuation.resume(throwing: OSAttestationServiceError.keyCreationFailed)
                    return
                }
                self.keyId = keyId
                continuation.resume(returning: keyId)
            }
        }
    }
}
