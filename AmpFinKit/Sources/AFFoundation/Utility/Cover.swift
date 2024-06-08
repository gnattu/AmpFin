//
//  File.swift
//
//
//  Created by Rasmus Krämer on 15.05.24.
//

import Foundation

public struct Cover: Codable, Hashable {
    public let type: CoverType
    public let size: CoverSize
    public let url: URL
    
    public init(type: CoverType, size: CoverSize, url: URL) {
        self.type = type
        self.size = size
        self.url = url
    }
}

extension Cover: Equatable {
    public static func == (lhs: Cover, rhs: Cover) -> Bool {
        lhs.url == rhs.url
    }
}

public extension Cover {
    enum CoverType: Codable, Hashable {
        case local
        case remote
        case mock
    }
    
    enum CoverSize: Codable, Hashable {
        case small
        case normal
        case custom(size: Int)
    }
}

public extension Cover.CoverSize {
    var dimensions: Int {
        switch self {
            case .small:
                200
            case .normal:
                800
            case .custom(let size):
                size
        }
    }
}
