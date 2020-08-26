//
//  DictionaryDecoder.swift
//  VDCodable
//
//  Created by Daniil on 11.08.2019.
//

import Foundation

open class DictionaryDecoder: CodableDecoder {
    
    public init() {}
    
    open func decode<T: Decodable>(_ type: T.Type, from data: Any) throws -> T  {
        try T(from: decoder(for: data))
    }
	
		func decoder(for data: Any) -> Decoder {
				VDDecoder(unboxer: Unboxer(input: data))
		}
    
}

fileprivate struct Unboxer: DecodingUnboxer {
    let input: Any
    let codingPath: [CodingKey]
    
    init(input: Any) {
        self.input = input
        codingPath = []
    }
    
    init(input: Any, path: [CodingKey], other unboxer: Unboxer) {
        self.input = input
        codingPath = path
    }
    
    private func decodeAny<T>() throws -> T {
        guard let result = input as? T else {
            throw DecodingError.typeMismatch(T.self, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(T.self), but found \(input)"))
        }
        return result
    }
    
    func decodeNil() -> Bool { return input as Optional<Any> == nil }
    func decodeArray() throws -> [Any] { return try decodeAny() }
    func decodeDictionary() throws -> [String: Any] { return try decodeAny() }
    func decode(_ type: Bool.Type) throws -> Bool { return try decodeAny() }
    func decode(_ type: String.Type) throws -> String { return try decodeAny() }
    func decode(_ type: Double.Type) throws -> Double { return try decodeAny() }
    func decode(_ type: Int.Type) throws -> Int { return try decodeAny() }
    func decode(_ type: Int8.Type) throws -> Int8 { return try decodeAny() }
    func decode(_ type: Int16.Type) throws -> Int16 { return try decodeAny() }
    func decode(_ type: Int32.Type) throws -> Int32 { return try decodeAny() }
    func decode(_ type: Int64.Type) throws -> Int64 { return try decodeAny() }
    func decode(_ type: UInt.Type) throws -> UInt { return try decodeAny() }
    func decode(_ type: UInt8.Type) throws -> UInt8 { return try decodeAny() }
    func decode(_ type: UInt16.Type) throws -> UInt16 { return try decodeAny() }
    func decode(_ type: UInt32.Type) throws -> UInt32 { return try decodeAny() }
    func decode(_ type: UInt64.Type) throws -> UInt64 { return try decodeAny() }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        if let result = input as? T {
            return result
        }
        let decoder = VDDecoder(unboxer: self)
        return try T(from: decoder)
    }
    
}
