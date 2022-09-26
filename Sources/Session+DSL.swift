import Foundation

// MARK: - DSL Session Builder

extension Session {
    @resultBuilder
    enum Builder {
        static func buildArray(_ components: [[Configuration]]) -> [Configuration] { components.flatMap { $0 } }
        static func buildBlock(_ components: [Configuration]...) -> [Configuration] { components.flatMap { $0 } }
        static func buildEither(first component: [Configuration]) -> [Configuration] { component }
        static func buildEither(second component: [Configuration]) -> [Configuration] { component }
        static func buildExpression(_ expression: Configuration) -> [Configuration] { [expression] }
        static func buildExpression(_ expression: [Configuration]) -> [Configuration] { expression }
        static func buildLimitedAvailability(_ component: [Configuration]) -> [Configuration] { component }
        static func buildOptional(_ component: [Configuration]?) -> [Configuration] { component ?? [] }
    }
}
