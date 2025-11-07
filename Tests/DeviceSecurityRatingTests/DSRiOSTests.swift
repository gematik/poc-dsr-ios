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
import DeviceCheck
@testable import DeviceSecurityRating
import XCTest

final class DSRiOSTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.

        let service = DCAppAttestService.shared

        XCTAssertTrue(DSRiOS().getDeviceInfo() == "iOS: 16.4, iOS, Model: iPhone | x86_64" ||
            DSRiOS().getDeviceInfo() == "iOS: 16.4, iOS, Model: iPhone | arm64")
    }
}
