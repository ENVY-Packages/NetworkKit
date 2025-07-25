//
//  NetworkError.swift
//  NetworkKit
//
//  Created by Vedant Shirke on 25/07/25.
//

public enum NetworkError: Error {
    case invalidURL
    case requestFailed(Error)
    case invalidResponse
    case statusCode(Int)
    case decodingFailed(Error)
}
