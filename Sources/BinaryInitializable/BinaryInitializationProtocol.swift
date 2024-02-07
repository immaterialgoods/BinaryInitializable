//
//  BinaryInitializationProtocol.swift
//

import Foundation

/// Protocol for the BinaryInitializable macro
public protocol BinaryInitialization {
    init(binaryData: Data) throws
}
