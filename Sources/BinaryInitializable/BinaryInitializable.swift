import Foundation
import BinaryInitializableMacros

/// A macro that produces an initializer conforming to BinaryInitialization.
/// It will generate an extension with the conformance, as well as generate the initializer required for the conformance.
/// As of now it creates that initializer within the main body of the type rather than within the extension.
@attached(extension, conformances: BinaryInitialization)
@attached(member, names: named(init(binaryData:)))
public macro BinaryInitializable(bigEndian: Bool = false) = #externalMacro(module: "BinaryInitializableMacros", type: "BinaryInitializableMacro")
