import Foundation

public struct CacheConfiguration: Sendable {
    public typealias DateProvider = @Sendable () -> Date

    public let ttl: TimeInterval
    public let dateProvider: DateProvider

    public init(ttl: TimeInterval, dateProvider: @escaping DateProvider = { Date() }) {
        self.ttl = ttl
        self.dateProvider = dateProvider
    }

    public static let fiveMinutes = CacheConfiguration(ttl: 5 * 60)
}

public actor InMemoryCache<Key: Hashable, Value> {
    private let configuration: CacheConfiguration
    private var storage: [Key: Entry]

    public init(configuration: CacheConfiguration = .fiveMinutes) {
        self.configuration = configuration
        self.storage = [:]
    }

    public func value(forKey key: Key) -> Value? {
        let now = configuration.dateProvider()
        guard let entry = storage[key] else {
            return nil
        }

        if entry.isValid(at: now) {
            return entry.value
        }

        storage.removeValue(forKey: key)
        return nil
    }

    public func insert(_ value: Value, forKey key: Key) {
        let expirationDate = configuration.dateProvider().addingTimeInterval(configuration.ttl)
        storage[key] = Entry(value: value, expirationDate: expirationDate)
    }

    public func removeValue(forKey key: Key) {
        storage.removeValue(forKey: key)
    }

    public func removeAll() {
        storage.removeAll()
    }

    public func clearExpiredValues() {
        let now = configuration.dateProvider()
        storage = storage.filter { $0.value.isValid(at: now) }
    }

    private struct Entry {
        let value: Value
        let expirationDate: Date

        func isValid(at date: Date) -> Bool {
            expirationDate > date
        }
    }
}
