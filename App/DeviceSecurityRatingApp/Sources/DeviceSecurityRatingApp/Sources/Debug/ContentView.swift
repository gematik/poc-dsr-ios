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
//  limitations under the License.//

import ASN1Kit
import CryptoKit
import DeviceCheck
import DeviceSecurityRating
import SwiftUI

struct ContentView: View {
    @State var isSupported = true

    @State var errorText = "-"

    @State var task: Task<Void, any Swift.Error>?

    @State var nonce = "0123456789"
    @State var rfc01JwtRegistration: String? = "-"
    @State var rfc01mTLSCertificate: String? = "-"
    @State var rfc02JwtAttest: String? = "-"
    @State var rfc02Challenge: String? = "-"
    @State var rfc02AuthCode: String? = "-"
    @State var rfc02Verifier: String? = "-"
    @State var rfc02DeviceToken: String? = "-"

    var body: some View {
        NavigationView {
            Form {
                Section("Registration") {
                    VStack {
                        Text("Faked nonce (Base64URL encoded)")
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        TextField("Custom Nonce", text: $nonce)
                    }

                    VStack {
                        Text("Output/Error:")
                            .font(.footnote)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(errorText)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Button {
                        task = Task {
                            let trustClient = InterceptedTrustClient(
                                // actual: MockTrustClient(mockedNonceBase64: try nonce.decodeBase64URLEncoded())
                                actual: try OpenAPITrustClient(urlSessionDelegate: nil, xAuthorization: Secrets.apiKey)
                            )
                            let service = DefaultTrustService(
                                client: trustClient,
                                osAttestationService: DefaultOSAttestationService()
                            )

                            try await service.resetAttestation()
                        }
                    } label: {
                        Text("reset")
                    }

                    Button {
                        task = Task {
                            errorText = "starting"
                            do {
                                let sessionDelegate = MTLSSessionDelegate()
                                let openAPITrustClient = try OpenAPITrustClient(
                                    urlSessionDelegate: sessionDelegate,
                                    xAuthorization: Secrets.apiKey
                                )
                                let trustClient = InterceptedTrustClient(
                                    // actual: MockTrustClient(mockedNonceBase64: try nonce.decodeBase64URLEncoded())
                                    actual: openAPITrustClient
                                )
                                let openAPITrustClient2 = try OpenAPITrustClient(
                                    urlSessionDelegate: sessionDelegate,
                                    xAuthorization: Secrets.apiKey
                                )
                                let trustClient2 = InterceptedTrustClient(
                                    // actual: MockTrustClient(mockedNonceBase64: try nonce.decodeBase64URLEncoded())
                                    actual: openAPITrustClient2
                                )
                                let service = DefaultTrustService(
                                    client: trustClient,
                                    osAttestationService: DefaultOSAttestationService()
                                )

                                sessionDelegate.trustService = service

                                errorText = "RFC 01..."
                                rfc01mTLSCertificate = try await service.registration().base64EncodedString()

                                nonce = trustClient.getNonceReceivedNonce?.base64EncodedString() ?? ""
                                rfc01JwtRegistration = String(
                                    data: trustClient.registerDeviceParameters ?? Data(),
                                    encoding: .utf8
                                )
                                errorText = "RFC 01...done"
                                errorText = "RFC 01...done\nRFC 02..."

                                rfc02DeviceToken = try await service.requestAttestation().utf8string ?? ""

                                rfc02JwtAttest = trustClient2.deviceAttestationParameters?.token.utf8string ?? ""
                                rfc02Challenge = trustClient2.deviceAttestationParameters?.challenge
                                    .base64EncodedString()

                                rfc02AuthCode = trustClient2.deviceTokenParameters?.authCode.encodeBase64urlsafe()
                                    .utf8string
                                rfc02Verifier = trustClient2.deviceTokenParameters?.verifier

                                errorText = "RFC 01...done\nRFC 02...done"

                            } catch {
                                switch error {
                                case DCError.serverUnavailable:
                                    errorText = "servers are currently unavailable"
                                default:
                                    errorText = error.localizedDescription
                                }
                            }
                        }
                    } label: {
                        Text("start")
                    }
                }

                Section("RFC 01") {
                    VStack(alignment: .leading) {
                        Text("Registration JWT:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc01JwtRegistration ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading) {
                        Text("mTLS Certificate:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc01mTLSCertificate ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("RFC 02") {
                    VStack(alignment: .leading) {
                        Text("Access JWT:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc02JwtAttest ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading) {
                        Text("Challenge:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc02Challenge ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading) {
                        Text("AuthCode:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc02AuthCode ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading) {
                        Text("Verifier:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc02Verifier ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)

                    VStack(alignment: .leading) {
                        Text("Device Token:")
                            .font(.footnote)
                        TextEditor(text: .constant(rfc02DeviceToken ?? ""))
                            .frame(maxHeight: 200)
                    }
                    .frame(maxWidth: .infinity)
                }

                Section("Sharing RFC 01") {
                    if #available(iOS 16.0, *) {
                        ShareLink("Nonce", item: nonce)
                        ShareLink("JWT", item: rfc01JwtRegistration ?? "")
                        ShareLink("mTLS", item: rfc01mTLSCertificate ?? "")
                    }
                }
                Section("Sharing RFC 02") {
                    if #available(iOS 16.0, *) {
                        ShareLink("JWT_access", item: rfc02JwtAttest ?? "")
                        ShareLink("Challenge", item: rfc02Challenge ?? "")
                        ShareLink("AuthCode", item: rfc02AuthCode ?? "")
                        ShareLink("Verifier", item: rfc02Verifier ?? "")
                        ShareLink("DeviceToken", item: rfc02DeviceToken ?? "")
                    }
                }

                Section("Sharing Everything") {
                    if #available(iOS 16.0, *) {
                        ShareLink("Single File", item: everything)
                    }
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("DSR PoC")
        }
    }

    var everything: String {
        """
                Nonce:

                \(nonce)

                JWT:

                \(rfc01JwtRegistration ?? "")

                mTLS:

                \(rfc01mTLSCertificate ?? "")

                JWT_access:

                \(rfc02JwtAttest ?? "")

                Challenge:

                \(rfc02Challenge ?? "")

                AuthCode:

                \(rfc02AuthCode ?? "")

                Verifier:

                \(rfc02Verifier ?? "")

                DeviceToken:

                \(rfc02DeviceToken ?? "")
        """
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
