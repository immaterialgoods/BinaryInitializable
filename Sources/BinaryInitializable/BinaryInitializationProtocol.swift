//
//  BinaryInitializationProtocol.swift
//

import Foundation

/// Protocol for the BinaryInitializable macro.
public protocol BinaryInitialization {
    /// Initializes a type from the given binary data.
    /// Properties should be decoded in source order.
    init(binaryData: Data) throws
}
