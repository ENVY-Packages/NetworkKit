//
//  Endpoint.swift
//  NetworkKit
//
//  Created by Vedant Shirke on 25/07/25.
//

import Foundation

public protocol Endpoint {
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
}
