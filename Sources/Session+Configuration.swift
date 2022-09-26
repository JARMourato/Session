import Foundation

// MARK: - Configuration

public protocol Configuration {}

/// The default session configuration uses the app shared URL cache object, use this to set your own cache.
public struct Cache: Configuration {
    let urlCache: URLCache
}

/// Sets the delegates at Session level and at a Task Level
public enum Delegate: Configuration {
    case session(URLSessionDelegate)
    case task(URLSessionTaskDelegate)
}

/// Sets a URLSession delegate
public enum Disable: Configuration {
    /// Disables the session to connect using a constrained network interface. A constrained network interface
    /// is one where the user turns on “Low Data Mode” in the device settings.
    case constrainedNetworkAccess
    /// Disables the session to connect over an “expensive” network interface. The system decides
    /// what an expensive network is but typically it’s a cellular or personal hotspot.
    case expensiveNetworkAccess
    /// Causes the session to fail immediately instead of waiting for connectivity, which is preferable to testing for reachability.
    /// Note: The `Timeout.resource` configuration determines how long the session will wait for connectivity. Background sessions
    /// always wait for connectivity.
    case waitingForConnectivity
}

/// Sets custom HTTP headers to all of your requests.
public struct Headers: Configuration {
    let httpHeaders: [String: String]
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
    /// All options that are provided by the framework will override the custom sessoin configuration provided values
    /// even if no option is provided, in which case the default configuration values for those options is assigned
    case custom(URLSessionConfiguration)
    /// An ephemeral session keeps cache data, credentials or other session related data in memory. It’s never written to disk which helps protects user privacy.
    /// You destroy the session data when you invalidate the session. This is similar to how a web browser behaves when private browsing.
    case ephemeral
}

/// An array of extra protocol subclasses that handle requests in a session.
public struct ProtocolClasses: Configuration {
    let classes: [AnyClass]
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
    // Set all user configurations
    let configuration = configs.urlSessionConfiguration
    configuration.allowsConstrainedNetworkAccess = configs.allowConstrainedNetworkAccess
    configuration.allowsExpensiveNetworkAccess = configs.allowExpensiveNetworkAccess
    configuration.httpAdditionalHeaders = configs.httpAdditionalHeaders
    configuration.protocolClasses = configs.protocolClasses
    configuration.timeoutIntervalForRequest = configs.timeoutIntervalForRequest
    configuration.timeoutIntervalForResource = configs.timeoutIntervalForResource
    configuration.urlCache = configs.cache
    configuration.waitsForConnectivity = configs.waitsForConnectivity
    // Create URLSession
    let session = URLSession(configuration: configuration, delegate: configs.sessionDelegate, delegateQueue: nil)
    return (session, configs.taskDelegate)
}

// MARK: Helpers for configuration array

extension Array where Element == Configuration {
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

    // MARK: Disabled

    var disabled: [Disable] { compactMap { $0 as? Disable } }
    var allowConstrainedNetworkAccess: Bool { !disabled.contains(.constrainedNetworkAccess) }
    var allowExpensiveNetworkAccess: Bool { !disabled.contains(.expensiveNetworkAccess) }
    var waitsForConnectivity: Bool { !disabled.contains(.waitingForConnectivity) }

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

    var timeoutIntervalForRequest: TimeInterval {
        timeouts.compactMap { timeout in
            guard case let .request(seconds) = timeout else { return nil }
            return TimeInterval(seconds)
        }.first ?? ConfigDefaults.timeoutIntervalForRequest
    }

    var timeoutIntervalForResource: TimeInterval {
        timeouts.compactMap { timeout in
            guard case let .resource(seconds) = timeout else { return nil }
            return TimeInterval(seconds)
        }.first ?? ConfigDefaults.timeoutIntervalForResource
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
