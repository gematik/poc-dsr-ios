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

import ComposableArchitecture
import Foundation
import OpenAPIRuntime
import OpenAPIURLSession

struct FDClient {
    var getTasks: @Sendable (Data) async throws -> [Components.Schemas.ERezept_v1]
}

struct AuthenticationMiddleware: ClientMiddleware {
    /// The token value, replace accordingly
    var xAuthorization: String = Secrets.apiKey

    func intercept(
        _ request: Request,
        baseURL: URL,
        operationID _: String,
        next: (Request, URL) async throws -> Response
    ) async throws -> Response {
        var request = request
        request.headerFields.append(.init(
            name: "X-Authorization", value: xAuthorization
        ))
        return try await next(request, baseURL)
    }
}

struct LoggingMiddleware: ClientMiddleware {
    func intercept(
        _ request: Request,
        baseURL: URL,
        operationID _: String,
        next: (Request, URL) async throws -> Response
    ) async throws -> Response {
        print("LoggingMiddleware: \(request.description)")
        let result = try await next(request, baseURL)
        print("LoggingMiddleware: \(result.description)")
        return result
    }
}

/// A transcoder for dates encoded as an ISO-8601 string (in RFC 3339 format).
public struct ISO8601DateTranscoderWithMillisecods: DateTranscoder {
    /// Creates and returns an ISO 8601 formatted string representation of the specified date.
    public func encode(_ date: Date) throws -> String {
        ISO8601DateFormatter().string(from: date)
    }

    static let dateFormatter: ISO8601DateFormatter = {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [
            ISO8601DateFormatter.Options.withFullDate,
            ISO8601DateFormatter.Options.withFullTime,
            ISO8601DateFormatter.Options.withFractionalSeconds,
        ]
        return dateFormatter
    }()

    /// Creates and returns a date object from the specified ISO 8601 formatted string representation.
    public func decode(_ dateString: String) throws -> Date {
        guard let date = Self.dateFormatter.date(from: dateString) else {
            throw DecodingError.dataCorrupted(
                .init(
                    codingPath: [],
                    debugDescription: "Expected date string to be ISO8601-formatted."
                )
            )
        }
        return date
    }
}

extension FDClient: DependencyKey {
    static var liveValue: FDClient = .init { attestationToken in
        @Dependency(\.mTLSSessionDelegate) var mTLSSessionDelegate

        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        let urlSessionInit = URLSession(
            configuration: urlSessionConfiguration,
            delegate: mTLSSessionDelegate,
            delegateQueue: OperationQueue.main
        )

        let client = Client(
            serverURL: try Servers.server2(),
            configuration: .init(dateTranscoder: ISO8601DateTranscoderWithMillisecods()),
            transport: URLSessionTransport(configuration: .init(session: urlSessionInit)),
            middlewares: [
                AuthenticationMiddleware(xAuthorization: Secrets.apiKey),
                LoggingMiddleware(),
            ]
        )

        let result = try await client
            .get_api_v1_erezept(.init(headers: .init(X_Device_Token: attestationToken.utf8string ?? "")))

        enum ClientError: Error {
            case notFound
            case internalServerError
            case undocumented
        }

        switch result {
        case let .ok(response):
            switch response.body {
            case let .json(json):
                return json
            }
        case let .internalServerError(internalServerError):
            throw ClientError.internalServerError
        case let .undocumented(statusCode, undocumentedPayload):
            throw ClientError.undocumented
        }
    }
}

extension DependencyValues {
    var fdClient: FDClient {
        get { self[FDClient.self] }
        set { self[FDClient.self] = newValue }
    }
}
