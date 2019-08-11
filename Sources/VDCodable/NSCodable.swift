//
//  MyEncodingProtocols.swift
//  TestFooter
//
//  Created by Данил Войдилов on 20.04.2018.
//  Copyright © 2018 Daniil Voidilov. All rights reserved.

import Foundation

public protocol NSEncodable: Encodable where Self: NSObject {}
public protocol NSDecodable: Decodable {}

public typealias NSCodable = NSDecodable & NSEncodable

extension NSEncodable {
    
    public func encode(to encoder: Encoder) throws {
        try _NSEncodable(self).encode(to: encoder)
    }
    
}

extension NSDecodable where Self: NSObject {
    
    public init(from decoder: Decoder) throws {
        guard let value = try _NSDecodable(from: decoder).value else {
            throw NSDecodableError.cannotParse
        }
        if let v = value as? Self {
            self = v
            return
        }
        if let array = value as? [Any] {
            if let arr = NSArray(array: array) as? Self { self = arr } else
                if let arr = NSMutableArray(array: array) as? Self { self = arr } else
                    if let arr = NSSet(array: array) as? Self { self = arr } else
                        if let arr = NSOrderedSet(array: array) as? Self { self = arr } else
                        { throw NSDecodableError.cannotParse }
        }
        if let dict = value as? [String: Any] {
            self.init(from: dict)
        }
        throw NSDecodableError.cannotParse
    }
    
}

private protocol DictInit {}
extension NSObject: DictInit {}

extension DictInit where Self: NSObject {
    
    fileprivate init(from dict: [String: Any]) {
        self.init()
        let properties = self.getTypeOfProperties()
        dict.forEach {
            if let t = properties[$0.key] {
                if let classInst = NSClassFromString(t) as? NSObject.Type, let d = $0.value as? [String: Any] {
                    let v = classInst.init(from: d)
                    setValue(v, forKey: $0.key)
                } else if let classInst = NSClassFromString(t) as? NSSet.Type, let d = $0.value as? [Any] {
                    let v = classInst.init(array: d)
                    setValue(v, forKey: $0.key)
                } else if let classInst = NSClassFromString(t) as? NSOrderedSet.Type, let d = $0.value as? [Any] {
                    let v = classInst.init(array: d)
                    setValue(v, forKey: $0.key)
                } else if let classInst = NSClassFromString(t) as? NSArray.Type, let d = $0.value as? [Any] {
                    let v = classInst.init(array: d)
                    setValue(v, forKey: $0.key)
                } else {
                    setValue($0.value, forKey: $0.key)
                }
            } else {
                //setValue($0.value, forUndefinedKey: $0.key)
            }
        }
    }
    
}

fileprivate protocol _Array {
    func map<T>(_ transform: (Any) throws -> T) rethrows -> [T]
}
extension AnyCollection: _Array where Element == Any {}
extension Array: _Array where Element == Any {}
extension NSArray: _Array {}
extension NSSet: _Array {}
extension NSOrderedSet: _Array {}
extension Set: _Array {
    fileprivate func map<T>(_ transform: (Any) throws -> T) rethrows -> [T] {
        var result: [T] = []
        try self.forEach {
            try result.append(transform($0))
        }
        return result
    }
}

fileprivate struct _NSEncodable: Encodable {
    fileprivate var value: Any?
    fileprivate var ignore: [String] = []
    
    fileprivate init(_ value: Any, ignore: [String] = []) {
        self.value = value
        self.ignore = ignore
    }
    
    func encode(to encoder: Encoder) throws {
        var singleContainer = encoder.singleValueContainer()
        guard let value = value else  { try singleContainer.encodeNil(); return }
        if let v = value as? Bool     { try singleContainer.encode(v); return }
        if let v = value as? UInt8    { try singleContainer.encode(v); return }
        if let v = value as? Int8     { try singleContainer.encode(v); return }
        if let v = value as? UInt16   { try singleContainer.encode(v); return }
        if let v = value as? Int16    { try singleContainer.encode(v); return }
        if let v = value as? UInt32   { try singleContainer.encode(v); return }
        if let v = value as? Int32    { try singleContainer.encode(v); return }
        if let v = value as? UInt     { try singleContainer.encode(v); return }
        if let v = value as? Int      { try singleContainer.encode(v); return }
        if let v = value as? UInt64   { try singleContainer.encode(v); return }
        if let v = value as? Int64    { try singleContainer.encode(v); return }
        if let v = value as? Double   { try singleContainer.encode(v); return }
        if let v = value as? Decimal  { try singleContainer.encode(v); return }
        if let v = value as? String   { try singleContainer.encode(v); return }
        if let v = value as? Date     { try singleContainer.encode(v); return }
        if let v = value as? Data     { try singleContainer.encode(v); return }
        if let v = value as? _Array {
            var unkeyedContainer = encoder.unkeyedContainer()
            try unkeyedContainer.encode(contentsOf: v.map{ _NSEncodable($0) })
            return
        }
        if let v = value as? [String: Any] {
            var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
            try v.forEach {
                if !ignore.contains($0.key) {
                    if let enc = $0.value as? _NSEncodable {
                        try keyedContainer.encode(enc, forKey: CodingKeys($0.key))
                    } else {
                        try keyedContainer.encode(_NSEncodable($0.value), forKey: CodingKeys($0.key))
                    }
                }
            }
            return
        }
        try _NSEncodable(properties).encode(to: encoder)
    }
    
    private var properties: [String: Any] {
        guard let value = value as? NSObject else { return [:] }
        var results: [String: Any] = [:]
        var count: UInt32 = 0
        let ps = class_copyPropertyList(value.classForCoder, &count)
        for i in 0..<Int(count) {
            if let property = ps?[i] {
                let cname = property_getName(property)
                let name = String(cString: cname)
                results[name] = value.value(forKey: name)
            }
        }
        free(ps)
        return results
    }

}

fileprivate struct _NSDecodable: Decodable {
    var value: Any?
    
    fileprivate init(from decoder: Decoder) throws {
        if let singleContainer = try? decoder.singleValueContainer() {
            if singleContainer.decodeNil() { return }
            if let v = try? singleContainer.decode(Bool.self)    { value = v; return }
            if let v = try? singleContainer.decode(UInt8.self)   { value = v; return }
            if let v = try? singleContainer.decode(Int8.self)    { value = v; return }
            if let v = try? singleContainer.decode(UInt16.self)  { value = v; return }
            if let v = try? singleContainer.decode(Int16.self)   { value = v; return }
            if let v = try? singleContainer.decode(UInt32.self)  { value = v; return }
            if let v = try? singleContainer.decode(Int32.self)   { value = v; return }
            if let v = try? singleContainer.decode(UInt.self)    { value = v; return }
            if let v = try? singleContainer.decode(Int.self)     { value = v; return }
            if let v = try? singleContainer.decode(UInt64.self)  { value = v; return }
            if let v = try? singleContainer.decode(Int64.self)   { value = v; return }
            if let v = try? singleContainer.decode(Date.self)    { value = v; return }
            if let v = try? singleContainer.decode(Data.self)    { value = v; return }
            if let v = try? singleContainer.decode(Double.self)  { value = v; return }
            if let v = try? singleContainer.decode(Decimal.self) { value = v; return }
            if let v = try? singleContainer.decode(String.self)  { value = v; return }
        }
        if var unkeyedContainer = try? decoder.unkeyedContainer(),
            let count = unkeyedContainer.count {
            var array: [Any?] = []
            while unkeyedContainer.currentIndex < count {
                let el = try unkeyedContainer.decode(_NSDecodable.self)
                array.append(el.value)
            }
            value = array
            return
        }
        let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
        var dict: [String: Any] = [:]
        try keyedContainer.allKeys.forEach {
            let j = try keyedContainer.decode(_NSDecodable.self, forKey: $0)
            dict[$0.stringValue] = j.value
        }
        value = dict
    }
}

fileprivate struct CodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?
    
    init?(intValue: Int)       { return nil }
    init(_ key: String)        { self.stringValue = key }
    init?(stringValue: String) { self.stringValue = stringValue }
}

fileprivate enum NSDecodableError: String, LocalizedError {
    case cannotParse = "Parsing error"
}

extension NSObject {
    
    fileprivate func getTypeOfProperties() -> [String: String] {
        var t: Mirror = Mirror(reflecting: self)
        var dict: [String: String] = [:]
        for child in t.children {
            if let label = child.label {
                dict[label] = String(reflecting: type(of: child.value))
            }
        }
        while let parent = t.superclassMirror {
            for child in parent.children {
                if let label = child.label {
                    dict[label] = String(reflecting: type(of: child.value))
                }
            }
            t = parent
        }
        return dict
    }
    
    fileprivate var propertyNames: [String: Any] {
        var results: [String: Any] = [:]
        var count: UInt32 = 0
        let ps = class_copyPropertyList(self.classForCoder, &count)
        for i in 0..<Int(count) {
            if let property = ps?[i] {
                let cname = property_getName(property)
                let name = String(cString: cname)
                results[name] = value(forKey: name)
            }
        }
        free(ps)
        return results
    }
}

