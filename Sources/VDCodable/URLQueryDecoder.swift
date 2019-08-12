//
//  URLQueryDecoder.swift
//  UnwrapOperator
//
//  Created by Daniil on 11.08.2019.
//

import Foundation
import UnwrapOperator

open class URLQueryDecoder: CodableDecoder {
    public typealias Input = URL
    public var dateEncodingStrategy: DateCodingStrategy
    public var arrayEncodingStrategy: ArrayDecodingStrategy
    
    public init(dateEncodingStrategy: DateCodingStrategy = .unixTimeSeconds, arrayEncodingStrategy: ArrayDecodingStrategy = .commaSeparator) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: URL) throws -> T {
        let unboxer = try Unboxer(data, dateEncodingStrategy: dateEncodingStrategy, arrayEncodingStrategy: arrayEncodingStrategy)
        return try T(from: VDDecoder(unboxer: unboxer))
    }

    public enum ArrayDecodingStrategy {
        case commaSeparator             //value1,value2
        case associative                //key[0]=value1&key[1]=value2
        case customSeparator(String)
        case custom((_ path: [CodingKey], _ string: String) throws -> [String])
    }
    
    public enum DictionaryDecodingStrategy {
        case associative
    }
    
    public enum DateCodingStrategy {
        case unixTimeSeconds
        case unixTimeMilliseconds
        case stringFormat(String)
        case customFormat(DateFormatter)
        case custom(([CodingKey], Date) throws -> String)
        case iso8601
    }
    
}

fileprivate struct Unboxer: DecodingUnboxer {
    let input: QueryValue
    let codingPath: [CodingKey]
    let dateEncodingStrategy: URLQueryDecoder.DateCodingStrategy
    let arrayEncodingStrategy: URLQueryDecoder.ArrayDecodingStrategy
    
    func decodeNil() -> Bool {
        return false
    }
    
    init(_ input: String, dateEncodingStrategy: URLQueryDecoder.DateCodingStrategy, arrayEncodingStrategy: URLQueryDecoder.ArrayDecodingStrategy) throws {
        self.input = try QueryValue(input)
        self.codingPath = []
        self.dateEncodingStrategy = dateEncodingStrategy
        self.arrayEncodingStrategy = arrayEncodingStrategy
    }
    
    init(_ url: URL, dateEncodingStrategy: URLQueryDecoder.DateCodingStrategy, arrayEncodingStrategy: URLQueryDecoder.ArrayDecodingStrategy) throws {
        let string: String
        if url.absoluteString.contains(QueryValue.start) {
            string = try url.absoluteString.components(separatedBy: QueryValue.start).last~!
        } else {
            string = ""
        }
        self = try Unboxer(string, dateEncodingStrategy: dateEncodingStrategy, arrayEncodingStrategy: arrayEncodingStrategy)
    }
    
    init(input: QueryValue, path: [CodingKey], other unboxer: Unboxer) {
        self.input = input
        self.codingPath = path
        dateEncodingStrategy = unboxer.dateEncodingStrategy
        arrayEncodingStrategy = unboxer.arrayEncodingStrategy
    }
    
    private func getString() throws -> String {
        guard case .single(let result) = input else {
            throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Cannot get single value for \(input.array ?? [])"))
        }
        return result
    }
    
    func decodeArray() throws -> [QueryValue] {
        switch arrayEncodingStrategy {
        case .commaSeparator:
            let string = try getString()
            return string.components(separatedBy: QueryValue.comma).map({ .single($0) })
        case .associative:
            let dict = try decodeDictionary()
            let values = try dict.sorted { try Int($0.key)~! < Int($1.key)~! }.map({ $0.value })
            return values
        case .customSeparator(let separator):
            let string = try getString()
            return string.components(separatedBy: separator).map({ .single($0) })
        case .custom(let block):
            let string = try getString()
            return try block(codingPath, string).map({ .single($0) })
        }
    }
    
    func decodeDictionary() throws -> [String: QueryValue] {
        let array = try input.array~!
        guard !array.isEmpty else { return [:] }
        var result: [String: QueryValue] = [:]
        var i = 0
        for (keys, value) in array {
            guard var first = keys.first else { throw QueryValue.Errors.unknown }
            if first.isEmpty {
                first = "\(i)"
                i += 1
            }
            let new = (Array(keys.dropFirst()), value)
            if let query = result[first] {
                guard !new.0.isEmpty, let arr = query.array else { throw QueryValue.Errors.unknown }
                result[first] = .keyed(arr + [new])
            } else if new.0.isEmpty {
                result[first] = .single(value)
            } else {
                result[first] = .keyed([new])
            }
        }
        return result
    }
    
    func decode(_ type: Bool.Type) throws -> Bool {
        let string = try getString()
        switch string.lowercased() {
        case "true", "yes", "1":
            return true
        case "false", "no", "0":
            return false
        default:
            throw error(type, string)
        }
    }
    
    func decode(_ type: String.Type) throws -> String {
        return try getString()
    }
    
    func decode(_ type: Double.Type) throws -> Double {
        let string = try getString()
        if let double = Double(string) {
            return double
        }
        throw error(type, string)
    }
    
    func decode(_ type: Int.Type) throws -> Int {
        let string = try getString()
        if let double = Int(string) {
            return double
        }
        throw error(type, string)
    }
    
    @inline(__always)
    private func error<T>(_ type: T.Type, _ string: String) -> DecodingError {
        return DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Expected \(type), but found \(string)"))
    }
    
    func decode<T: Decodable>(_ type: T.Type) throws -> T {
        let decoder = VDDecoder(unboxer: self)
        return try T(from: decoder)
    }
    
}

enum QueryValue {
    case single(String), keyed([([String], String)])
    internal static let start = "?"
    internal static let comma = ","
    internal static let separator = "&"
    internal static let setter = "="
    internal static let openKey: Character = "["
    internal static let closeKey: Character = "]"
    internal static let point: Character = "."
    
    init(_ string: String) throws {
        if string.isEmpty {
            self = .keyed([])
            return
        }
        if !string.contains(QueryValue.setter) {
            self = .single(string)
            return
        }
        let components = string.components(separatedBy: QueryValue.separator)
        let it = try components.map { str -> ([String], String) in
            let array = str.components(separatedBy: QueryValue.setter)
            guard array.count == 2 else {
                throw Errors.noEqualSign(str)
            }
            return (QueryValue.separateKey(array[0]), array[1])
        }
        self = .keyed(it)
    }
    
    static func separateKey(_ key: String) -> [String] {
        var result: [String] = []
        var str = ""
        for char in key {
            switch char {
            case QueryValue.openKey:
                if result.isEmpty, !str.isEmpty {
                    result.append(str)
                }
            case QueryValue.closeKey:
                result.append(str)
                str = ""
            case QueryValue.point:
                result.append(str)
                str = ""
            default:
                str.append(char)
            }
        }
        if result.isEmpty, !str.isEmpty {
            result.append(str)
        }
        return result
    }
    
    var array: [([String], String)]? {
        if case .keyed(let result) = self {
            return result
        }
        return nil
    }
    
    var string: String? {
        if case .single(let result) = self {
            return result
        }
        return nil
    }
    
    enum Errors: Error {
        case noEqualSign(String), unknown
    }
    
}
