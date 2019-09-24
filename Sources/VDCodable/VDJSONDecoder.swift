//
//  JSONScanDecoder.swift
//  Coders
//
//  Created by Данил Войдилов on 23/12/2018.
//  Copyright © 2018 daniil. All rights reserved.
//

import Foundation
import UnwrapOperator

open class VDJSONDecoder {
	
	open var dateDecodingStrategy: DateDecodingStrategy
	open var keyDecodingStrategy: KeyDecodingStrategy
	open var tryDecodeFromQuotedString: Bool
    open var customDecoding: (([CodingKey], JSON) -> JSON)?
	public let userInfo: [CodingUserInfoKey : Any] = [:]
	
	public init(dateDecodingStrategy: DateDecodingStrategy = .deferredToDate,
				keyDecodingStrategy: KeyDecodingStrategy = .useDefaultKeys,
				tryDecodeFromQuotedString: Bool = true, customDecoding: (([CodingKey], JSON) -> JSON)? = nil) {
		self.dateDecodingStrategy = dateDecodingStrategy
		self.keyDecodingStrategy = keyDecodingStrategy
		self.tryDecodeFromQuotedString = tryDecodeFromQuotedString
        self.customDecoding = customDecoding
	}
	
    open func decode<D: Decodable>(_ type: D.Type, json: JSON) throws -> D {
        if type == JSON.self, let result = json as? D { return (customDecoding?([], json) as? D) ?? result }
        let decoder = VDDecoder(unboxer: Unboxer(json: json, dateDecodingStrategy: dateDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy, tryDecodeFromQuotedString: tryDecodeFromQuotedString, customDecoding: customDecoding))
        return try D.init(from: decoder)
    }
    
	open func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
		let json = try JSON(from: data)
        return try decode(type, json: json)
	}
	
}

fileprivate struct Unboxer: DecodingUnboxer {
    let userInfo: [CodingUserInfoKey: Any] = [:]
    let codingPath: [CodingKey]
	let dateDecodingStrategy: VDJSONDecoder.DateDecodingStrategy
	let keyDecodingStrategy: VDJSONDecoder.KeyDecodingStrategy
    let customDecoding: (([CodingKey], JSON) -> JSON)?
	let tryDecodeFromQuotedString: Bool
    let input: JSON

    init(input: JSON, path: [CodingKey], other unboxer: Unboxer) {
        self.input = unboxer.customDecoding?(path, input) ?? input
        codingPath = path
        dateDecodingStrategy = unboxer.dateDecodingStrategy
        keyDecodingStrategy = unboxer.keyDecodingStrategy
        tryDecodeFromQuotedString = unboxer.tryDecodeFromQuotedString
        customDecoding = unboxer.customDecoding
    }
    
	init(json: JSON, dateDecodingStrategy: VDJSONDecoder.DateDecodingStrategy, keyDecodingStrategy: VDJSONDecoder.KeyDecodingStrategy, tryDecodeFromQuotedString: Bool, customDecoding: (([CodingKey], JSON) -> JSON)?) {
		self.dateDecodingStrategy = dateDecodingStrategy
		self.keyDecodingStrategy = keyDecodingStrategy
		self.tryDecodeFromQuotedString = tryDecodeFromQuotedString
        self.customDecoding = customDecoding
        self.codingPath = []
        self.input = customDecoding?([], json) ?? json
	}
    
    func decodeArray() throws -> [JSON] {
        return try decode([JSON].self) { try JSON(from: &$0)~!.array~! }
    }
    
    func decodeDictionary() throws -> [String: JSON] {
        var dictionary = try decode([String: JSON].self) { try JSON(from: &$0)~!.object~! }
        if case .useDefaultKeys = keyDecodingStrategy {
            return dictionary
        }
        for (key, value) in dictionary {
            dictionary[key] = nil
            switch keyDecodingStrategy {
            case .useDefaultKeys:
                dictionary[key] = value
            case .convertFromSnakeCase:
                dictionary[VDJSONDecoder.KeyDecodingStrategy.keyFromSnakeCase(key)] = value
            case .custom(let fun):
                dictionary[fun(codingPath)] = value
            }
        }
        return dictionary
    }
	
	@inline(__always)
	func decodeNil() -> Bool {
		if case .null = input { return true }
		return false
	}
	
	@inline(__always)
	func decode(_ type: Bool.Type) throws -> Bool {
        return try decode(type) { try $0.nextBool() }
	}
	
	@inline(__always)
	func decode(_ type: String.Type) throws -> String {
		if case .string(let string) = input {
			return string
		}
		throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(type) but found \(input.kind) instead."))
	}
	
    @inline(__always)
    private func decode<T>(_ type: T.Type, block: @escaping (inout JSONScanner) throws -> T) throws -> T {
        if let result = input.value as? T {
            return result
        }
        if tryDecodeFromQuotedString, case .string(let string) = input {
            let data = Data(string.utf8)
            return try  data.withUnsafeBytes { rawPointer -> T in
                let source = rawPointer.bindMemory(to: UInt8.self)
                var scanner = JSONScanner(source: source, messageDepthLimit: .max)
                do {
                    return try block(&scanner)
                } catch  {
                    throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: error.localizedDescription, underlyingError: error))
                }
            }
        }
        throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(type) but found \(input.kind) instead."))
    }
    
	@inline(__always)
	func decode(_ type: Double.Type) throws -> Double {
        return try decode(type) { try $0.nextDouble() }
	}
    
    func decode(_ type: Int.Type) throws -> Int {
        return try decode(type) { try $0.nextSignedInteger() }
    }
    
    func decodeDecimal() throws -> Decimal {
        return try decode(Decimal.self) { try Decimal($0.nextDouble()) }
    }
	
	@inline(__always)
	func decodeDate(from decoder: VDDecoder<Unboxer>) throws -> Date {
		switch dateDecodingStrategy {
		case .deferredToDate: return try Date(from: decoder)
		case .secondsSince1970:
			let seconds = try Double(from: decoder)
			return Date(timeIntervalSince1970: seconds)
		case .millisecondsSince1970:
			let milliseconds = try Double(from: decoder)
			return Date(timeIntervalSince1970: milliseconds / 1000)
		case .iso8601:
			let string = try String(from: decoder)
            if let result = _iso8601Formatter.date(from: string) {
                return result
            } else {
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected date string to be ISO8601-formatted."))
            }
		case .formatted(let formatter):
			let string = try String(from: decoder)
			if let result = formatter.date(from: string) {
				return result
			} else {
				throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Date string does not match format expected by formatter."))
			}
		case .stringFormats(let formats):
			let string = try String(from: decoder)
			for format in formats {
				_dateFormatter.dateFormat = format
				if let result = _dateFormatter.date(from: string) {
					return result
				}
			}
			throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Date string does not match '\(formats)'."))
		case .custom(let transform):
			return try transform(decoder)
		}
	}
    
	@inline(__always)
	func decode<T: Decodable>(_ type: T.Type) throws -> T {
		if type == JSON.self, let result = input as? T { return result }
        let decoder = VDDecoder(unboxer: self)
		if type == Date.self || type as? NSDate.Type != nil {
			let result = try decodeDate(from: decoder)
            return try cast(result, as: type)
		}
        if type == Decimal.self || type as? NSDecimalNumber.Type != nil {
            let result = try decodeDecimal()
            return try cast(result, as: type)
        }
		return try T.init(from: decoder)
	}
    
    private func cast<A, T>(_ value: A, as type: T.Type) throws -> T {
        if let result = value as? T {
            return result
        } else {
            throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(type) but found \(value) instead."))
        }
    }
	
}

fileprivate let _dateFormatter = DateFormatter()
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
internal let _iso8601Formatter: ISO8601DateFormatter = {
	let formatter = ISO8601DateFormatter()
	formatter.formatOptions = .withInternetDateTime
	return formatter
}()
