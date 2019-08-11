//
//  CodableCoder.swift
//  VDCodable
//
//  Created by Daniil on 11.08.2019.
//

import Foundation

open class VDCoder<Input: Encodable, Output: Decodable>: CodableEncoder, CodableDecoder {
    
    static func decode(_ value: Input) throws -> Output {
        if let result = value as? Output {
            return result
        }
//        if let json = value as? JSON {
//            return try VDJSONDecoder().decode(Output.self, from: json)
//        }
//        if Output.self == JSON.self {
//            return try VDJSONEncoder().encodeJSON(value) as! Output
//        }
        return try DictionaryDecoder().decode(Output.self, from: DictionaryEncoder().encode(value))
    }
    
    public func encode<T: Encodable>(_ value: T) throws -> Output {
        return try VDCoder<T, Output>.decode(value)
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Input) throws -> T {
        return try VDCoder<Input, T>.decode(data)
    }
    
}
