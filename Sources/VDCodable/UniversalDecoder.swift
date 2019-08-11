//
//  UniversalDecoder.swift
//  VDCodable
//
//  Created by Daniil on 10.08.2019.
//
import Foundation

public protocol DecodingUnboxer: SingleValueDecodingContainer {
    associatedtype Input
    var userInfo: [CodingUserInfoKey: Any] { get }
    var input: Input { get }
    init(input: Input, path: [CodingKey], other unboxer: Self)
    func decodeArray() throws -> [Input]
    func decodeDictionary() throws -> [String: Input]
}

extension DecodingUnboxer {
    
    public var userInfo: [CodingUserInfoKey: Any] { return [:] }
    
    public func decode(_ type: Int8.Type) throws -> Int8 {
        let int = try decode(Int.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: Int16.Type) throws -> Int16 {
        let int = try decode(Int.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: Int32.Type) throws -> Int32 {
        let int = try decode(Int.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: Int64.Type) throws -> Int64 {
        let int = try decode(Int.self)
        return type.init(int)
    }
    
    public func decode(_ type: UInt.Type) throws -> UInt {
        let int = try decode(Int.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: UInt8.Type) throws -> UInt8 {
        let int = try decode(UInt.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: UInt16.Type) throws -> UInt16 {
        let int = try decode(UInt.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: UInt32.Type) throws -> UInt32 {
        let int = try decode(UInt.self)
        guard int >= type.min && int <= type.max else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Number \(int) is out of \(type) range"))
        }
        return type.init(int)
    }
    
    public func decode(_ type: UInt64.Type) throws -> UInt64 {
        let int = try decode(UInt.self)
        return type.init(int)
    }
    
    public func decode(_ type: Float.Type) throws -> Float {
        return try Float(decode(Double.self))
    }
    
//    public func decode<T: Decodable>(_ type: T.Type) throws -> T {
//       let decoder = VDDecoder(unboxer: Self.init(input: input, path: codingPath, other: self))
//        return try T.init(from: decoder)
//    }
    
}

public struct VDDecoder<Unboxer: DecodingUnboxer>: Decoder {
    typealias Input = Unboxer.Input
    let unboxer: Unboxer
    public var userInfo: [CodingUserInfoKey : Any] { return unboxer.userInfo }
    public var codingPath: [CodingKey] { return unboxer.codingPath }
    
    public init(unboxer: Unboxer) {
        self.unboxer = unboxer
    }
    
    public func container<Key: CodingKey>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> {
        let container = try _KeyedDecodingContainer<Key, Unboxer>(unboxer: unboxer)
        return KeyedDecodingContainer(container)
    }
    
    public func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        let container = try _UnkeyedDecodingContaier(unboxer: unboxer)
        return container
    }
    
    public func singleValueContainer() throws -> SingleValueDecodingContainer {
        return unboxer
    }
}

fileprivate struct _KeyedDecodingContainer<Key: CodingKey, Unboxer: DecodingUnboxer>: KeyedDecodingContainerProtocol {
    typealias Input = Unboxer.Input
    var codingPath: [CodingKey] { return _unboxer.codingPath }
    var allKeys: [Key] { return self.getAllKeys() }
    let input: [String: Input]
    let _unboxer: Unboxer
    
    init(unboxer: Unboxer) throws {
        self._unboxer = unboxer
        do {
             self.input = try unboxer.decodeDictionary()
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: unboxer.codingPath, debugDescription: "Cannot get keyed decoding container.", underlyingError: error))
        }
    }
    
    func getAllKeys() -> [Key] {
        var result: [Key] = []
        for (keyString, _) in input {
            if let key = Key.init(stringValue: keyString) {
                result.append(key)
            }
        }
        return result
    }
    
    private func unboxer(_ data: Input, _ key: CodingKey) -> Unboxer {
        return Unboxer(input: data, path: codingPath + [key], other: _unboxer)
    }
    
    func contains(_ key: Key) -> Bool {
        return input[key.stringValue] != nil
    }
    
    func decodeNil(forKey key: Key) throws -> Bool {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return unboxer(js, key).decodeNil()
    }
    
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: String.Type, forKey key: Key) throws -> String {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        return try unboxer(js, key).decode(type)
    }
    
    func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        var path = codingPath
        path.append(key)
        let container = try _KeyedDecodingContainer<NestedKey, Unboxer>(unboxer: unboxer(js, key))
        return KeyedDecodingContainer(container)
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        var path = codingPath
        path.append(key)
        return try _UnkeyedDecodingContaier(unboxer: unboxer(js, key))
    }
    
    func superDecoder() throws -> Decoder {
        let key = PlainCodingKey("super")
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        var path = codingPath
        path.append(key)
        let decoder = VDDecoder(unboxer: unboxer(js, key))
        return decoder
    }
    
    func superDecoder(forKey key: Key) throws -> Decoder {
        guard let js = input[key.stringValue] else {
            throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: codingPath + [key], debugDescription: "No value associated with key '\(key.stringValue)'."))
        }
        var path = codingPath
        path.append(key)
        return VDDecoder(unboxer: unboxer(js, key))
    }
    
}

fileprivate struct _UnkeyedDecodingContaier<Unboxer: DecodingUnboxer>: UnkeyedDecodingContainer {
    typealias Input = Unboxer.Input
    var codingPath: [CodingKey] { return _unboxer.codingPath }
    var count: Int? { return input.count }
    var currentIndex: Int = 0
    var isAtEnd: Bool { return currentIndex >= input.count }
    var input: [Input]
    let _unboxer: Unboxer
    
    init(unboxer: Unboxer) throws {
        _unboxer = unboxer
        do {
            input = try unboxer.decodeArray()
        } catch {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: unboxer.codingPath, debugDescription: "Cannot get unkeyed decoding container -- found \(unboxer.input) value instead.", underlyingError: error))
        }
    }
    
    private func unboxer(_ data: Input) -> Unboxer {
        return Unboxer(input: data, path: codingPath + [PlainCodingKey(currentIndex)], other: _unboxer)
    }
    
    mutating func decodeNil() throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Input?.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        if unboxer(input[currentIndex]).decodeNil() {
            currentIndex += 1
            return true
        }
        return false
    }
    
    mutating func decode(_ type: Bool.Type) throws -> Bool {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Bool.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: String.Type) throws -> String {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(String.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Double.Type) throws -> Double {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Double.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Float.Type) throws -> Float {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int.Type) throws -> Int {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int8.Type) throws -> Int8 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int16.Type) throws -> Int16 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int32.Type) throws -> Int32 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: Int64.Type) throws -> Int64 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt.Type) throws -> UInt {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt8.Type) throws -> UInt8 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt16.Type) throws -> UInt16 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt32.Type) throws -> UInt32 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode(_ type: UInt64.Type) throws -> UInt64 {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Float.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func decode<T: Decodable>(_ type: T.Type) throws -> T {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(T.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let result = try unboxer(input[currentIndex]).decode(type)
        currentIndex += 1
        return result
    }
    
    mutating func nestedContainer<NestedKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> where NestedKey: CodingKey {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound([String: Input].self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        var path = codingPath
        path.append(PlainCodingKey(currentIndex))
        let container = try _KeyedDecodingContainer<NestedKey, Unboxer>(unboxer: unboxer(input[currentIndex]))
        currentIndex += 1
        return KeyedDecodingContainer(container)
    }
    
    mutating func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound([Input].self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        var path = codingPath
        path.append(PlainCodingKey(currentIndex))
        let container = try _UnkeyedDecodingContaier(unboxer: unboxer(input[currentIndex]))
        currentIndex += 1
        return container
    }
    
    mutating func superDecoder() throws -> Decoder {
        guard !isAtEnd else {
            throw DecodingError.valueNotFound(Input.self, DecodingError.Context(codingPath: codingPath + [PlainCodingKey(currentIndex)], debugDescription: "Unkeyed container is at end."))
        }
        let decoder = VDDecoder(unboxer: unboxer(input[currentIndex]))
        currentIndex += 1
        return decoder
    }
    
}
