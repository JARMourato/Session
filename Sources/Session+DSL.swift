// Copyright © 2022 João Mourato. All rights reserved.

import Foundation

// MARK: - DSL Session Builder

public extension Session {
    @resultBuilder
    enum Builder {
        public static func buildArray(_ components: [[Configuration]]) -> [Configuration] { components.flatMap { $0 } }
        public static func buildBlock(_ components: [Configuration]...) -> [Configuration] { components.flatMap { $0 } }
        public static func buildEither(first component: [Configuration]) -> [Configuration] { component }
        public static func buildEither(second component: [Configuration]) -> [Configuration] { component }
        public static func buildExpression(_ expression: Configuration) -> [Configuration] { [expression] }
        public static func buildExpression(_ expression: [Configuration]) -> [Configuration] { expression }
        public static func buildLimitedAvailability(_ component: [Configuration]) -> [Configuration] { component }
        public static func buildOptional(_ component: [Configuration]?) -> [Configuration] { component ?? [] }
    }
}
