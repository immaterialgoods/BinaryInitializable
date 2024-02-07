//
//  BinaryInitializationParser.swift
//

import Foundation

public class BinaryInitializationParser {
    
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
    
    let data: Data
        
    var nextIndex: Data.Index
    
    let isBigEndian: Bool

    public init(_ data: Data, isBigEndian: Bool = false) {
        self.data = data
        self.nextIndex = data.startIndex
        self.isBigEndian = isBigEndian
    }
    
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
