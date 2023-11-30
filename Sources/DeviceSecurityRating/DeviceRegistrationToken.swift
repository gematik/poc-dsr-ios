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

import Foundation

struct DeviceRegistrationToken: Claims {
    internal init(pubkey: Data, iat: Date, nonce: Data, csr: Data, keyId: String, attestation: Data) {
        iss = "TrustSDK_1.0"
        sub = pubkey.base64EncodedString()
        self.iat = Int(iat.timeIntervalSince1970)

        type = "iOS"
        self.nonce = nonce.base64EncodedString()
        self.csr = csr.base64EncodedString()
        self.keyId = keyId
        self.attestation = attestation.base64EncodedString()
    }

    let iss: String

    let sub: String

    let iat: Int

    // Fixed value
    let type: String

    // Base64 encoded Data
    let nonce: String

    // base64 encoded PKCS#10
    let csr: String

    // attestation key id
    let keyId: String

    // Base64 CBOR
    let attestation: String
}
