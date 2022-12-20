# Session

[![Build Status][build status badge]][build status]
[![codebeat badge][codebeat status badge]][codebeat status]
[![codeclimate badge][codeclimate status badge]][codeclimate status]
[![codecov][codecov status badge]][codecov status]
![Platforms][platforms badge]

`Session` is a very lightweight wrapper over `URLSession` only focused on the `async` versions of its methods. This library will only focus on the usage of Swift Concurrency and thus, no completion handler based methods are implemented or will ever be.

## Why would I use this?

The main goal of this small wrapper is two fold:

- backwards compatibility of the `URLSession` async methods.
- rapid prototyping of a `URLSession` object, with simple configurations in a SwiftUI DSL fashion.


## Installation

If you're working directly in a Package, add `Session` to your Package.swift file

```swift
dependencies: [
    .package(url: "https://github.com/JARMourato/Session.git", .upToNextMajor(from: "1.0.0")),
]
```

If working in an Xcode project select `File->Add Packages...` and search for the package name: `Session` or the git url:

`https://github.com/JARMourato/Session.git`

## Usage

### Initialization 

Here is how one would create a `Session` object 

```swift
let session = Session()
```

Pretty simple am I right ? 🙃

When nothing is specified, every option follows the defaults used by Apple. So a session created without any parameters uses `URLSessionConfiguration.default`. 


However, one might need to change a configuration or two. So here are the options you could use: 

```swift
let session = Session {
	// Set up caching
	Cache(urlCache: /*Some URLCache*/)
	// Delegates       
	Delegate.session(/*some URLSessionDelegate object*/) 
	Delegate.task(/*some URLSessionTaskDelegate object*/) // Only relevant for iOS 15 and above.
	// Turn off some default behaviors
	Disable.constrainedNetworkAccess
	Disable.expensiveNetworkAccess
	// Turn on additional behavior
	Enable.waitingForConnectivity
	// Add session wide headers         
	Headers(httpHeaders: [:])
	// Set your own URLSessionConfiguration preset
	Preset.background(identifier: "some id", sharedContainerIdentifier: "optional shared container id", isDiscretionary: false /* default is true */)
	Preset.custom(/* Some URLSessionConfiguration object*/) 
	Preset.ephemeral
	// Set a mock or something... 
	ProtocolClasses(classes: [ /* some classes */ ])
	// Override the default timeouts
	Timeout.request(10)
	Timeout.resource(60)
}
```

### Methods

**Given that all methods are `async` you have to run them in an `async` context such as within `Task { /* your code */ }`.**

The library adds a syntax sugar by way of a `Requestable` protocol: 

```swift
public protocol Requestable {
    func buildURLRequest() throws -> URLRequest
}
```

Which means, that any type that conforms to `Requestable` can be used directly in the methods as opposed to being bounded by the usage of a `URLRequest`. Naturally, `URLRequest` conforms to `Requestable` so you still can use that. 

The provided methods are wrappers over the `URLSession` versions, providing backwards compatibility with `async` as well as a couple helper return types. 

### Data

Nothing fancy here

```swift
let response = try await session.data(for: requestable) 
let data: Data = response.data
let urlResponse: URLResponse = response.urlResponse
```

or if you want to get your `Requestable` paired with the response

```swift
let response = try await session.dataResponse(for: requestable) 
let request: some Requestable = response.request
let data: Data = response.result.data
let urlResponse: URLResponse = response.result.urlResponse
```

### Download

```swift
let response = try await session.download(for: requestable) /* or try await session.download(resumeFrom: data)  */
let location: URL = response.url
let urlResponse: URLResponse = response.urlResponse
```

### Upload

```swift
let response = try await session.upload(for: requestable, fromFile: url) /* or try await session.upload(for: requestable, fromData: data)  */
let data: Data = response.data
let urlResponse: URLResponse = response.urlResponse
```

## Contributions

If you feel like something is missing or you want to add any new functionality, please open an issue requesting it and/or submit a pull request with passing tests 🙌

## License

This project is open source and covered by a standard 2-clause BSD license. That means you can use (publicly, commercially and privately), modify and distribute this project's content, as long as you mention João Mourato as the original author of this code and reproduce the LICENSE text inside your app, repository, project or research paper.

## Contact

João ([@_JARMourato](https://twitter.com/_JARMourato))

[build status]: https://github.com/JARMourato/Session/actions?query=workflow%3ACI
[build status badge]: https://github.com/JARMourato/Session/workflows/CI/badge.svg
[codebeat status]: https://codebeat.co/projects/github-com-jarmourato-session-main
[codebeat status badge]: https://codebeat.co/badges/a209283f-2c79-4515-8a8b-c09c59fabb9a
[codeclimate status]: https://codeclimate.com/github/JARMourato/Session/maintainability
[codeclimate status badge]: https://api.codeclimate.com/v1/badges/acf483a14e7a38c9fc43/maintainability
[codecov status]: https://codecov.io/gh/JARMourato/Session
[codecov status badge]: https://codecov.io/gh/JARMourato/Session/branch/main/graph/badge.svg?token=XAHCCI1JNM
[platforms badge]: https://img.shields.io/static/v1?label=Platforms&message=iOS%20|%20macOS%20|%20tvOS%20|%20watchOS%20&color=brightgreen
