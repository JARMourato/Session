// Copyright © 2022 João Mourato. All rights reserved.

import Foundation

// MARK: - Configuration

public protocol Configuration {}

/// The default session configuration uses the app shared URL cache object, use this to set your own cache.
public struct Cache: Configuration {
    let urlCache: URLCache

    public init(urlCache: URLCache) {
        self.urlCache = urlCache
    }
}

/// Sets the delegates at Session level and at a Task Level
public enum Delegate: Configuration {
    case session(URLSessionDelegate)
    /// Note: only available for iOS 15 or above
    case task(URLSessionTaskDelegate)
}

/// Disables default session behaviors
public enum Disable: Configuration {
    /// Disables the session to connect using a constrained network interface. A constrained network interface
    /// is one where the user turns on “Low Data Mode” in the device settings.
    case constrainedNetworkAccess
    /// Disables the session to connect over an “expensive” network interface. The system decides
    /// what an expensive network is but typically it’s a cellular or personal hotspot.
    case expensiveNetworkAccess
}

/// Enables additional session behaviors
public enum Enable: Configuration {
    /// Causes the session to waiting for connectivity instead of failling immediately, which would be preferable to testing for reachability.
    /// Note: The `Timeout.resource` configuration determines how long the session will wait for connectivity. Background sessions
    /// always wait for connectivity.
    case waitingForConnectivity
}

/// Sets custom HTTP headers to all of your requests.
public struct Headers: Configuration {
    let httpHeaders: [String: String]

    public init(httpHeaders: [String: String]) {
        self.httpHeaders = httpHeaders
    }
}

/// These will be used as a base configuration for the `URLSessionConfiguration` otherwise, the `URLSessionConfiguration.default` will be used.
public enum Preset: Configuration {
    /// For network tasks that you want to run in the background.
    ///  - Parameter identifier: an identifier needs to be used to rebuild your session and resume running tasks correctly.
    ///  - Parameter sharedContainerIdentifier: used when implementing background downloading
    ///  and uploading inside an app extension.
    ///  - Parameter isDiscretionary: if set to `true` the system will decide when to start the transfer, useful for non-urgent tasks.
    case background(identifier: String, sharedContainerIdentifier: String? = nil, isDiscretionary: Bool = true)
    /// To be able to inject a configuration, in case there are options not provided by the framework.
    /// All options that are provided by the framework will override the custom session configuration provided values
    case custom(URLSessionConfiguration)
    /// An ephemeral session keeps cache data, credentials or other session related data in memory. It’s never written to disk which helps protects user privacy.
    /// You destroy the session data when you invalidate the session. This is similar to how a web browser behaves when private browsing.
    case ephemeral
}

/// An array of extra protocol subclasses that handle requests in a session.
public struct ProtocolClasses: Configuration {
    let classes: [AnyClass]

    public init(classes: [AnyClass]) {
        self.classes = classes
    }
}

/// To set per session timeouts
public enum Timeout: Configuration {
    /// The timeout interval, in seconds, that a task will wait for data to arrive. The timer resets each time new data arrives. Default is 60 seconds.
    case request(Int)
    /// The timeout interval, in seconds, that a task will wait for the whole resource request to complete. The default value is 7 days.
    case resource(Int)
}

// MARK: - Session Creation

internal func createSession(from configs: [Configuration]) -> (URLSession, URLSessionTaskDelegate?) {
    // Set all user configurations override if needed
    let configuration = configs.urlSessionConfiguration
    configuration.overrideValueIfNeededFor(\.allowsConstrainedNetworkAccess, with: configs.allowsConstrainedNetworkAccess)
    configuration.overrideValueIfNeededFor(\.allowsExpensiveNetworkAccess, with: configs.allowsExpensiveNetworkAccess)
    configuration.overrideValueIfNeededFor(\.httpAdditionalHeaders, with: configs.httpAdditionalHeaders)
    configuration.overrideValueIfNeededFor(\.protocolClasses, with: configs.protocolClasses)
    configuration.overrideValueIfNeededFor(\.timeoutIntervalForRequest, with: configs.timeoutIntervalForRequest)
    configuration.overrideValueIfNeededFor(\.timeoutIntervalForResource, with: configs.timeoutIntervalForResource)
    configuration.overrideValueIfNeededFor(\.urlCache, with: configs.cache)
    configuration.overrideValueIfNeededFor(\.waitsForConnectivity, with: configs.waitsForConnectivity)
    // Create URLSession
    let session = URLSession(configuration: configuration, delegate: configs.sessionDelegate, delegateQueue: nil)
    return (session, configs.taskDelegate)
}

// MARK: Helpers for configuration array

extension [Configuration] {
    // MARK: Cache

    var cache: URLCache? { compactMap { $0 as? Cache }.first?.urlCache }

    // MARK: Delegates

    var delegates: [Delegate] { compactMap { $0 as? Delegate } }

    var sessionDelegate: URLSessionDelegate? {
        delegates.compactMap { delegate in
            guard case let .session(sdel) = delegate else { return nil }
            return sdel
        }.first
    }

    var taskDelegate: URLSessionTaskDelegate? {
        delegates.compactMap { delegate in
            guard case let .task(tdel) = delegate else { return nil }
            return tdel
        }.first
    }

    // MARK: Disabled/Enabled

    var disabled: [Disable] { compactMap { $0 as? Disable } }
    var enabled: [Enable] { compactMap { $0 as? Enable } }

    var allowsConstrainedNetworkAccess: Bool? {
        guard let _ = disabled.firstIndex(of: .constrainedNetworkAccess) else { return nil }
        return false
    }

    var allowsExpensiveNetworkAccess: Bool? {
        guard let _ = disabled.firstIndex(of: .expensiveNetworkAccess) else { return nil }
        return false
    }

    var waitsForConnectivity: Bool? {
        guard let _ = enabled.firstIndex(of: .waitingForConnectivity) else { return nil }
        return true
    }

    // MARK: Headers

    var httpAdditionalHeaders: [String: String]? { compactMap { $0 as? Headers }.first?.httpHeaders }

    // MARK: Presets

    var urlSessionConfiguration: URLSessionConfiguration {
        compactMap { $0 as? Preset }.first?.configuration ?? .default
    }

    // MARK: Protocol Classes

    var protocolClasses: [AnyClass]? {
        compactMap { $0 as? ProtocolClasses }.first?.classes
    }

    // MARK: Timeouts

    var timeouts: [Timeout] { compactMap { $0 as? Timeout } }

    var timeoutIntervalForRequest: TimeInterval? {
        timeouts.compactMap { timeout in
            guard case let .request(seconds) = timeout else { return nil }
            return TimeInterval(seconds)
        }.first
    }

    var timeoutIntervalForResource: TimeInterval? {
        timeouts.compactMap { timeout in
            guard case let .resource(seconds) = timeout else { return nil }
            return TimeInterval(seconds)
        }.first
    }
}

// MARK: Helpers for specific configs

extension Preset {
    var configuration: URLSessionConfiguration {
        switch self {
        case let .background(identifier, sharedContainerIdentifier, isDiscretionary):
            let config = URLSessionConfiguration.background(withIdentifier: identifier)
            config.sharedContainerIdentifier = sharedContainerIdentifier
            config.isDiscretionary = isDiscretionary
            return config
        case let .custom(configuration):
            return configuration
        case .ephemeral:
            return .ephemeral
        }
    }
}

// MARK: Defaults

internal enum ConfigDefaults {
    static var timeoutIntervalForRequest: TimeInterval { 60 }
    static var timeoutIntervalForResource: TimeInterval { 604_800 } // 7 days
}

// MARK: Helper for configuration values override

extension URLSessionConfiguration {
    func overrideValueIfNeededFor<T>(_ keypath: ReferenceWritableKeyPath<URLSessionConfiguration, T>, with optionalValue: T?) {
        guard let optionalValue else { return }
        self[keyPath: keypath] = optionalValue
    }

    func overrideValueIfNeededFor<T>(_ keypath: ReferenceWritableKeyPath<URLSessionConfiguration, T?>, with optionalValue: T?) {
        guard case let .some(value) = optionalValue else { return }
        self[keyPath: keypath] = value
    }
}

protocol OptionalProtocol {}

extension Optional: OptionalProtocol {}
