//
//  JSON.swift
//
//  Created by Данил Войдилов on 12/12/2018.
//

import Foundation

@dynamicMemberLookup
public enum JSON: Codable {
	case bool(Bool)
	case int(Int)
	case double(Double)
	case string(String)
	case array([JSON])
	case object([String: JSON])
	case null
	
	public subscript(dynamicMember member: String) -> JSON {
		return self[member] ?? .null
	}
	
	public var data: Data {
		var encoder = ProtobufJSONEncoder()
		putSelf(to: &encoder)
		return encoder.dataResult
	}
	
	public var utf8String: String {
		return String(data: data, encoding: .utf8) ?? ""
	}
	
	public init?(from value: Any) {
		if let bl  = value as? Bool   { self = .bool(bl);    return }
		if let int = value as? Int    { self = .int(int);    return }
		if let db  = value as? Double { self = .double(db);  return }
		if let str = value as? String { self = .string(str); return }
		if let arr = value as? [Any] {
			var arrV: [JSON] = []
			for a in arr {
				guard let json = JSON(from: a) else { return nil }
				arrV.append(json)
			}
			self = .array(arrV)
			return
		}
		if let dict = value as? [String: Any] {
			var dictV: [String: JSON] = [:]
			for (key, v) in dict {
				guard let json = JSON(from: v) else { return nil }
				dictV[key] = json
			}
			self = .object(dictV)
			return
		}
		return nil
	}
	
	public init(from jsonUTF8Data: Data) throws {
        self = try jsonUTF8Data.withUnsafeBytes { rawPointer -> JSON in
            let source = rawPointer.bindMemory(to: UInt8.self)
			var scanner = JSONScanner(source: source, messageDepthLimit: .max)
			return try JSON(from: &scanner)
		}
	}
	
	internal init(from scanner: inout JSONScanner) throws {
		let c = try scanner.peekOneCharacter()
		switch c {
		case "[":
			var array: [JSON] = []
			try scanner.skipRequiredArrayStart()
			if !scanner.skipOptionalArrayEnd() {
				try array.append(JSON(from: &scanner))
				while !scanner.skipOptionalArrayEnd() {
					try scanner.skipRequiredComma()
					try array.append(JSON(from: &scanner))
				}
			}
			self = .array(array)
		case "{":
			var object: [String: JSON] = [:]
			try scanner.skipRequiredObjectStart()
			if !scanner.skipOptionalObjectEnd() {
				let key = try scanner.nextKey()
				try scanner.skipRequiredColon()
				let value = try JSON(from: &scanner)
				object[key] = value
				while !scanner.skipOptionalObjectEnd() {
					try scanner.skipRequiredComma()
					let key = try scanner.nextKey()
					try scanner.skipRequiredColon()
					let value = try JSON(from: &scanner)
					object[key] = value
				}
			}
			self = .object(object)
		case "t", "f":
			self = try .bool(scanner.nextBool())
		case "\"":
			self = try .string(scanner.nextQuotedString())
		case "n":
			if scanner.skipOptionalNull() {
				self = .null
			} else {
				throw JSONDecodingError.failure
			}
		default:
			let dbl = try scanner.nextDouble()
			//self = .double(dbl)
			if dbl.truncatingRemainder(dividingBy: 1) == 0 {
				self = .int(Int(dbl))
			} else {
				self = .double(dbl)
			}
		}
	}
	
	public init(from decoder: Decoder) throws {
		if var unkeyedContainer = try? decoder.unkeyedContainer() {
			var array: [JSON] = []
			while !unkeyedContainer.isAtEnd {
				let el = try unkeyedContainer.decode(JSON.self)
				array.append(el)
			}
			self = .array(array)
			return
		}
		if let keyedContainer = try? decoder.container(keyedBy: CodingKeys.self) {
			var dict: [String: JSON] = [:]
			try keyedContainer.allKeys.forEach {
				let j = try keyedContainer.decode(JSON.self, forKey: $0)
				dict[$0.stringValue] = j
			}
			self = .object(dict)
			return
		}
		let singleContainer = try decoder.singleValueContainer()
		if let b = try? singleContainer.decode(Bool.self)   { self = .bool(b);   return }
		if let i = try? singleContainer.decode(Int.self)    { self = .int(i);    return }
		if let d = try? singleContainer.decode(Double.self) { self = .double(d); return }
		if let s = try? singleContainer.decode(String.self) { self = .string(s); return }
		if singleContainer.decodeNil() 						{ self = .null;      return }
		throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Invalid JSON data"))
	}
	
	public func encode(to encoder: Encoder) throws {
		var singleContainer = encoder.singleValueContainer()
		switch self {
		case .bool(let b):   try singleContainer.encode(b)
		case .int(let i):    try singleContainer.encode(i)
		case .double(let d): try singleContainer.encode(d)
		case .string(let s): try singleContainer.encode(s)
		case .null:			 try singleContainer.encodeNil()
		case .array(let a):
			var unkeyedContainer = encoder.unkeyedContainer()
			try unkeyedContainer.encode(contentsOf: a)
		case .object(let d):
			var keyedContainer = encoder.container(keyedBy: CodingKeys.self)
			try d.forEach {
				try keyedContainer.encode($0.value, forKey: CodingKeys($0.key))
			}
		}
	}
	
    func putSelf(to encoder: inout ProtobufJSONEncoder) {
		switch self {
		case .object(let object):
			encoder.separator = nil
			encoder.openCurlyBracket()
			for (key, value) in object {
				encoder.startField(name: key)
				value.putSelf(to: &encoder)
			}
			encoder.closeCurlyBracket()
		case .array(let array):
            encoder.separator = nil
			encoder.openSquareBracket()
			if let value = array.first {
				value.putSelf(to: &encoder)
				var index = 1
				while index < array.count {
					encoder.comma()
					array[index].putSelf(to: &encoder)
					index += 1
				}
			}
			encoder.closeSquareBracket()
		case .bool(let bool):     encoder.putBoolValue(value: bool)
		case .int(let int):       encoder.appendInt(value: Int64(int))
		case .double(let double): encoder.putDoubleValue(value: double)
		case .string(let string): encoder.putStringValue(value: string)
		case .null:				  encoder.putNullValue()
		}
	}
	
	private struct CodingKeys: CodingKey {
		var stringValue: String
		var intValue: Int?
		
		init?(stringValue: String) { self.stringValue = stringValue }
		init?(intValue: Int) { return nil }
		init(_ key: String) { self.stringValue = key }
	}
}

extension JSON {
	
	public enum Kind: String, CaseIterable {
		case object, array, number, string, boolean, null
	}
	
	public var kind: Kind {
		switch self {
		case .array(_):  return .array
		case .object(_): return .object
		case .bool(_):   return .boolean
		case .double(_), .int(_): return .number
		case .null:      return .null
		case .string(_): return .string
		}
	}
	
	public var value : Any? {
		switch self {
		case .array(let ar):     return ar
		case .object(let d):     return d
		case .bool(let b):       return b
		case .double(let d):     return d
		case .int(let i):        return i
		case .string(let s):     return s
		case .null:				 return nil
		}
	}
	
	public var string: String? { return extract() as? String }
	
	public var int: Int? {
		switch self {
		case .int(let i):      return i
		case .string(let str): return Int(str)
		case .double(let d):   return Int(d)
		default: return nil
		}
	}
	
	public var double: Double? {
		switch self {
		case .double(let d):   return d
		case .int(let i):      return Double(i)
		case .string(let str): return Double(str)
		default: return nil
		}
	}
	
	public var bool: Bool? {
		switch self {
		case .bool(let d): return d
		case .string(let str):
			switch str.lowercased() {
			case "true", "yes", "1": return true
			case "false", "no", "0": return false
			default: return nil
			}
		case .int(let i):    if i == 1 || i == 0 { return i == 1 }
		case .double(let i): if i == 1 || i == 0 { return i == 1 }
		default: return nil
		}
		return nil
	}
	
	public var array: [JSON]? {
		if case .array(let d) = self { return d }
		return nil
	}
	
	public var object: [String: JSON]? {
		if case .object(let d) = self { return d }
		return nil
	}
	
	public var isNull: Bool { return self == .null }
	
	public subscript(index: Int) -> JSON? {
		if case .array(let arr) = self {
			return index < arr.count && index >= 0 ? arr[index] : nil
		}
		return nil
	}
	
	public subscript(key: String) -> JSON? {
		if case .object(let dict) = self { return dict[key] }
		return nil
	}
	
	public subscript<T: RawRepresentable>(key: T) -> JSON? where T.RawValue == String {
		if case .object(let dict) = self { return dict[key.rawValue] }
		return nil
	}
	
	public func extract() -> Any? {
		switch self {
		case .array(let ar):     return ar.map { $0.extract() }
		case .object(let d): 	 return d.mapValues { $0.extract() }
		case .bool(let b):       return b
		case .double(let d):     return d
		case .int(let i):        return i
		case .string(let s):     return s
		case .null:				 return nil
		}
	}
	
	public func toArray() -> [Any]? { return extract() as? [Any] }
	public func toDictionary() -> [String: Any]? { return extract() as? [String: Any] }
	
}

extension Optional where Wrapped == JSON {
    
    public subscript(index: Int) -> JSON? {
        return self?[index]
    }
    
    public subscript(key: String) -> JSON? {
        return self?[key]
    }
    
    public subscript<T: RawRepresentable>(key: T) -> JSON? where T.RawValue == String {
        return self?[key]
    }
    
}

extension JSON: CustomStringConvertible {
	public var description: String {
		var str = self.stringSlice()
		JSON.makeOffsets(&str)
		return str
	}
	
	private func stringSlice() -> String {
		switch self {
		case .bool(let b):       return "\(b)"
		case .int(let i):        return "\(i)"
		case .double(let d):     return "\(d)"
		case .string(let str):   return "\"\(str)\""
		case .array(let a):      return "[\(a.map{ $0.stringSlice() }.joined(separator: ", "))]"
		case .object(let d):     return "{\n\(d.map{ "\"\($0.key)\": \($0.value.stringSlice())" }.joined(separator: ",\n"))\n}"
		case .null:				 return "null"
		}
	}
	
	private static func makeOffsets(_ s: inout String) {
		var lb = 0
		var comp = s.components(separatedBy: "\n")
		for i in 0..<comp.count {
			let l = comp[i].components(separatedBy: "{").count - comp[i].components(separatedBy: "}").count
			if l < 0 { lb += l }
			comp[i] = [String](repeating: "   ", count: lb).joined() + comp[i]
			if l > 0 { lb += l }
		}
		s = comp.joined(separator: "\n")
	}
}

extension JSON: ExpressibleByArrayLiteral {
	public typealias ArrayLiteralElement = JSON
	public init(arrayLiteral elements: JSON...) { self = .array(elements) }
}

extension JSON: ExpressibleByDictionaryLiteral {
	public typealias Key = String
	public typealias Value = JSON
	
	public init(dictionaryLiteral elements: (String, JSON)...) {
		var dict: [String: JSON] = [:]
		elements.forEach { dict[$0.0] = $0.1 }
		self = .object(dict)
	}
}

extension JSON: ExpressibleByFloatLiteral {
	public typealias FloatLiteralType = Double
	public init(floatLiteral value: Double) { self = .double(value) }
}

extension JSON: ExpressibleByIntegerLiteral {
	public typealias IntegerLiteralType = Int
	public init(integerLiteral value: Int) { self = .int(value) }
}

extension JSON: ExpressibleByBooleanLiteral {
	public typealias BooleanLiteralType = Bool
	public init(booleanLiteral value: Bool) { self = .bool(value) }
}

extension JSON: ExpressibleByStringLiteral {
	public typealias StringLiteralType = String
	public init(stringLiteral value: String) { self = .string(value) }
}

extension JSON: Collection {
	public typealias Element = JSON
	
	public var count: Int {
		switch self {
		case .array(let array): return array.count
		case .object(let dictionary): return dictionary.count
		default: return 1
		}
	}
	
	public enum Index: Comparable {
		case int(Int), key(Dictionary<String, JSON>.Index), single
		
		public static func < (lhs: JSON.Index, rhs: JSON.Index) -> Bool {
			switch (lhs, rhs) {
			case (.int(let i), .int(let j)): return i < j
			case (.key(let i), .key(let j)): return i < j
			case (.single, .single): return false
			case (.single, .int(let i)): return 0 < i
			case (.int(let i), .single): return i < 0
			default: fatalError("Invalid Index types")
			}
		}
		
		public static func == (lhs: JSON.Index, rhs: JSON.Index) -> Bool {
			switch (lhs, rhs) {
			case (.int(let i), .int(let j)): return i == j
			case (.key(let i), .key(let j)): return i == j
			case (.single, .single): return true
			default: return false
			}
		}
	}
	
	public var startIndex: Index {
		switch self {
		case .array(let array): return .int(array.startIndex)
		case .object(let dictionary): return .key(dictionary.startIndex)
		default: return .single
		}
	}
	
	public var endIndex: Index {
		switch self {
		case .array(let array): return .int(array.endIndex)
		case .object(let dictionary): return .key(dictionary.endIndex)
		default: return .single
		}
	}
	
	public func index(after i: Index) -> Index {
		switch (self, i) {
		case (.array(let array), .int(let j)): return .int(array.index(after: j))
		case (.object(let dictionary), .key(let j)): return .key(dictionary.index(after: j))
		case (.object(let dictionary), .int(let j)): return .int(Array(dictionary).index(after: j))
		case (_, .single): return .single
		default: fatalError("Invalid index type")
		}
	}
	
	public subscript(position: JSON.Index) -> JSON {
		switch (self, position) {
		case (.array(let array), .int(let i)): return array[i]
		case (.object(let dictionary), .key(let i)): return dictionary[i].value
		case (.object(let dictionary), .int(let i)): return Array(dictionary)[i].value
		case (_, .single): return self
		default: fatalError("Invalid index type")
		}
	}
}

extension JSON: Hashable {
    
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .bool(let b):   b.hash(into: &hasher)
        case .int(let i):    i.hash(into: &hasher)
        case .double(let d): d.hash(into: &hasher)
        case .string(let s): s.hash(into: &hasher)
        case .array(let a):  a.hash(into: &hasher)
        case .object(let d): d.hash(into: &hasher)
        case .null:          Optional<JSON>.none.hash(into: &hasher)
        }
    }
	
	public static func ==(_ lhs: JSON, _ rhs: JSON) -> Bool {
		switch (lhs, rhs) {
		case (.bool(let l),	  .bool(let r)):   return l == r
		case (.int(let l), 	  .int(let r)):    return l == r
		case (.double(let l), .double(let r)): return l == r
		case (.string(let l), .string(let r)): return l == r
		case (.array(let l),  .array(let r)):  return l == r
		case (.object(let l), .object(let r)): return l == r
		case (.null, 		  .null):		   return true
		default: return false
		}
	}
}
