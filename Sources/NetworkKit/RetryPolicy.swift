//
//  RetryPolicy.swift
//  NetworkKit
//
//  Created by Vedant Shirke on 25/07/25.
//

public protocol RetryPolicy {
    func shouldRetry(for error: Error, attempt: Int) -> Bool
}

public struct DefaultRetryPolicy: RetryPolicy {
    public init() {}
    public func shouldRetry(for error: Error, attempt: Int) -> Bool {
        return attempt < 3
    }
}
