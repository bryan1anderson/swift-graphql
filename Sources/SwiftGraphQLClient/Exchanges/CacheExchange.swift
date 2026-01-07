import Combine
import Foundation

/// Exchange that lets you naively cache GraphQL resutls of your queries.
///
/// Cache exchange uses document caching to invalidate results. That means that
/// when a mutation result with a return type T goes through the cache exchange,
/// cache exchange invalidates all cached queries that contain a result of type T.
///
/// - NOTE: Cache exchange doesn't perform any deduplication of requests.
///
/// - NOTE: The caching pattern used here is greedy and not optimal.
public class CacheExchange: Exchange, @unchecked Sendable {

    /// Results from previous oeprations indexed by operation's ids.
    private var resultCache: [String: OperationResult]

    /// Index of operation IDs indexed by the typename in their result.
    private var operationCache: [String: Set<String>]

    /// Serial queue for synchronizing access to caches
    private let queue: DispatchQueue

    public init() {
        self.resultCache = [:]
        self.operationCache = [:]
        self.queue = DispatchQueue(label: "com.swiftgraphql.cacheexchange")
    }

    /// Clears all cached results.
    ///
    /// - NOTE: This method doesn't re-execute any of the watched queries.
    public func clear() {
        queue.sync {
            self.resultCache = [:]
            self.operationCache = [:]
        }
    }

    /// Tells whether a given operation should rely on the result saved in the cache.
    ///
    /// - NOTE: CacheOnly operations might get a nil value and fail when selection tries
    ///         to decode them. That's O.K.
    private func shouldUseCache(operation: Operation) -> Bool {
        queue.sync {
            operation.kind == .query && operation.policy != .networkOnly && (operation.policy == .cacheOnly || resultCache[operation.id] != nil)
        }
    }

    public func register(
        client: GraphQLClient,
        operations: AnyPublisher<Operation, Never>,
        next: @escaping ExchangeIO
    ) -> AnyPublisher<OperationResult, Never> {
        let shared = operations.share()

        // We synchronously send cached results upstream.
        let cachedOps: AnyPublisher<OperationResult, Never> =
            shared
            .compactMap { [weak self] operation in
                guard let self = self else { return nil }
                return self.queue.sync {
                    let shouldUseCache = operation.kind == .query && operation.policy != .networkOnly && (operation.policy == .cacheOnly || self.resultCache[operation.id] != nil)

                    guard shouldUseCache else {
                        return nil
                    }

                    let cachedResult = self.resultCache[operation.id]
                    if operation.policy == .cacheAndNetwork {
                        return cachedResult?.with(stale: true)
                    }
                    return cachedResult
                }
            }
            .eraseToAnyPublisher()

        // We filter requests that hit cache and listen for results
        // to keep track of received results.
        let downstream =
            shared
            .filter({ [weak self] operation in
                guard let self = self else { return false }
                return self.queue.sync {
                    // Cache stops cache-only operations - they shouldn't reach any
                    // other exchange for obvious reasons.
                    guard operation.policy != .cacheOnly else {
                        return false
                    }

                    // We only cache queries and ignore all other kinds of transactions.
                    guard operation.kind == .query else {
                        return true
                    }

                    // Filter out cache-first requests that were matched/hit.
                    let wasHit = operation.policy == .cacheFirst && self.resultCache[operation.id] != nil
                    return operation.policy != .cacheFirst || !wasHit
                }
            })
            .eraseToAnyPublisher()

        let forwardedOps: AnyPublisher<OperationResult, Never> = next(downstream)

        let upstream =
            forwardedOps
            .handleEvents(receiveOutput: { [weak self] result in
                guard let self = self else { return }
                let operationsToReexecute: [Operation] = self.queue.sync {
                    var operationsToReexecute = [Operation]()

                    // Invalidate the cache given a mutation's response.
                    if result.operation.kind == .mutation {
                        var pendingOperations = Set<String>()

                        // Collect all operations that need to be invalidated.
                        for typename in result.operation.types {
                            guard let cachedOperations = self.operationCache[typename] else {
                                continue
                            }
                            cachedOperations.forEach { pendingOperations.insert($0) }
                        }

                        // Invalidate all operations that need invalidation.
                        for opid in pendingOperations {
                            guard let cachedResult = self.resultCache[opid] else {
                                continue
                            }

                            self.resultCache.removeValue(forKey: opid)
                            operationsToReexecute.append(cachedResult.operation.with(policy: .networkOnly))
                        }
                    }

                    // Cache query result and operation references.
                    // (AnyCodable represents nil values as Void objects.)
                    if result.operation.kind == .query, result.error == nil {
                        self.resultCache[result.operation.id] = result

                        // NOTE: cache-only operations never receive data from the
                        //       exchanges coming after the cache (i.e. from the upstream stream)
                        //       meaning they are never indexed for re-execution.
                        for typename in result.operation.types {
                            if self.operationCache[typename] == nil {
                                self.operationCache[typename] = Set<String>()
                            }

                            self.operationCache[typename]!.insert(result.operation.id)
                        }
                    }

                    return operationsToReexecute
                }

                for operationToReexecute in operationsToReexecute {
                    client.reexecute(operation: operationToReexecute)
                }
            })
            .eraseToAnyPublisher()

        return cachedOps.merge(with: upstream).eraseToAnyPublisher()
    }
}
