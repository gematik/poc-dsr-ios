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

import DataKit
import Foundation
import OpenSSL

class Brainpool256r1Signer: JWTSigner {
    let x5c: X509
    let derBytes: Data
    let key: BrainpoolP256r1.Verify.PrivateKey

    init(x5c: Data, key: Data) throws {
        derBytes = x5c
        self.x5c = try X509(der: x5c)
        self.key = try BrainpoolP256r1.Verify.PrivateKey(raw: key)
    }

    var certificates: [Data] {
        [derBytes]
    }

    func sign(message: Data) throws -> Data {
        try key.sign(message: message).rawRepresentation
    }
}
