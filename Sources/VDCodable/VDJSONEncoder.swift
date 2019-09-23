//
//  MyJSONEncoder.swift
//  Coders
//
//  Created by Данил Войдилов on 24/12/2018.
//  Copyright © 2018 daniil. All rights reserved.
//

import Foundation

open class VDJSONEncoder {
	
    open var dateEncodingStrategy: DateEncodingStrategy
    open var keyEncodingStrategy: KeyEncodingStrategy
    open var maximumFractionLength: Int32?
    open var customEncoding: (([CodingKey], JSON) throws -> JSON)?
    
    public init(dateEncodingStrategy: DateEncodingStrategy = .deferredFromDate, keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys, maximumFractionLength: Int32? = nil, customEncoding: (([CodingKey], JSON) throws -> JSON)? = nil) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.maximumFractionLength = maximumFractionLength
        self.customEncoding = customEncoding
    }
	
	open func encode<T: Encodable>(_ value: T) throws -> Data {
        let json = try encodeToJSON(value)
        var encoder = ProtobufJSONEncoder(maxFractionDigits: maximumFractionLength)
        json.putSelf(to: &encoder)
        return encoder.dataResult
	}
    
    open func encodeToJSON<T: Encodable>(_ value: T) throws -> JSON {
        if let result = value as? JSON {
            return try customEncoding?([], result) ?? result
        }
        var encoder = VDEncoder(boxer: Boxer(dateEncodingStrategy: dateEncodingStrategy, keyEncodingStrategy: keyEncodingStrategy, customEncoding: customEncoding))
        let json = try encoder.encode(value)
        return json
    }
	
}

fileprivate struct Boxer: EncodingBoxer {
    let codingPath: [CodingKey]
    let dateEncodingStrategy: VDJSONEncoder.DateEncodingStrategy
    let keyEncodingStrategy: VDJSONEncoder.KeyEncodingStrategy
    let customEncoding: (([CodingKey], JSON) throws -> JSON)?
    
    init(dateEncodingStrategy: VDJSONEncoder.DateEncodingStrategy, keyEncodingStrategy: VDJSONEncoder.KeyEncodingStrategy, customEncoding: (([CodingKey], JSON) throws -> JSON)?) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.codingPath = []
        self.customEncoding = customEncoding
    }
    
    init(path: [CodingKey], other boxer: Boxer) {
        codingPath = path
        dateEncodingStrategy = boxer.dateEncodingStrategy
        keyEncodingStrategy = boxer.keyEncodingStrategy
        customEncoding = boxer.customEncoding
    }
    
    private func encodeAny(_ json: JSON) throws -> JSON {
        return try customEncoding?(codingPath, json) ?? json
    }
    
    func encodeNil() throws -> JSON { return try encodeAny(.null) }
    func encode(_ array: [JSON]) throws -> JSON { return try encodeAny(.array(array)) }
    func encode(_ value: Bool) throws -> JSON { return try encodeAny(.bool(value)) }
    func encode(_ value: String) throws -> JSON { return try encodeAny(.string(value)) }
    func encode(_ value: Double) throws -> JSON { return try encodeAny(.double(value)) }
    func encode(_ value: Int) throws -> JSON { return try encodeAny(.int(value)) }
    
    func encode(_ dictionary: [String: JSON]) throws -> JSON {
        var result: [String: JSON]
        switch keyEncodingStrategy {
        case .useDefaultKeys:
            result = dictionary
        case .convertToSnakeCase:
            result = [:]
            dictionary.forEach {
                result[VDJSONEncoder.KeyEncodingStrategy.keyToSnakeCase($0.key)] = $0.value
            }
        case .custom(let block):
            result = [:]
            dictionary.forEach {
                result[block(codingPath)] = $0.value
            }
        }
        return try encodeAny(.object(result))
    }
    
    func encode(date: Date) throws -> JSON {
        switch dateEncodingStrategy {
        case .deferredFromDate:
            var encoder = VDEncoder(boxer: self)
            return try encoder.encode(date)
        case .secondsSince1970:
            return try encode(date.timeIntervalSince1970)
        case .millisecondsSince1970:
            return try encode(date.timeIntervalSince1970 * 1000)
        case .iso8601:
            return try encode(_iso8601Formatter.string(from: date))
        case .formatted(let formatter):
            return try encode(formatter.string(from: date))
        case .stringFormat(let format):
            let formatter = DateFormatter()
            formatter.dateFormat = format
            return try encode(formatter.string(from: date))
        case .custom(let block):
            return try encodeAny(block(VDEncoder(boxer: self)))
        }
    }
    
    func encode<T: Encodable>(value: T) throws -> JSON {
        if let date = value as? Date {
            return try encode(date: date)
        }
        var encoder = VDEncoder(boxer: self)
        return try encoder.encode(value)
    }
    
}
