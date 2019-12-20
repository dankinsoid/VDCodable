//
//  URLQueryEncoder.swift
//  VDCodable
//
//  Created by Daniil on 12.08.2019.
//

import Foundation
import UnwrapOperator

open class URLQueryEncoder: CodableEncoder {
    public typealias Output = [URLQueryItem]
    public let dateEncodingStrategy: DateEncodingStrategy
    public var arrayEncodingStrategy: ArrayEncodingStrategy
    public var nestedEncodingStrategy: DictionaryEncodingStrategy
    public var keyEncodingStrategy: KeyEncodingStrategy
    
    public init(keyEncodingStrategy: KeyEncodingStrategy = .useDefaultKeys, arrayEncodingStrategy: ArrayEncodingStrategy = .commaSeparator, nestedEncodingStrategy: DictionaryEncodingStrategy = .point) {
        self.dateEncodingStrategy = .unixTimeSeconds
        self.arrayEncodingStrategy = arrayEncodingStrategy
        self.nestedEncodingStrategy = nestedEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
    }
    
    open func encode<T: Encodable>(_ value: T, for baseURL: URL) throws -> URL {
        let items = try encode(value)
        if !items.isEmpty {
            var components = try URLComponents(url: baseURL, resolvingAgainstBaseURL: false)~!
            components.queryItems = (components.queryItems ?? []) + items
            return try components.url~!
        }
        return baseURL
    }
    
    open func encode<T: Encodable>(_ value: T) throws -> [URLQueryItem] {
        let boxer = Boxer(keyEncodingStrategy: keyEncodingStrategy, dateEncodingStrategy: dateEncodingStrategy, arrayEncodingStrategy: arrayEncodingStrategy, nestedEncodingStrategy: nestedEncodingStrategy)
        var encoder = VDEncoder(boxer: boxer)
        if nestedEncodingStrategy == .json {
            let json = try VDJSONEncoder().encodeToJSON(value)
            if let object = json.object {
                let dict = try object.mapValues {
                    try String(data: $0.data, encoding: .utf8)~!
                }
                let query = try encoder.encode(dict)
                return try boxer.getQuery(from: query)
            }
        }
        let query = try encoder.encode(value)
        return try boxer.getQuery(from: query)
    }
    
    open func encodePath<T: Encodable>(_ value: T) throws -> String {
        let items = try encodeParameters(value)
        return items.map { $0.key + QueryValue.setter + $0.value }.joined(separator: QueryValue.separator)
    }
    
    open func encodeParameters<T: Encodable>(_ value: T) throws -> [String: String] {
        let items = try encode(value)
        var result: [String: String] = [:]
        for item in items {
            result[item.name] = item.value ?? result[item.name]
        }
        return result
    }
    
    public enum ArrayEncodingStrategy {
        case commaSeparator                   //value1,value2
        case associative(indexed: Bool)       //key[0]=value1&key[1]=value2
        case customSeparator(String)
        case custom((_ path: [CodingKey], _ string: [String]) throws -> String)
    }
    
    public enum DictionaryEncodingStrategy {
        case squareBrackets, point, json
    }
    
    public enum DateEncodingStrategy {
        case unixTimeSeconds
        case unixTimeMilliseconds
        case stringFormat(String)
        case customFormat(DateFormatter)
        case custom(([CodingKey], String) throws -> Date)
        case iso8601
    }
    
}

fileprivate struct Boxer: EncodingBoxer {
    typealias Output = QueryValue
    let codingPath: [CodingKey]
    let dateEncodingStrategy: URLQueryEncoder.DateEncodingStrategy
    let arrayEncodingStrategy: URLQueryEncoder.ArrayEncodingStrategy
    let nestedEncodingStrategy: URLQueryEncoder.DictionaryEncodingStrategy
    let keyEncodingStrategy: KeyEncodingStrategy
    
    init(keyEncodingStrategy: KeyEncodingStrategy, dateEncodingStrategy: URLQueryEncoder.DateEncodingStrategy, arrayEncodingStrategy: URLQueryEncoder.ArrayEncodingStrategy, nestedEncodingStrategy: URLQueryEncoder.DictionaryEncodingStrategy) {
        self.codingPath = []
        self.keyEncodingStrategy = keyEncodingStrategy
        self.dateEncodingStrategy = dateEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
        self.nestedEncodingStrategy = nestedEncodingStrategy
    }
    
    init(path: [CodingKey], other boxer: Boxer) {
        codingPath = path
        keyEncodingStrategy = boxer.keyEncodingStrategy
        dateEncodingStrategy = boxer.dateEncodingStrategy
        arrayEncodingStrategy = boxer.arrayEncodingStrategy
        nestedEncodingStrategy = boxer.nestedEncodingStrategy
    }
    
    func encodeNil() throws -> QueryValue {
        return .single("")
    }
    
    func encode(_ dictionary: [String: QueryValue]) throws -> QueryValue {
        return try encode(dictionary, emptyKeys: false)
    }
    
    func getQuery(from output: QueryValue) throws -> [URLQueryItem] {
        guard let array = output.array else {
            throw QueryValue.Errors.unknown
        }
        return try array.map {
            let name: String
            switch nestedEncodingStrategy {
            case .squareBrackets:
                guard var key = $0.0.first else {
                    throw QueryValue.Errors.unknown
                }
                let chain = $0.0.dropFirst().joined(separator: "][")
                if $0.0.count > 1 {
                    key += "[" + chain + "]"
                }
                name = key
            case .point, .json:
                var result = ""
                let point = String(QueryValue.point)
                for key in $0.0 {
                    if key.isEmpty {
                        result += "[]"
                    } else {
                        if !result.isEmpty {
                            result += point
                        }
                        result += key
                    }
                }
                name = result
            }
            return URLQueryItem(name: name, value: $0.1)
        }
    }
    
    private func encode(_ dictionary: [String: QueryValue], emptyKeys: Bool) throws -> QueryValue {
        guard !dictionary.isEmpty else { return .keyed([]) }
        var result: [([String], String)] = []
        for (key, query) in dictionary {
            var key = key
            if emptyKeys, Int(key) != nil {
                key = ""
            } else {
                switch keyEncodingStrategy {
                case .useDefaultKeys:
                    break
                case .convertToSnakeCase(let separator):
                    key = KeyEncodingStrategy.keyToSnakeCase(key, separator: separator)
                case .custom(let block):
                    key = block(codingPath + [PlainCodingKey(key)])
                }
            }
            switch query {
            case .single(let value):
                result.append(([key], value))
            case .keyed(let array):
                result.append(contentsOf: array.map { ([key] + $0.0, $0.1) })
            }
        }
        return .keyed(result)
    }
    
    func encode(_ array: [QueryValue]) throws -> QueryValue {
        switch arrayEncodingStrategy {
        case .commaSeparator:
            return try .single(array.map({ try $0.string~! }).joined(separator: QueryValue.comma))
        case .associative(let indexed):
            return try encode(Dictionary(uniqueKeysWithValues: array.enumerated().map({ ("\($0.offset)", $0.element) })), emptyKeys: !indexed)
        case .customSeparator(let separator):
            return try .single(array.map({ try $0.string~! }).joined(separator: separator))
        case .custom(let block):
            return try .single(block(codingPath, array.map { try $0.string~! }))
        }
    }

    func encode(_ value: Bool) throws -> QueryValue {
        return .single(value ? "true" : "false")
    }
    
    func encode(_ value: String) throws -> QueryValue {
        return .single(value)
    }
    
    func encode(_ value: Double) throws -> QueryValue {
        return .single("\(value)")
    }
    
    func encode(_ value: Int) throws -> QueryValue {
        return .single("\(value)")
    }
    
}
