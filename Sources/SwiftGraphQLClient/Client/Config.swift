import Foundation
import Logging

/// A structure that lets you configure 
public final class ClientConfiguration: @unchecked Sendable {
    
    /// Logger that we use to communitcate state changes and events inside the client.
    public var logger: Logger = Logger(label: "graphql.client")
    
    public init() {
        // Certain built-in exchanges (e.g. `DebugExchange`) product `.debug` logs that require `.debug` log level to be visible. This makes sure that the expected functionality of all exchanges matches the actual functionality (e.g. "debug exchange actually prints messages in the console").
        self.logger.logLevel = .debug
    }
}
