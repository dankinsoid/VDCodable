//
//  CodableProtocols.swift
//  VDCodable
//
//  Created by Daniil on 11.08.2019.
//

import Foundation

public protocol CodableDecoder {
    associatedtype Input
    func decode<T: Decodable>(_ type: T.Type, from data: Input) throws -> T
}

public protocol CodableEncoder {
    associatedtype Output
    func encode<T: Encodable>(_ value: T) throws -> Output
}

public typealias CodableCoder = CodableDecoder & CodableEncoder

extension JSONDecoder: CodableDecoder {}
extension JSONEncoder: CodableEncoder {}
extension PropertyListDecoder: CodableDecoder {}
extension PropertyListEncoder: CodableEncoder {}
extension VDJSONDecoder: CodableDecoder {}
extension VDJSONEncoder: CodableEncoder {}
