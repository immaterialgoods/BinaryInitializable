//
//  BinaryInitializationParser.swift
//

import Foundation

/// A wrapper around some Data, which can sequentially read out numerical values when requested.
public class BinaryInitializationParser {
    
    /// In case there's an error.
    enum ParserError: CustomStringConvertible, Error {
        
        case dataExhaused
        case copyFailure

        var description: String {
            switch self {
            case .dataExhaused: return "Not enough data remaining to initialize value."
            case .copyFailure: return "Not enough data was copied into the value."
            }
        }

    }
    
    /// The data the parser is reading from.
    let data: Data
    
    /// The data's endianness.
    let isBigEndian: Bool
    
    /// The current index from which the parser will begin its next read.
    /// The parser always begins at the data's `.startIndex`.
    /// If you need to start at a particular location, use Data's subscripting to pass in a subset of your overall data.
    private(set) var nextIndex: Data.Index

    /// Initialize with the data to be read from, along with the endianness of the data.
    public init(_ data: Data, isBigEndian: Bool = false) {
        self.data = data
        self.nextIndex = data.startIndex
        self.isBigEndian = isBigEndian
    }
    
    /// Reads the next value out of the data. The amount of data to be read corresponds to the size of the type T.
    /// The parser keeps track of its position in the data so the next call can read the next chunk of data.
    public func nextValue<T: Numeric>() throws -> T {
        let size = MemoryLayout<T>.size
        let firstIndex = nextIndex
        let lastIndex = firstIndex.advanced(by: size)
        nextIndex = lastIndex

        guard lastIndex <= data.endIndex else { throw ParserError.dataExhaused }
        
        var value: T = 0
        var swapEndian = false
        
        #if _endian(big)
            swapEndian = isBigEndian == false
        #else
            swapEndian = isBigEndian
        #endif
        
        // If we simply use `data.withUnsafeBytes { $0.load(as: T.self }` we can have alignment problems. Must copy.
        let bytesCopied = withUnsafeMutableBytes(of: &value, {
            if swapEndian {
                data[firstIndex..<lastIndex].reversed().copyBytes(to: $0)
            } else {
                data[firstIndex..<lastIndex].copyBytes(to: $0)
            }
        })

        guard bytesCopied == size else { throw ParserError.copyFailure }
        
        return value
    }

}
