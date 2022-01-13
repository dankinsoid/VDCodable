//
//  VDEncoder.swift
//  VDCodable
//
//  Created by Daniil on 10.08.2019.
//

import Foundation

public protocol EncodingBoxer {
    associatedtype Output
    var codingPath: [CodingKey] { get }
    var userInfo: [CodingUserInfoKey: Any] { get }
    init(path: [CodingKey], other boxer: Self)
    func encode(_ dictionary: [String: Output]) throws -> Output
    func encode(_ array: [Output]) throws -> Output
    func encodeNil() throws -> Output
    func encode(_ value: Bool) throws -> Output
    func encode(_ value: String) throws -> Output
    func encode(_ value: Double) throws -> Output
    func encode(_ value: Float) throws -> Output
    func encode(_ value: Int) throws -> Output
    func encode(_ value: Int8) throws -> Output
    func encode(_ value: Int16) throws -> Output
    func encode(_ value: Int32) throws -> Output
    func encode(_ value: Int64) throws -> Output
    func encode(_ value: UInt) throws -> Output
    func encode(_ value: UInt8) throws -> Output
    func encode(_ value: UInt16) throws -> Output
    func encode(_ value: UInt32) throws -> Output
    func encode(_ value: UInt64) throws -> Output
    func encode<T: Encodable>(value: T) throws -> Output
    func encodeIfPresent(_ value: Bool?) throws -> Output?
    func encodeIfPresent(_ value: String?) throws -> Output?
    func encodeIfPresent(_ value: Double?) throws -> Output?
    func encodeIfPresent(_ value: Float?) throws -> Output?
    func encodeIfPresent(_ value: Int?) throws -> Output?
    func encodeIfPresent(_ value: Int8?) throws -> Output?
    func encodeIfPresent(_ value: Int16?) throws -> Output?
    func encodeIfPresent(_ value: Int32?) throws -> Output?
    func encodeIfPresent(_ value: Int64?) throws -> Output?
    func encodeIfPresent(_ value: UInt?) throws -> Output?
    func encodeIfPresent(_ value: UInt8?) throws -> Output?
    func encodeIfPresent(_ value: UInt16?) throws -> Output?
    func encodeIfPresent(_ value: UInt32?) throws -> Output?
    func encodeIfPresent(_ value: UInt64?) throws -> Output?
    func encodeIfPresent<T: Encodable>(value: T?) throws -> Output?
}

extension EncodingBoxer {
    public var userInfo: [CodingUserInfoKey: Any] { return [:] }
    public func encode(_ value: Float) throws -> Output { return try encode(Double(value)) }
    public func encode(_ value: Int8) throws -> Output { return try encode(Int(value)) }
    public func encode(_ value: Int16) throws -> Output { return try encode(Int(value)) }
    public func encode(_ value: Int32) throws -> Output { return try encode(Int(value)) }
    public func encode(_ value: Int64) throws -> Output { return try encode(Int(value)) }
    public func encode(_ value: UInt) throws -> Output {
        guard value <= UInt(Int.max) else {
            throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: codingPath, debugDescription: "Value is out of Int"))
        }
        return try encode(Int(value))
    }
    public func encode(_ value: UInt8) throws -> Output { return try encode(UInt(value)) }
    public func encode(_ value: UInt16) throws -> Output { return try encode(UInt(value)) }
    public func encode(_ value: UInt32) throws -> Output { return try encode(UInt(value)) }
    public func encode(_ value: UInt64) throws -> Output { return try encode(UInt(value)) }
    public func encode<T: Encodable>(value: T) throws -> Output {
        var encoder = VDEncoder(boxer: self)
        return try encoder.encode(value)
    }
    
    @inline(__always)
    private func encodeAnyIfPresent<T>(_ value: T?, _ block: (T) throws -> Output) throws -> Output? {
        guard let result = value else { return nil }
        return try block(result)
    }
    
    public func encodeIfPresent(_ value: Bool?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: String?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Double?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Float?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Int?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Int8?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Int16?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Int32?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: Int64?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: UInt?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: UInt8?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: UInt16?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: UInt32?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent(_ value: UInt64?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
    public func encodeIfPresent<T: Encodable>(value: T?) throws -> Output? { try encodeAnyIfPresent(value, encode) }
}

public struct VDEncoder<Boxer: EncodingBoxer>: Encoder {
    public var codingPath: [CodingKey] { return boxer.codingPath }
    public var userInfo: [CodingUserInfoKey: Any] { return boxer.userInfo }
    fileprivate var storage = EncoderStorage<Boxer.Output>(.single(SingleStorage()))
    public let boxer: Boxer
    
    public init(boxer: Boxer) {
        self.boxer = boxer
    }
    
   public func container<Key: CodingKey>(keyedBy type: Key.Type) -> KeyedEncodingContainer<Key> {
        var container = _KeyedContainer<Key, Boxer>(boxer: boxer)
        switch storage.kind {
        case .unkeyed(let array):
            array.value.append(.keyed(container.output))
        case .keyed(let dict):
            container.output = dict
        case .single(let value):
            if let output = value.value {
                storage.kind = .unkeyed(UnkeyedStorage([.just(output), .keyed(container.output)]))
            } else {
                storage.kind = .keyed(container.output)
            }
        }
        return KeyedEncodingContainer(container)
    }
    
    public func unkeyedContainer() -> UnkeyedEncodingContainer {
        var container = _UnkeyedContainer(boxer: boxer)
        switch storage.kind {
        case .unkeyed(let array):
            container.storage = array
        case .keyed(let dict):
            storage.kind = .unkeyed(UnkeyedStorage([.keyed(dict), .unkeyed(container.storage)]))
        case .single(let value):
            if let output = value.value {
                storage.kind = .unkeyed(UnkeyedStorage([.just(output), .unkeyed(container.storage)]))
            } else {
                storage.kind = .unkeyed(container.storage)
            }
        }
        return container
    }
    
    public func singleValueContainer() -> SingleValueEncodingContainer {
        let container = _SingleContainer(boxer: boxer)
        switch storage.kind {
        case .unkeyed(let array):
            array.value.append(EncoderStorage(.single(container.storage)))
        case .keyed(let dict):
            storage.kind = .unkeyed(UnkeyedStorage([.keyed(dict), EncoderStorage(.single(container.storage))]))
        case .single(let value):
            if let output = value.value {
                storage.kind = .unkeyed(UnkeyedStorage([.just(output), EncoderStorage(.single(container.storage))]))
            } else {
                storage.kind = .single(container.storage)
            }
        }
        return container
    }
    
    public mutating func encode<E: Encodable>(_ value: E) throws -> Boxer.Output {
        try value.encode(to: self)
        let value = try get()
//        storage.kind = .single(SingleStorage())
        return value
    }
    
    public mutating func get() throws -> Boxer.Output {
        let result = try encode(value: storage)
        return result
    }
    
    private func encode(value: EncoderStorage<Boxer.Output>) throws -> Boxer.Output {
        switch value.kind {
        case .unkeyed(let array):
            return try boxer.encode(array.value.map(self.encode))
        case .keyed(let dictionary):
            return try boxer.encode(dictionary.value.mapValues(self.encode))
        case .single(let value):
            guard let output = value.value else {
                throw EncodingError.invalidValue(value.value as Any, EncodingError.Context(codingPath: codingPath, debugDescription: "No value"))
            }
            return output
        }
    }
    
}

fileprivate class EncoderStorage<Output> {
    enum Kind {
        case unkeyed(UnkeyedStorage<Output>), keyed(KeyedStorage<Output>), single(SingleStorage<Output>)
    }
    var kind: Kind
    
    init(_ value: Kind) {
        kind = value
    }
    
    static func just(_ value: Output) -> EncoderStorage {
        return EncoderStorage(.single(.init(value)))
    }
    
    static func keyed(_ value: KeyedStorage<Output>) -> EncoderStorage {
        return EncoderStorage(.keyed(value))
    }
    
    static func unkeyed(_ value: UnkeyedStorage<Output>) -> EncoderStorage {
        return EncoderStorage(.unkeyed(value))
    }
}

fileprivate final class UnkeyedStorage<Output> {
    var value: [EncoderStorage<Output>] = []
    
    init(_ value: [EncoderStorage<Output>]) {
        self.value = value
    }
}

fileprivate final class KeyedStorage<Output> {
    var value: [String: EncoderStorage<Output>] = [:]
    
    init(_ value: [String: EncoderStorage<Output>]) {
        self.value = value
    }
    
}

fileprivate final class SingleStorage<Output> {
    var value: Output?
    
    init() {}
    
    init(_ value: Output) {
        self.value = value
    }
}

fileprivate struct _KeyedContainer<Key: CodingKey, Boxer: EncodingBoxer>: KeyedEncodingContainerProtocol {
    var codingPath: [CodingKey] { return _boxer.codingPath }
    let _boxer: Boxer
    var output = KeyedStorage<Boxer.Output>([:])
    var isEmpty: Bool { return output.value.isEmpty }
    
    init(boxer: Boxer) {
        _boxer = boxer
    }
    
    func boxer(_ key: CodingKey) -> Boxer {
        return Boxer(path: codingPath + [key], other: _boxer)
    }
    
    func encodeNil(forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encodeNil())
    }
    
    func encode(_ value: Bool, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: String, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Double, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Float, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Int, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Int8, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Int16, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Int32, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: Int64, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: UInt, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: UInt8, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: UInt16, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: UInt32, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode(_ value: UInt64, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value))
    }
    
    func encode<T: Encodable>(_ value: T, forKey key: Key) throws {
        output.value[key.stringValue] = try .just(boxer(key).encode(value: value))
    }
    
    private func encodeNoNil<T>(_ value: T?, forKey key: Key, _ block: (T?) throws -> Boxer.Output?) throws {
        guard let value = try block(value) else { return }
        output.value[key.stringValue] = .just(value)
    }
    
    func encodeIfPresent(_ value: Bool?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: String?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Double?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Float?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Int?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Int8?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Int16?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Int32?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: Int64?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: UInt?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: UInt8?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: UInt16?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: UInt32?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent(_ value: UInt64?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    func encodeIfPresent<T: Encodable>(_ value: T?, forKey key: Key) throws { try encodeNoNil(value, forKey: key, boxer(key).encodeIfPresent) }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type, forKey key: Key) -> KeyedEncodingContainer<NestedKey> {
        let container = _KeyedContainer<NestedKey, Boxer>(boxer: boxer(key))
         output.value[key.stringValue] = .keyed(container.output)
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) -> UnkeyedEncodingContainer {
        let container = _UnkeyedContainer(boxer: boxer(key))
        output.value[key.stringValue] = .unkeyed(container.storage)
        return container
    }
    
    func superEncoder() -> Encoder {
        let key = PlainCodingKey("super")
        let encoder = VDEncoder(boxer: boxer(key))
        output.value[key.stringValue] = encoder.storage
        return encoder
    }
    
    func superEncoder(forKey key: Key) -> Encoder {
        let encoder = VDEncoder(boxer: boxer(key))
        output.value[key.stringValue] = encoder.storage
        return encoder
    }
    
}

fileprivate struct _UnkeyedContainer<Boxer: EncodingBoxer>: UnkeyedEncodingContainer {
    var codingPath: [CodingKey] { return _boxer.codingPath }
    var storage = UnkeyedStorage<Boxer.Output>([])
    var count: Int { return storage.value.count }
    let _boxer: Boxer
    
    init(boxer: Boxer) {
        _boxer = boxer
    }
    
    func boxer() -> Boxer {
        return Boxer(path: codingPath + [PlainCodingKey(count)], other: _boxer)
    }
    
    func encodeNil() throws {
        try storage.value.append(.just(boxer().encodeNil()))
    }
    
    func encode(_ value: Bool) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: String) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Double) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Float) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Int) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Int8) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Int16) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Int32) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: Int64) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: UInt) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: UInt8) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: UInt16) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: UInt32) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    func encode(_ value: UInt64) throws {
        try storage.value.append(.just(boxer().encode(value)))
    }
    
    mutating func encode<T: Encodable>(_ value: T) throws {
        try storage.value.append(.just(boxer().encode(value: value)))
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy keyType: NestedKey.Type) -> KeyedEncodingContainer<NestedKey> {
        var path = codingPath
        path.append(PlainCodingKey(count))
        let container = _KeyedContainer<NestedKey, Boxer>(boxer: boxer())
        storage.value.append(.keyed(container.output))
        return KeyedEncodingContainer(container)
    }
    
    func nestedUnkeyedContainer() -> UnkeyedEncodingContainer {
        let container = _UnkeyedContainer<Boxer>(boxer: boxer())
        storage.value.append(.unkeyed(container.storage))
        return container
    }
    
    func superEncoder() -> Encoder {
        let encoder = VDEncoder(boxer: boxer())
        storage.value.append(encoder.storage)
        return encoder
    }
    
}

fileprivate final class _SingleContainer<Boxer: EncodingBoxer>: SingleValueEncodingContainer {
    var codingPath: [CodingKey] { return boxer.codingPath }
    let storage = SingleStorage<Boxer.Output>()
    let boxer: Boxer
    
    init(boxer: Boxer) {
        self.boxer = boxer
    }
    
    func encodeNil() throws {
        storage.value = try boxer.encodeNil()
    }
    
    func encode(_ value: Bool) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: String) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Double) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Float) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Int) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Int8) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Int16) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Int32) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: Int64) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: UInt) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: UInt8) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: UInt16) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: UInt32) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode(_ value: UInt64) throws {
        storage.value = try boxer.encode(value)
    }
    
    func encode<T: Encodable>(_ value: T) throws {
        storage.value = try boxer.encode(value: value)
    }
    
}
