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
import UIKit

struct AttestationToken: Claims {
    internal init(pubkey: Data, iat: Date, nonce: Data, assertion: Data, deviceAttributes: Attributes) {
        iss = "TrustSDK_1.0"
        sub = pubkey.base64EncodedString()
        self.iat = Int(iat.timeIntervalSince1970)

        type = "iOS"
        self.nonce = nonce.base64EncodedString()
        self.assertion = assertion.base64EncodedString()
        self.deviceAttributes = deviceAttributes
    }

    let iss: String

    let sub: String

    let iat: Int

    // Fixed value
    let type: String

    // Base64 encoded Data
    let nonce: String

    let assertion: String

    let deviceAttributes: Attributes

    struct Attributes: Codable {
        init(
            systemName: String = UIDevice.current.systemName,
            systemVersion: String = UIDevice.current.systemVersion,
            systemModel: String = UIDevice.current.modelName,
            identifierForVendor: String = UIDevice.current.identifierForVendor?.uuidString ?? ""
        ) {
            self.systemName = systemName
            self.systemVersion = systemVersion
            self.systemModel = systemModel
            self.identifierForVendor = identifierForVendor
        }

        let systemName: String
        let systemVersion: String
        let systemModel: String
        let identifierForVendor: String
    }
}

extension UIDevice {
    var modelName: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        return identifier
    }
}
