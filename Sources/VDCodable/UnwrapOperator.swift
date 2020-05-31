import Foundation

postfix operator ~!

postfix func ~!<T>(_ lhs: T?) throws -> T {
    guard let value = lhs else { throw OptionalException.noValue }
    return value
}

enum OptionalException: String, LocalizedError {
    case noValue
}
