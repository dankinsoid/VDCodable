//
//  TypeMirror.swift
//
//  Created by Данил Войдилов on 21/09/2018.
//  Copyright © 2018 Данил Войдилов. All rights reserved.
//

import Foundation

extension Mirror {
    
    public static func reflect<T: Decodable>(_ type: T.Type) -> [String: Any.Type] {
        let decoder = _Decoder()
        let _ = try? T(from: decoder)
        return decoder.container.value.mapValues { $0.value }
    }
    
    public static func reflect(type: Decodable.Type) -> [String: Any.Type] {
        let decoder = _Decoder()
        let _ = try? type.init(from: decoder)
        return decoder.container.value.mapValues { $0.value }
    }
    
    public init(reflectingType type: Decodable.Type) {
        let decoder = _Decoder()
        let _ = try? type.init(from: decoder)
        self.init(type: type, decoder: decoder)
    }
    
    public init<T: Decodable>(_ type: T.Type) {
        let decoder = _Decoder()
        let _ = try? T(from: decoder)
        self.init(type: type, decoder: decoder)
    }
    
    private init(type: Decodable.Type, decoder: _Decoder) {
        let childs = decoder.container.value.map({ Mirror.Child(label: $0.key, value: $0.value.value) })
        self.init(type, children: childs)
    }
    
}

fileprivate class _Decoder: Decoder {
    
    let codingPath: [CodingKey] = []
    var userInfo: [CodingUserInfoKey : Any] = [:]
    var container: ClassWrapper<[String: ClassWrapper<Any.Type>]> = ClassWrapper([:])
    var key: String?
    
    func container<Key>(keyedBy type: Key.Type) throws -> KeyedDecodingContainer<Key> where Key: CodingKey {
        let cont = _KeyedDecodingContainer<Key>()
        container = cont.container
        return KeyedDecodingContainer(cont)
    }
    
    func unkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _UnkeyedDecodingContainer()
    }
    
    func singleValueContainer() throws -> SingleValueDecodingContainer {
        return _SingleValueDecodingContainer()
    }
}

fileprivate class ClassWrapper<T> {
    var value: T
    init(_ v: T) { value = v }
}

fileprivate struct _KeyedDecodingContainer<Key: CodingKey>: KeyedDecodingContainerProtocol {
    
    var allKeys: [Key] = []
    let codingPath: [CodingKey] = []
    var container: ClassWrapper<[String: ClassWrapper<Any.Type>]> = ClassWrapper([:])
    
    init() {}
    
    func contains(_ key: Key) -> Bool { return true }
    func decodeAny<T>(_ type: T.Type, for key: Key) { container.value[key.stringValue] = ClassWrapper(T.self) }
    func decodeNil(forKey key: Key) throws -> Bool                     { decodeAny(Any?.self, for: key); return true }
    func decode(_ type: Bool.Type, forKey key: Key) throws -> Bool     { decodeAny(type, for: key); return false }
    func decode(_ type: String.Type, forKey key: Key) throws -> String { decodeAny(type, for: key); return "" }
    func decode(_ type: Double.Type, forKey key: Key) throws -> Double { decodeAny(type, for: key); return 0 }
    func decode(_ type: Float.Type, forKey key: Key) throws -> Float   { decodeAny(type, for: key); return 0 }
    func decode(_ type: Int.Type, forKey key: Key) throws -> Int       { decodeAny(type, for: key); return 0 }
    func decode(_ type: Int8.Type, forKey key: Key) throws -> Int8     { decodeAny(type, for: key); return 0 }
    func decode(_ type: Int16.Type, forKey key: Key) throws -> Int16   { decodeAny(type, for: key); return 0 }
    func decode(_ type: Int32.Type, forKey key: Key) throws -> Int32   { decodeAny(type, for: key); return 0 }
    func decode(_ type: Int64.Type, forKey key: Key) throws -> Int64   { decodeAny(type, for: key); return 0 }
    func decode(_ type: UInt.Type, forKey key: Key) throws -> UInt     { decodeAny(type, for: key); return 0 }
    func decode(_ type: UInt8.Type, forKey key: Key) throws -> UInt8   { decodeAny(type, for: key); return 0 }
    func decode(_ type: UInt16.Type, forKey key: Key) throws -> UInt16 { decodeAny(type, for: key); return 0 }
    func decode(_ type: UInt32.Type, forKey key: Key) throws -> UInt32 { decodeAny(type, for: key); return 0 }
    func decode(_ type: UInt64.Type, forKey key: Key) throws -> UInt64 { decodeAny(type, for: key); return 0 }
    func decode<T: Decodable>(_ type: T.Type, forKey key: Key) throws -> T {
        decodeAny(type, for: key)
        return decodeType()
    }
    
    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type, forKey key: Key) throws -> KeyedDecodingContainer<NestedKey> {
        if container.value[key.stringValue] == nil { decodeAny([String: Any].self, for: key) }
        return KeyedDecodingContainer(_KeyedDecodingContainer<NestedKey>())
    }
    
    func nestedUnkeyedContainer(forKey key: Key) throws -> UnkeyedDecodingContainer {
        if container.value[key.stringValue] == nil { decodeAny([Any].self, for: key) }
        var cont = _UnkeyedDecodingContainer()
        cont.container = container.value[key.stringValue]!
        return cont
    }
    
    func superDecoder() throws -> Decoder {
        return _Decoder()
    }
    func superDecoder(forKey key: Key) throws -> Decoder {
        return _Decoder()
    }
    
}

fileprivate struct _UnkeyedDecodingContainer: UnkeyedDecodingContainer {
    
    var count: Int? { return 0 }
    let isAtEnd: Bool = true
    let currentIndex: Int = 0
    
    let codingPath: [CodingKey] = []
    var container: ClassWrapper<Any.Type> = ClassWrapper([Any].self)
    
    func decodeAny<T>(_ type: T.Type) {
        container.value = [T].self
    }
    func decodeNil() throws -> Bool { decodeAny(Optional<Any>.self); return true }
    func decode(_ type: Bool.Type) throws -> Bool     { decodeAny(type); return false }
    func decode(_ type: String.Type) throws -> String { decodeAny(type); return "" }
    func decode(_ type: Double.Type) throws -> Double { decodeAny(type); return 0 }
    func decode(_ type: Float.Type) throws -> Float   { decodeAny(type); return 0 }
    func decode(_ type: Int.Type) throws -> Int       { decodeAny(type); return 0 }
    func decode(_ type: Int8.Type) throws -> Int8     { decodeAny(type); return 0 }
    func decode(_ type: Int16.Type) throws -> Int16   { decodeAny(type); return 0 }
    func decode(_ type: Int32.Type) throws -> Int32   { decodeAny(type); return 0 }
    func decode(_ type: Int64.Type) throws -> Int64   { decodeAny(type); return 0 }
    func decode(_ type: UInt.Type) throws -> UInt     { decodeAny(type); return 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8   { decodeAny(type); return 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { decodeAny(type); return 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { decodeAny(type); return 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { decodeAny(type); return 0 }
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        decodeAny(type)
        return decodeType()
    }
    

    func nestedContainer<NestedKey: CodingKey>(keyedBy type: NestedKey.Type) throws -> KeyedDecodingContainer<NestedKey> {
        if container.value == [Any].self { decodeAny([String: Any].self) }
        return KeyedDecodingContainer(_KeyedDecodingContainer<NestedKey>())
    }
    
    func nestedUnkeyedContainer() throws -> UnkeyedDecodingContainer {
        return _UnkeyedDecodingContainer()
    }
    
    func superDecoder() throws -> Decoder {
        return _Decoder()
    }
    
}

fileprivate struct _SingleValueDecodingContainer: SingleValueDecodingContainer {
    
    let codingPath: [CodingKey] = []
    var container: ClassWrapper<Any.Type> = ClassWrapper(Any.self)
    
    func decodeAny<T>(_ type: T.Type) {
        container.value = T.self
    }
    func decodeNil() -> Bool                          { decodeAny(Optional<Any>.self); return true }
    func decode(_ type: Bool.Type) throws -> Bool     { decodeAny(type); return false }
    func decode(_ type: String.Type) throws -> String { decodeAny(type); return "" }
    func decode(_ type: Double.Type) throws -> Double { decodeAny(type); return 0 }
    func decode(_ type: Float.Type) throws -> Float   { decodeAny(type); return 0 }
    func decode(_ type: Int.Type) throws -> Int       { decodeAny(type); return 0 }
    func decode(_ type: Int8.Type) throws -> Int8     { decodeAny(type); return 0 }
    func decode(_ type: Int16.Type) throws -> Int16   { decodeAny(type); return 0 }
    func decode(_ type: Int32.Type) throws -> Int32   { decodeAny(type); return 0 }
    func decode(_ type: Int64.Type) throws -> Int64   { decodeAny(type); return 0 }
    func decode(_ type: UInt.Type) throws -> UInt     { decodeAny(type); return 0 }
    func decode(_ type: UInt8.Type) throws -> UInt8   { decodeAny(type); return 0 }
    func decode(_ type: UInt16.Type) throws -> UInt16 { decodeAny(type); return 0 }
    func decode(_ type: UInt32.Type) throws -> UInt32 { decodeAny(type); return 0 }
    func decode(_ type: UInt64.Type) throws -> UInt64 { decodeAny(type); return 0 }
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        decodeAny(type)
        return decodeType()
    }
    
}

fileprivate func decodeType<T: Decodable>() -> T {
    do {
        return try T(from: _Decoder())
    } catch {
        return Data(capacity: MemoryLayout<T>.stride).withUnsafeBytes { $0.load(as: T.self) }
    }
}

fileprivate struct _CodingKey: CodingKey {
    
    static let superKey = _CodingKey("super")
    var stringValue: String
    var intValue: Int?
    
    init(_ stringValue: String) { self.stringValue = stringValue }
    init?(stringValue: String) { self.stringValue = stringValue }
    init?(intValue: Int) { return nil }
    
}
