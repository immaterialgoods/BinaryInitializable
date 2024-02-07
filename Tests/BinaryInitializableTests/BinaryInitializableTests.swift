import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest


// MARK: - Macro setup

// Macro implementations build for the host, so the corresponding module is not available when cross-compiling. Cross-compiled tests may still make use of the macro itself in end-to-end tests.
#if canImport(BinaryInitializableMacros)
import BinaryInitializableMacros

let testMacros: [String: Macro.Type] = [
    "BinaryInitializable": BinaryInitializableMacro.self,
]

#endif


// MARK: - Test Data

let testBytesLittleEndian: [UInt8] = [
    0x34, 0x0, 0x0, 0x0,    // 52 (UInt32)
    0xCA, 0x9, 0x0, 0x0,    // 2506 (UInt32)
    0x33, 0x33, 0xC5, 0x42, // 98.6 (Float32)
    0xCD, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0x3C, 0x40, // 28.8 (Double)
    0xFB, 0xFF, 0xFF, 0xFF, // -5 (Int32)
    0xED, 0x5F, 0x84, 0x0,  // 8675309 (UInt32)
]

let testBytesBigEndian: [UInt8] = [
    0x0, 0x0, 0x0, 0x34,    // 52 (UInt32)
    0x0, 0x0, 0x9, 0xCA,    // 2506 (UInt32)
    0x42, 0xC5, 0x33, 0x33, // 98.6 (Float32)
    0x40, 0x3C, 0xCC, 0xCC, 0xCC, 0xCC, 0xCC, 0xCD, // 28.8 (Double)
    0xFF, 0xFF, 0xFF, 0xFB, // -5 (Int32)
    0x0, 0x84, 0x5F, 0xED,  // 8675309 (UInt32)
]

let testDataLittleEndian = Data(testBytesLittleEndian)

let testDataBigEndian = Data(testBytesBigEndian)


// MARK: - Tests

final class BinaryInitializableTests: XCTestCase {
    
    // MARK: Macro Tests

    func testMacroStruct() throws {
        #if canImport(BinaryInitializableMacros)
        
        assertMacroExpansion(
            """
            @BinaryInitializable
            struct Digits {
                static let excluded: UInt32
                let five: UInt32
                let sixPointThree: Float32
            }
            """,
            expandedSource: """
            struct Digits {
                static let excluded: UInt32
                let five: UInt32
                let sixPointThree: Float32
            
                public init(binaryData: Data) throws {
                    let parser = BinaryInitializationParser(binaryData, isBigEndian: false)
                    self.five = try parser.nextValue()
                    self.sixPointThree = try parser.nextValue()
                }
            }
            
            extension Digits: BinaryInitialization {
            }
            """,
            macros: testMacros
        )
        
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacroClass() throws {
        #if canImport(BinaryInitializableMacros)
        
        assertMacroExpansion(
            """
            @BinaryInitializable
            class Digits {
                static let excluded: UInt32
                let five: UInt32
                let sixPointThree: Float32
            }
            """,
            expandedSource: """
            class Digits {
                static let excluded: UInt32
                let five: UInt32
                let sixPointThree: Float32
            
                public init(binaryData: Data) throws {
                    let parser = BinaryInitializationParser(binaryData, isBigEndian: false)
                    self.five = try parser.nextValue()
                    self.sixPointThree = try parser.nextValue()
                }
            }
            
            extension Digits: BinaryInitialization {
            }
            """,
            macros: testMacros
        )
        
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacroBigEndian() throws {
        #if canImport(BinaryInitializableMacros)
        
        assertMacroExpansion(
            """
            @BinaryInitializable(bigEndian: true)
            struct Digits {
                static let excluded: UInt32
                let five: UInt32
                let sixPointThree: Float32
            }
            """,
            expandedSource: """
            struct Digits {
                static let excluded: UInt32
                let five: UInt32
                let sixPointThree: Float32
            
                public init(binaryData: Data) throws {
                    let parser = BinaryInitializationParser(binaryData, isBigEndian: true)
                    self.five = try parser.nextValue()
                    self.sixPointThree = try parser.nextValue()
                }
            }
            
            extension Digits: BinaryInitialization {
            }
            """,
            macros: testMacros
        )
        
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacroEmptyStruct() throws {
        #if canImport(BinaryInitializableMacros)
        
        assertMacroExpansion(
            """
            @BinaryInitializable(bigEndian: true)
            struct Digits {
            }
            """,
            expandedSource: """
            struct Digits {
            
                public init(binaryData: Data) throws {
                }
            }
            
            extension Digits: BinaryInitialization {
            }
            """,
            macros: testMacros
        )
        
        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    // MARK: Parser Tests
    
    func testParserLittleEndian() throws {
        #if canImport(BinaryInitializableMacros)
        
        do {
            let parser = BinaryInitializationParser(testDataLittleEndian, isBigEndian: false)
            
            let fiftyTwo: UInt32 = try parser.nextValue()
            let twentyFiveOhSix: UInt32 = try parser.nextValue()
            let ninetyEightPointSix: Float = try parser.nextValue()
            let twentyEightEight: Double = try parser.nextValue()
            let negativeFive: Int32 = try parser.nextValue()
            let jenny: UInt32 = try parser.nextValue()

            XCTAssertEqual(fiftyTwo, 52)
            XCTAssertEqual(twentyFiveOhSix, 2506)
            XCTAssertEqual(ninetyEightPointSix, 98.6)
            XCTAssertEqual(twentyEightEight, 28.8)
            XCTAssertEqual(negativeFive, -5)
            XCTAssertEqual(jenny, 8675309)
        } catch {
            XCTFail("Got error loading data during parser test: \(error)")
        }

        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }
    
    func testMacroValuesBigEndian() throws {
        #if canImport(BinaryInitializableMacros)
        
        do {
            let parser = BinaryInitializationParser(testDataBigEndian, isBigEndian: true)
            
            let fiftyTwo: UInt32 = try parser.nextValue()
            let twentyFiveOhSix: UInt32 = try parser.nextValue()
            let ninetyEightPointSix: Float = try parser.nextValue()
            let twentyEightEight: Double = try parser.nextValue()
            let negativeFive: Int32 = try parser.nextValue()
            let jenny: UInt32 = try parser.nextValue()

            XCTAssertEqual(fiftyTwo, 52)
            XCTAssertEqual(twentyFiveOhSix, 2506)
            XCTAssertEqual(ninetyEightPointSix, 98.6)
            XCTAssertEqual(twentyEightEight, 28.8)
            XCTAssertEqual(negativeFive, -5)
            XCTAssertEqual(jenny, 8675309)
        } catch {
            XCTFail("Got error loading data during parser test: \(error)")
        }

        #else
        throw XCTSkip("macros are only supported when running tests for the host platform")
        #endif
    }

}
