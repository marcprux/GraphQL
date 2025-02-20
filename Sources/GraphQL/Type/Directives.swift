import OrderedCollections

public enum DirectiveLocation: String, Encodable {
    // Operations
    case query = "QUERY"
    case mutation = "MUTATION"
    case subscription = "SUBSCRIPTION"
    case field = "FIELD"
    case fragmentDefinition = "FRAGMENT_DEFINITION"
    case fragmentSpread = "FRAGMENT_SPREAD"
    case fragmentVariableDefinition = "FRAGMENT_VARIABLE_DEFINITION"
    case inlineFragment = "INLINE_FRAGMENT"
    case variableDefinition = "VARIABLE_DEFINITION"
    // Schema Definitions
    case schema = "SCHEMA"
    case scalar = "SCALAR"
    case object = "OBJECT"
    case fieldDefinition = "FIELD_DEFINITION"
    case argumentDefinition = "ARGUMENT_DEFINITION"
    case interface = "INTERFACE"
    case union = "UNION"
    case `enum` = "ENUM"
    case enumValue = "ENUM_VALUE"
    case inputObject = "INPUT_OBJECT"
    case inputFieldDefinition = "INPUT_FIELD_DEFINITION"
}

/**
 * Directives are used by the GraphQL runtime as a way of modifying execution
 * behavior. Type system creators will usually not create these directly.
 */
public final class GraphQLDirective {
    public let name: String
    public let description: String?
    public let locations: [DirectiveLocation]
    public let args: [GraphQLArgumentDefinition]
    public let isRepeatable: Bool
    public let astNode: DirectiveDefinition?

    public init(
        name: String,
        description: String? = nil,
        locations: [DirectiveLocation],
        args: GraphQLArgumentConfigMap = [:],
        isRepeatable: Bool = false,
        astNode: DirectiveDefinition? = nil
    ) throws {
        try assertValid(name: name)
        self.name = name
        self.description = description
        self.locations = locations
        self.args = try defineArgumentMap(args: args)
        self.isRepeatable = isRepeatable
        self.astNode = astNode
    }

    func argConfigMap() -> GraphQLArgumentConfigMap {
        var argConfigs: GraphQLArgumentConfigMap = [:]
        for argDef in args {
            argConfigs[argDef.name] = argDef.toArg()
        }
        return argConfigs
    }
}

/**
 * Used to conditionally include fields or fragments.
 */
public let GraphQLIncludeDirective = try! GraphQLDirective(
    name: "include",
    description:
    "Directs the executor to include this field or fragment only when " +
        "the \\`if\\` argument is true.",
    locations: [
        .field,
        .fragmentSpread,
        .inlineFragment,
    ],
    args: [
        "if": GraphQLArgument(
            type: GraphQLNonNull(GraphQLBoolean),
            description: "Included when true."
        ),
    ]
)

/**
 * Used to conditionally skip (exclude) fields or fragments.
 */
public let GraphQLSkipDirective = try! GraphQLDirective(
    name: "skip",
    description:
    "Directs the executor to skip this field or fragment when the \\`if\\` " +
        "argument is true.",
    locations: [
        .field,
        .fragmentSpread,
        .inlineFragment,
    ],
    args: [
        "if": GraphQLArgument(
            type: GraphQLNonNull(GraphQLBoolean),
            description: "Skipped when true."
        ),
    ]
)

/**
 * Constant string used for default reason for a deprecation.
 */
let defaultDeprecationReason = "No longer supported"

/**
 * Used to declare element of a GraphQL schema as deprecated.
 */
public let GraphQLDeprecatedDirective = try! GraphQLDirective(
    name: "deprecated",
    description:
    "Marks an element of a GraphQL schema as no longer supported.",
    locations: [
        .fieldDefinition,
        .argumentDefinition,
        .inputFieldDefinition,
        .enumValue,
    ],
    args: [
        "reason": GraphQLArgument(
            type: GraphQLString,
            description:
            "Explains why this element was deprecated, usually also including a " +
                "suggestion for how to access supported similar data. Formatted " +
                "using the Markdown syntax, as specified by [CommonMark]" +
                "(https://commonmark.org/).",
            defaultValue: Map.string(defaultDeprecationReason)
        ),
    ]
)

/**
 * Used to provide a URL for specifying the behavior of custom scalar definitions.
 */
public let GraphQLSpecifiedByDirective = try! GraphQLDirective(
    name: "specifiedBy",
    description: "Exposes a URL that specifies the behavior of this scalar.",
    locations: [.scalar],
    args: [
        "url": GraphQLArgument(
            type: GraphQLNonNull(GraphQLString),
            description: "The URL that specifies the behavior of this scalar."
        ),
    ]
)

/**
 * Used to indicate an Input Object is a OneOf Input Object.
 */
public let GraphQLOneOfDirective = try! GraphQLDirective(
    name: "oneOf",
    description: "Indicates exactly one field must be supplied and this field must not be \\`null\\`.",
    locations: [.inputObject],
    args: [:]
)

/**
 * The full list of specified directives.
 */
let specifiedDirectives: [GraphQLDirective] = [
    GraphQLIncludeDirective,
    GraphQLSkipDirective,
    GraphQLDeprecatedDirective,
    GraphQLSpecifiedByDirective,
    GraphQLOneOfDirective,
]

func isSpecifiedDirective(_ directive: GraphQLDirective) -> Bool {
    return specifiedDirectives.contains { specifiedDirective in
        specifiedDirective.name == directive.name
    }
}
