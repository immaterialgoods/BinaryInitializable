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
        let binaryInitializationExtension = try ExtensionDeclSyntax("extension \(type.trimmed): BinaryInitialization {}")
        return [binaryInitializationExtension]
    }
    
    /// Builds initializer
    public static func expansion(of node: AttributeSyntax,
                                 providingMembersOf declaration: some DeclGroupSyntax,
                                 conformingTo protocols: [TypeSyntax],
                                 in context: some MacroExpansionContext)
    throws -> [DeclSyntax] {
        let members: MemberBlockItemListSyntax
        if let structDecl = declaration.as(StructDeclSyntax.self) {
            members = structDecl.memberBlock.members
        } else if let classDecl = declaration.as(ClassDeclSyntax.self) {
            members = classDecl.memberBlock.members
        } else {
            throw BinaryInitializableMacroError.onlyApplicableToStructOrClass
        }
        
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
        
        let variableNames = members
            .compactMap { $0.decl.as(VariableDeclSyntax.self) }
            .filter {
                $0.modifiers.contains(where: { $0.name.text == "static" }) == false
            }
            .compactMap { $0.bindings.first?.pattern }

        let header = SyntaxNodeString(stringLiteral: "public init(binaryData: Data) throws")
        let initializer = try InitializerDeclSyntax(header) {
            if variableNames.isEmpty == false {
                if bigEndian {
                    "    let parser = BinaryInitializationParser(binaryData, isBigEndian: true)"
                } else {
                    "    let parser = BinaryInitializationParser(binaryData, isBigEndian: false)"
                }
            }
            for name in variableNames {
                ExprSyntax("    self.\(name) = try parser.nextValue()")
            }
        }
        
        return [DeclSyntax(initializer)]
    }
    
}

public enum BinaryInitializableMacroError: CustomStringConvertible, Error {
    case onlyApplicableToStructOrClass
    
    public var description: String {
        switch self {
        case .onlyApplicableToStructOrClass: return "@BinaryInitializable can only be applied to a struct or class"
        }
    }
}


@main
struct BinaryInitializablePlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        BinaryInitializableMacro.self,
    ]
}
