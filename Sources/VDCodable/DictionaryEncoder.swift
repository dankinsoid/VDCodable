//
//  DictionaryEncoder.swift
//  VDCodable
//
//  Created by Daniil on 11.08.2019.
//

import Foundation
import SimpleCoders

open class DictionaryEncoder: CodableEncoder {
    
    public init() {}
    
    open func encode<T: Encodable>(_ value: T) throws -> Any {
        var encoder = VDEncoder(boxer: Boxer())
        return try encoder.encode(value)
    }
    
}

fileprivate struct Boxer: EncodingBoxer {
    let codingPath: [CodingKey]
    
    init() {
        codingPath = []
    }
    
    init(path: [CodingKey], other boxer: Boxer) {
        codingPath = path
    }
    
    func encodeNil() throws -> Any { return Optional<Any>.none as Any }
    func encode(_ dictionary: [String: Any]) throws -> Any { return dictionary }
    func encode(_ array: [Any]) throws -> Any { return array }
    func encode(_ value: Bool) throws -> Any { return value }
    func encode(_ value: String) throws -> Any { return value }
    func encode(_ value: Double) throws -> Any { return value }
    func encode(_ value: Int) throws -> Any { return value }
    func encode(_ value: Int8) throws -> Any { return value }
    func encode(_ value: Int16) throws -> Any { return value }
    func encode(_ value: Int32) throws -> Any { return value }
    func encode(_ value: Int64) throws -> Any { return value }
    func encode(_ value: UInt) throws -> Any { return value }
    func encode(_ value: UInt8) throws -> Any { return value }
    func encode(_ value: UInt16) throws -> Any { return value }
    func encode(_ value: UInt32) throws -> Any { return value }
    func encode(_ value: UInt64) throws -> Any { return value }
    
}
