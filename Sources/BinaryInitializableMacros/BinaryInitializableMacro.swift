import Foundation
import SwiftCompilerPlugin
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros

/// Implementation of the `BinaryInitializable` macro, which
/// produces an initializer to conform the type to BinaryInitialization.
public struct BinaryInitializableMacro: MemberMacro, ExtensionMacro {
    
    /// Builds protocol conformance
    public static func expansion(of node: AttributeSyntax,
                                 attachedTo declaration: some DeclGroupSyntax,
                                 providingExtensionsOf type: some TypeSyntaxProtocol,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [ExtensionDeclSyntax] {
        
        // This one is simple. Just build the extension to conform to BinaryInitialization
        let binaryInitializationExtension = try ExtensionDeclSyntax("extension \(type.trimmed): BinaryInitialization {}")
        return [binaryInitializationExtension]
        
    }
    
    /// Builds initializer
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [DeclSyntax] {
        
        // Check the arguments to see if we should use big endian
        var bigEndian: Bool = false
        if case .argumentList(let arguments) = node.arguments {
            for argument in arguments.compactMap({ $0.as(LabeledExprSyntax.self) }) {
                if let expression = argument.expression.as(BooleanLiteralExprSyntax.self),
                   argument.label?.text == "bigEndian",
                   expression.literal.text == "true" {
                    bigEndian = true
                }
            }
        }

        // Grab the list of properties of the struct or class.
        let properties: MemberBlockItemListSyntax
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            properties = structDecl.memberBlock.members
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            properties = classDecl.memberBlock.members
        } else {
            // Hey, this isn't meant to be used on anything else!
            throw BinaryInitializableMacroError.onlyApplicableToStructOrClass
        }
        
        // Filter out static properties, then map to just property names (that's all we need)
        let propertyNames = properties
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter { $0.modifiers.contains(where: { $0.name.text == "static" }) == false }
            .compactMap { $0.bindings.first?.pattern }

        // Build the initializer. First the header, then the body.
        let header = SyntaxNodeString(stringLiteral: "public init(binaryData: Data) throws")
        let initializer = try InitializerDeclSyntax(header) {
            // Don't output the parser code if there are no properties
            // (compiler will give an "unused variable" warning)
            if propertyNames.isEmpty == false {
                if bigEndian {
                    "    let parser = BinaryInitializationParser(binaryData, isBigEndian: true)"
                } else {
                    "    let parser = BinaryInitializationParser(binaryData, isBigEndian: false)"
                }
            }
            for name in propertyNames {
                ExprSyntax("    self.\(name) = try parser.nextValue()")
            }
        }
        
        return [DeclSyntax(initializer)]
    }
    
}

/// This error is shown to the user by the compiler if they attempt to attach this macro to something that is not a struct or class.
public enum BinaryInitializableMacroError: CustomStringConvertible, Error {
    case onlyApplicableToStructOrClass
    
    public var description: String {
        switch self {
        case .onlyApplicableToStructOrClass: return "@BinaryInitializable can only be applied to a struct or class"
        }
    }
}

/// Necessary boilerplate
@main
struct BinaryInitializablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BinaryInitializableMacro.self,
    ]
}
