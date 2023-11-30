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

import DataKit
import Foundation

extension String {
    /// Decode the string using Base64URL decoding
    public func decodeBase64URLEncoded(mode: Base64.Mode = .failOnInvalidCharacters) throws -> Data {
        try Base64.decode(string: self, mode: mode)
    }
}
