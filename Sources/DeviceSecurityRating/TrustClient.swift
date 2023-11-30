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

/// A Nonce for the TrustClient
public typealias Nonce = Data
/// Represents mTLS Certificate
public typealias MTLSCert = Data
/// Represents the AuthCode while using device attestation
public typealias AuthCode = Data
/// Represents the DeviceToken while using device attestation
public typealias DeviceToken = Data

/// Client Protocol for talking to the GMS
public protocol TrustClient {
    /// Request a nonce from the GMS
    /// Device Registration Step 03
    func getNonce() async throws -> Nonce

    /// Register a device
    /// Device Registration Step 17
    func registerDevice(jwt: Data) async throws -> MTLSCert

    /// Attest the devices current state against GMS.
    ///
    /// - Parameters:
    ///   - jwt: The JWT to use for the attestation
    ///   - challenge: The challenge used for the attestation
    /// - Returns: An authcode if successful, throws otherwise
    func deviceAttestation(jwt: Data, challenge: Data) async throws -> AuthCode

    /// Retrieve a device token form a pending device attestation.
    ///
    /// - Parameters:
    ///   - authCode: The authCode from pervious `deviceAttestation(jwt:challenge:)` call.
    ///   - verifier: The PKCE Code Verifier
    /// - Returns: Returns a device token if successful, throws otherwise
    func deviceToken(authCode: Data, verifier: String) async throws -> DeviceToken

    /// Retrieve a list of all registered devices for the user.
    /// - Parameter identifier: The user identifier
    /// - Returns: The list of devices
    func devices(for identifier: String) async throws
        -> [OpenAPIClientAttest.Components.Schemas.DeviceRegistration]

    /// Delete a device for a user
    /// - Parameters:
    ///   - userIdentifier: The user identifier to delete the device for
    ///   - deviceIdentifier: The device identifier to delete
    func deleteDevice(userIdentifier: String, deviceIdentifier: String) async throws
}

import OpenAPIRuntime
import OpenAPIURLSession

struct AuthenticationMiddleware: ClientMiddleware {
    /// The token value.
    var xAuthorization: String

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

import OpenAPIClientAttest
import OpenAPIClientInit

/// A transcoder for dates encoded as an ISO-8601 string (in RFC 3339 format).
public struct ISO8601DateTranscoderWithMilliseconds: DateTranscoder {
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

public class OpenAPITrustClient: TrustClient {
    enum Error: Swift.Error, LocalizedError {
        case generic(String)

        var errorDescription: String? {
            switch self {
            case let .generic(message):
                return "OpenAPITrustClient: \(message)"
            }
        }
    }

    let clientInit: OpenAPIClientInit.Client
    let clientAttest: OpenAPIClientAttest.Client
    public init(urlSessionDelegate: URLSessionDelegate?, xAuthorization: String) throws {
        let urlSessionConfiguration = URLSessionConfiguration.ephemeral
        let urlSessionInit = URLSession(
            configuration: urlSessionConfiguration
        )
        let urlSessionAttest = URLSession(
            configuration: urlSessionConfiguration,
            delegate: urlSessionDelegate,
            delegateQueue: OperationQueue.main
        )
        clientInit = Client(
            serverURL: try OpenAPIClientInit.Servers.server1(),
            transport: URLSessionTransport(configuration: .init(session: urlSessionInit)),
            middlewares: [AuthenticationMiddleware(xAuthorization: xAuthorization), LoggingMiddleware()]
        )
        clientAttest = Client(
            serverURL: try OpenAPIClientAttest.Servers.server1(),
            configuration: .init(dateTranscoder: ISO8601DateTranscoderWithMilliseconds()),
            transport: URLSessionTransport(configuration: .init(session: urlSessionAttest)),
            middlewares: [AuthenticationMiddleware(xAuthorization: xAuthorization), LoggingMiddleware()]
        )
    }

    public func getNonce() async throws -> Nonce {
        switch try await clientInit.get_nonce(.init()) {
        case let .ok(response):
            switch response.body {
            case let .text(value):
                print("NONCE: \(value)")
                return try value.decodeBase64URLEncoded()
            }
        default:
            throw Error.generic("response parsing failed")
        }
    }

    public func registerDevice(jwt: Data) async throws -> MTLSCert {
        guard let token = String(data: jwt, encoding: .utf8) else {
            throw Error.generic("token serialization failed")
        }

        switch try await clientInit.post_register_device(.init(body: .json(.init(token: token)))) {
        case let .created(response):
            switch response.body {
            case let .json(body):
                return try body.cert.decodeBase64URLEncoded()
            }
        case let .badRequest(error):
            print(error)
            throw Error.generic("bad request \(error)")
        case let .internalServerError(error):
            throw Error.generic("bad request \(error)")
        case let .undocumented(statusCode: statusCode, _):
            throw Error.generic("bad request \(statusCode)")
        }
    }

    public func deviceAttestation(jwt: Data, challenge: Data) async throws -> AuthCode {
        guard let token = String(data: jwt, encoding: .utf8),
              let challenge = challenge.encodeBase64urlsafe().utf8string else {
            throw Error.generic("token serialization failed")
        }

        switch try await clientAttest
            .post_device_attestation(.init(body: .json(.init(token: token, codeChallenge: challenge)))) {
        case let .ok(response):
            switch response.body {
            case let .text(result):
                return try result.decodeBase64URLEncoded()
            }
        case let .badRequest(error):
            print(error)
            throw Error.generic("deviceAttestation bad request \(error)")
        case let .internalServerError(error):
            throw Error.generic("deviceAttestation bad request \(error)")
        case let .undocumented(statusCode: statusCode, _):
            throw Error.generic("deviceAttestation bad request \(statusCode)")
        }
    }

    public func deviceToken(authCode: Data, verifier: String) async throws -> DeviceToken {
        let authCode = authCode.base64EncodedString()

        let parameters = [
            "code": authCode,
            "code_verifier": verifier,
        ]

        let parameterArray = parameters
            .sorted { $0.0 > $1.0 }
            .map { key, value -> String in
                let escapedValue = value.urlPercentEscapedString()
                return "\(key)=\(escapedValue ?? value)"
            }

        guard let body = parameterArray.joined(separator: "&").data(using: .utf8) else {
            throw Error.generic("parameter encoding failed")
        }

        switch try await clientAttest.post_device_token(.init(body: .binary(body))) {
        case let .ok(response):
            switch response.body {
            case let .json(result):
                return result.token.data(using: .utf8) ?? Data()
            }
        case let .badRequest(error):
            print(error)
            throw Error.generic("deviceToken bad request \(error)")
        case let .internalServerError(error):
            throw Error.generic("deviceToken bad request \(error)")
        case let .undocumented(statusCode: statusCode, _):
            throw Error.generic("deviceToken bad request \(statusCode)")
        case .accepted:
            throw Error.generic("still in progress")
        }
    }

    public func devices(for identifier: String) async throws
        -> [OpenAPIClientAttest.Components.Schemas.DeviceRegistration] {
        switch try await clientAttest.get_device_registrations(.init(query: .init(userIdentifier: identifier))) {
        case let .ok(response):
            switch response.body {
            case let .json(deviceRegistrations):
                return deviceRegistrations
            }
        case let .badRequest(error):
            print(error)
            throw Error.generic("devices bad request \(error)")
        case let .internalServerError(error):
            throw Error.generic("devices internalServerError \(error)")
        case let .undocumented(statusCode: statusCode, _):
            throw Error.generic("devices undocumented \(statusCode)")
        }
    }

    public func deleteDevice(userIdentifier: String, deviceIdentifier: String) async throws {
        switch try await clientAttest.delete_device_registrations(.init(query: .init(
            userIdentifier: userIdentifier,
            deviceIdentifier: deviceIdentifier
        ))) {
        case .noContent:
            return
        case let .badRequest(error):
            print(error)
            throw Error.generic("deleteDevice bad request \(error)")
        case let .internalServerError(error):
            throw Error.generic("deleteDevice internalServerError \(error)")
        case let .undocumented(statusCode: statusCode, _):
            throw Error.generic("deleteDevice undocumented \(statusCode)")
        case .notFound:
            throw Error.generic("deleteDevice device not found")
        }
    }
}

extension String {
    /// Percent escaped URL Safe string that can be used in an URL query as specified in RFC 3986
    ///
    /// This percent-escapes all characters besides the alphanumeric character set and "-", ".", "_", and "~".
    ///
    /// http://www.ietf.org/rfc/rfc3986.txt
    ///
    /// :returns: Returns URL safe percent-escaped string.
    public func urlPercentEscapedString() -> String? {
        let allowedCharacters =
            CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~")

        return addingPercentEncoding(withAllowedCharacters: allowedCharacters)
    }
}

public class InterceptedTrustClient: TrustClient {
    public private(set) var getNonceReceivedNonce: Data?
    public private(set) var registerDeviceParameters: Data?
    public private(set) var registerDeviceResult: Data?
    public private(set) var deviceAttestationParameters: (token: Data, challenge: Data)?
    public private(set) var deviceAttestationResult: AuthCode?
    public private(set) var deviceTokenParameters: (authCode: Data, verifier: String)?
    public private(set) var deviceTokenResult: DeviceToken?
    // swiftlint:disable:next discouraged_optional_collection
    public private(set) var registeredDevicesResult: [OpenAPIClientAttest.Components.Schemas.DeviceRegistration]?

    let client: TrustClient

    public init(actual client: TrustClient) {
        self.client = client
    }

    public func getNonce() async throws -> Nonce {
        let result = try await client.getNonce()

        getNonceReceivedNonce = result
        return result
    }

    public func registerDevice(jwt: Data) async throws -> MTLSCert {
        registerDeviceParameters = jwt
        let result = try await client.registerDevice(jwt: jwt)
        registerDeviceResult = result
        return result
    }

    public func deviceAttestation(jwt: Data, challenge: Data) async throws -> AuthCode {
        deviceAttestationParameters = (token: jwt, challenge: challenge)

        let result = try await client.deviceAttestation(jwt: jwt, challenge: challenge)
        deviceAttestationResult = result

        return result
    }

    public func deviceToken(authCode: Data, verifier: String) async throws -> DeviceToken {
        deviceTokenParameters = (authCode: authCode, verifier: verifier)
        let result = try await client.deviceToken(authCode: authCode, verifier: verifier)
        deviceTokenResult = result

        return result
    }

    public func devices(for identifier: String) async throws
        -> [OpenAPIClientAttest.Components.Schemas.DeviceRegistration] {
        let devices = try await client.devices(for: identifier)
        registeredDevicesResult = devices
        return devices
    }

    public func deleteDevice(userIdentifier: String, deviceIdentifier: String) async throws {
        try await client.deleteDevice(userIdentifier: userIdentifier, deviceIdentifier: deviceIdentifier)
    }
}

public class MockTrustClient: TrustClient {
    public let mockedNonce: Data
    public private(set) var registerDeviceReceivedData: Data?
    public private(set) var deviceAttestationReceivedData: (token: Data, challenge: Data)?
    public private(set) var deviceTokenReceivedData: (authCode: Data, verifier: String)?

    public init(mockedNonceBase64: Data = ("0123456789".data(using: .utf8) ?? Data()).base64EncodedData()) {
        mockedNonce = mockedNonceBase64
    }

    public func getNonce() async throws -> Nonce {
        mockedNonce
    }

    public func registerDevice(jwt: Data) async throws -> MTLSCert {
        registerDeviceReceivedData = jwt
        return "MTLSCert".data(using: .utf8) ?? Data()
    }

    public func deviceAttestation(jwt: Data, challenge: Data) async throws -> AuthCode {
        deviceAttestationReceivedData = (token: jwt, challenge: challenge)

        return "AuthCode".data(using: .utf8) ?? Data()
    }

    public func deviceToken(authCode: Data, verifier: String) async throws -> DeviceToken {
        deviceTokenReceivedData = (authCode: authCode, verifier: verifier)

        return "DeviceToken".data(using: .utf8) ?? Data()
    }

    public func devices(for _: String) async throws -> [OpenAPIClientAttest.Components.Schemas.DeviceRegistration] {
        []
    }

    public func deleteDevice(userIdentifier _: String, deviceIdentifier _: String) async throws {}
}
