//
//  NetworkManager.swift
//  NetworkKit
//
//  Created by Vedant Shirke on 25/07/25.
//

import Foundation

public class NetworkManager: NSObject {
    private var session: URLSession!
    private let retryPolicy: RetryPolicy
    private var sslConfig: SSLConfiguration?

    public init(sslConfiguration: SSLConfiguration? = nil,
                retryPolicy: RetryPolicy = DefaultRetryPolicy()) {
        self.retryPolicy = retryPolicy
        self.sslConfig = sslConfiguration
        super.init()

        if sslConfiguration != nil {
            let config = URLSessionConfiguration.default
            session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        } else {
            session = URLSession.shared
        }
    }

    public func request<T: Decodable>(_ endpoint: Endpoint, responseType: T.Type) async throws -> T {
        var attempt = 0
        while true {
            do {
                let request = try buildRequest(from: endpoint)
                let (data, response) = try await session.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                guard 200..<300 ~= httpResponse.statusCode else {
                    throw NetworkError.statusCode(httpResponse.statusCode)
                }

                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                attempt += 1
                if !retryPolicy.shouldRetry(for: error, attempt: attempt) {
                    throw NetworkError.requestFailed(error)
                }
            }
        }
    }

    private func buildRequest(from endpoint: Endpoint) throws -> URLRequest {
        guard var components = URLComponents(string: endpoint.path) else {
            throw NetworkError.invalidURL
        }
        components.queryItems = endpoint.queryItems
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.httpBody = endpoint.body
        endpoint.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        return request
    }
}

extension NetworkManager: URLSessionDelegate {
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {

        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let sslConfig = sslConfig else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        let policy = SecPolicyCreateSSL(true, challenge.protectionSpace.host as CFString)
        SecTrustSetPolicies(serverTrust, policy)

        guard let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let serverCertData = SecCertificateCopyData(serverCert) as Data

        if sslConfig.pinnedCertificates.contains(serverCertData) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}

