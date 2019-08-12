//
//  URLQueryEncoder.swift
//  VDCodable
//
//  Created by Daniil on 12.08.2019.
//

import Foundation
import UnwrapOperator

open class URLQueryEncoder: CodableEncoder {
    public typealias Output = URL
    let dateEncodingStrategy: DateEncodingStrategy
    let arrayEncodingStrategy: ArrayEncodingStrategy
    let baseURL: URL
    
    public init(baseURL: URL, dateEncodingStrategy: DateEncodingStrategy = .unixTimeSeconds, arrayEncodingStrategy: ArrayEncodingStrategy = .commaSeparator) {
        self.baseURL = baseURL
        self.dateEncodingStrategy = dateEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }
    
    open func encode<T: Encodable>(_ value: T) throws -> URL {
        var encoder = VDEncoder(boxer: Boxer(dateEncodingStrategy: dateEncodingStrategy, arrayEncodingStrategy: arrayEncodingStrategy))
        let query = try encoder.encode(value)
        guard let array = query.array else {
            throw QueryValue.Errors.unknown
        }
        let strings: [URLQueryItem] = try array.map {
            guard var key = $0.0.first else {
                throw QueryValue.Errors.unknown
            }
            let chain = $0.0.dropFirst().joined(separator: "][")
            if $0.0.count > 1 {
                key += "[" + chain + "]"
            }
            return URLQueryItem(name: key, value: $0.1)
        }
        if !strings.isEmpty {
            var components = try URLComponents(url: baseURL, resolvingAgainstBaseURL: false)~!
            components.queryItems = strings
            return try components.url~!
//            return baseURL.appendingPathComponent(QueryValue.start + strings.joined(separator: QueryValue.separator))
        }
        return baseURL
    }
    
    public enum ArrayEncodingStrategy {
        case commaSeparator                   //value1,value2
        case associative(indexed: Bool)       //key[0]=value1&key[1]=value2
        case customSeparator(String)
        case custom((_ path: [CodingKey], _ string: [String]) throws -> String)
    }
    
    public enum DictionaryEncodingStrategy {
        case associative
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
    
    init(dateEncodingStrategy: URLQueryEncoder.DateEncodingStrategy, arrayEncodingStrategy: URLQueryEncoder.ArrayEncodingStrategy) {
        self.codingPath = []
        self.dateEncodingStrategy = dateEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }
    
    init(path: [CodingKey], other boxer: Boxer) {
        codingPath = path
        dateEncodingStrategy = boxer.dateEncodingStrategy
        arrayEncodingStrategy = boxer.arrayEncodingStrategy
    }
    
    func encodeNil() throws -> QueryValue {
        return .single("")
    }
    
    func encode(_ dictionary: [String: QueryValue]) throws -> QueryValue {
        return try encode(dictionary, emptyKeys: false)
    }
    
    private func encode(_ dictionary: [String: QueryValue], emptyKeys: Bool) throws -> QueryValue {
        guard !dictionary.isEmpty else { return .keyed([]) }
        var result: [([String], String)] = []
        for (key, query) in dictionary {
            var key = key
            if emptyKeys, Int(key) != nil {
                key = ""
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
