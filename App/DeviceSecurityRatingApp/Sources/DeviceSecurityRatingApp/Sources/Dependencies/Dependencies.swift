// swiftlint:disable:this file_name
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

import Dependencies
import DeviceSecurityRating

struct TrustServiceDependency: DependencyKey {
    static var liveValue: TrustService = {
        @Dependency(\.trustClient) var trustClient
        @Dependency(\.mTLSSessionDelegate) var mTLSSessionDelegate

        let service = DefaultTrustService(
            client: trustClient,
            osAttestationService: DefaultOSAttestationService()
        )
        mTLSSessionDelegate.trustService = service

        return service
    }()
}

extension DependencyValues {
    var trustService: TrustService {
        get { self[TrustServiceDependency.self] }
        set { self[TrustServiceDependency.self] = newValue }
    }
}

struct OpenAPITrustClientDependency: DependencyKey {
    static var liveValue: TrustClient = {
        @Dependency(\.mTLSSessionDelegate) var mTLSSessionDelegate

        return try! OpenAPITrustClient( // swiftlint:disable:this force_try
            urlSessionDelegate: mTLSSessionDelegate,
            xAuthorization: Secrets.apiKey
        )
    }()
}

extension DependencyValues {
    var trustClient: TrustClient {
        get { self[OpenAPITrustClientDependency.self] }
        set { self[OpenAPITrustClientDependency.self] = newValue }
    }
}

struct MTLSSessionDelegateDependency: DependencyKey {
    static var liveValue = MTLSSessionDelegate()
}

extension DependencyValues {
    var mTLSSessionDelegate: MTLSSessionDelegate {
        get { self[MTLSSessionDelegateDependency.self] }
        set { self[MTLSSessionDelegateDependency.self] = newValue }
    }
}
