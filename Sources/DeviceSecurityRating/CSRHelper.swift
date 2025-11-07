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

struct CSRHelper {
    init() {}

    enum OID: String {
        // Object classes
        case objectClass = "2.5.4.0"
        // Attribute type "Aliased entry name"
        case aliasedEntryName = "2.5.4.1"
        // knowledgeInformation attribute type
        case knowledgeInformation = "2.5.4.2"
        // Common name
        case commonName = "2.5.4.3"
        // Attribute "surname"
        case surname = "2.5.4.4"
        // Serial number attribute type
        case serialNumber = "2.5.4.5"
        // Country name
        case countryName = "2.5.4.6"
        // Locality Name
        case localityName = "2.5.4.7"
        // State or Province name
        case stateOrProvinceName = "2.5.4.8"
        // Street address
        case streetAddress = "2.5.4.9"
        // Organization name
        case organizationName = "2.5.4.10"
        // Organization unit name
        case organizationUnitName = "2.5.4.11"

        // PKCS #9 Email Address attribute for use in signatures
        case emailAddress = "1.2.840.113549.1.9.1"

        // Challenge Password attribute for use in signatures
        case challengePassword = "1.2.840.113549.1.9.7"

        var asn1Tag: ASN1Tag {
            switch self {
            case .emailAddress:
                return .ia5String
            default: return .utf8String
            }
        }
    }

    static func contentPair(oid: OID, payload: String) throws -> ASN1Object {
        create(tag: .universal(.set), data: ASN1Data.constructed(
            [
                create(tag: .universal(.sequence), data: ASN1Data.constructed([
                    try ObjectIdentifier.from(string: oid.rawValue).asn1encode(),
                    try payload.asn1encode(tag: .universal(oid.asn1Tag)),
                ])),
            ]
        ))
    }

    static func createCSR(keypair: PrivateKeyContainer, content: [OID: String]) throws -> Data {
        let contentASN1Encoded = content.compactMap { key, value in
            try? contentPair(oid: key, payload: value)
        }
        let asn1 = ASN1Data.constructed([
            try Int(0).asn1encode(tag: .universal(.integer)),
            create(tag: .universal(.sequence), data: ASN1Data.constructed(
                contentASN1Encoded
            )),
            try keypair.asn1PublicKey(),
        ])

        let asn1AsData = try create(tag: .universal(.sequence), data: asn1).serialize()

        let signature = try keypair.sign(data: Data(SHA256.hash(data: asn1AsData))).asn1encoded()

        let data = try create(tag: .universal(.sequence), data:
            ASN1Data.constructed([
                create(tag: .universal(.sequence), data: asn1),
                create(tag: .universal(.sequence), data: ASN1Data.constructed([
                    try ObjectIdentifier.from(string: "1 2 840 10045 4 3 2").asn1encode(),
                ])),
                create(tag: .universal(.bitString), data: ASN1Data.primitive(signature)),
            ])).serialize()

        return data
    }
}
