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

import Foundation
import OpenSSL

/// Types conforming should be able to verify a signature
public protocol JWTSignatureVerifier {
    /// Verify whether the `signature` is correct for the given `message`
    ///
    /// - Parameters:
    ///   - signature: raw signature bytes
    ///   - message: raw message bytes
    /// - Returns: true when the signature authenticates the message
    /// - Throws: `Swift.Error`
    func verify(signature: Data, message: Data) throws -> Bool
}

extension BrainpoolP256r1.Verify.PublicKey: JWTSignatureVerifier {
    // [REQ:gemSpec_Krypt:A_17207]
    // [REQ:gemSpec_Krypt:GS-A_4357-01,GS-A_4357-02]
    public func verify(signature raw: Data, message: Data) throws -> Bool {
        let signature = try BrainpoolP256r1.Verify.Signature(rawRepresentation: raw)
        return try verify(signature: signature, message: message)
    }
}

enum X509SignatureVerifierError: Error {
    case unsupported(String)
}

extension X509: JWTSignatureVerifier {
    public func verify(signature: Data, message: Data) throws -> Bool {
        // [REQ:gemSpec_Krypt:A_17207]
        // [REQ:gemSpec_Krypt:GS-A_4357-01,GS-A_4357-02] Assure that brainpoolP256r1 is used
        guard let key = brainpoolP256r1VerifyPublicKey() else {
            throw X509SignatureVerifierError.unsupported("expected brainpool P256r1 key")
        }
        return try key.verify(signature: signature, message: message)
    }
}
