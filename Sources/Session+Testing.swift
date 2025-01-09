// Copyright © 2025 JARMourato All rights reserved.

import Foundation

// MARK: - Testing Helpers

protocol SessionTask: AnyObject {
    var taskDelegate: URLSessionTaskDelegate? { get set }
    func resume()
}

extension URLSessionTask: SessionTask {
    var taskDelegate: URLSessionTaskDelegate? {
        get { delegate }
        set { delegate = newValue }
    }
}
