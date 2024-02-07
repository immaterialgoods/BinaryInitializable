import Foundation
import BinaryInitializableMacros

/// A macro that produces an initializer conforming to BinaryInitialization.
@attached(extension, conformances: BinaryInitialization)
@attached(member, names: named(init(binaryData:)))
public macro BinaryInitializable(bigEndian: Bool = false) = #externalMacro(module: "BinaryInitializableMacros", type: "BinaryInitializableMacro")
