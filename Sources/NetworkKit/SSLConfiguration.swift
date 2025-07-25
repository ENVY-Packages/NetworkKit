//
//  SSLConfiguration.swift
//  NetworkKit
//
//  Created by Vedant Shirke on 25/07/25.
//

import Foundation

public struct SSLConfiguration {
    let pinnedCertificates: [Data]

    public init(certNames: [String], bundle: Bundle = .main) {
        self.pinnedCertificates = certNames.compactMap {
            guard let path = bundle.path(forResource: $0, ofType: "cer"),
                  let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
                return nil
            }
            return data
        }
    }
}
