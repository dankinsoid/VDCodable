import Foundation
import SimpleCoders

open class VDJSONDecoder: CodableDecoder {
	
	open var dateDecodingStrategy: any DateDecodingStrategy
	open var dataDecodingStrategy: DataDecodingStrategy
	open var keyDecodingStrategy: any KeyDecodingStrategy
	open var tryDecodeFromQuotedString: Bool
	open var decodeOneObjectAsArray: Bool
	open var customDecoding: (([CodingKey], JSON) -> JSON)?
	
	public init(
		dateDecodingStrategy: any DateDecodingStrategy = DefferedToDateCodingStrategy(),
		dataDecodingStrategy: DataDecodingStrategy = .deferredToData,
		keyDecodingStrategy: any KeyDecodingStrategy = UseDeafultKeyCodingStrategy(),
		decodeOneObjectAsArray: Bool = true,
		tryDecodeFromQuotedString: Bool = true,
		customDecoding: (([CodingKey], JSON) -> JSON)? = nil
	) {
		self.dateDecodingStrategy = dateDecodingStrategy
		self.dataDecodingStrategy = dataDecodingStrategy
		self.keyDecodingStrategy = keyDecodingStrategy
		self.tryDecodeFromQuotedString = tryDecodeFromQuotedString
		self.decodeOneObjectAsArray = decodeOneObjectAsArray
		self.customDecoding = customDecoding
	}
	
	open func decode<D: Decodable>(_ type: D.Type, json: JSON) throws -> D {
		if type == JSON.self, let result = json as? D { return (customDecoding?([], json) as? D) ?? result }
		return try D.init(from: decoder(for: json))
	}
	
	open func decode<D: Decodable>(_ type: D.Type, from data: Data) throws -> D {
		let json = try JSON(from: data)
		return try decode(type, json: json)
	}
	
	open func decode<D: Codable>(json: JSON, defaults: D) -> D {
		if D.self == JSON.self, let result = json as? D { return (customDecoding?([], json) as? D) ?? result }
		do {
			return try D.init(from: decoder(for: json, defaults: VDJSONEncoder().encodeToJSON(defaults)))
		} catch {
			return defaults
		}
	}
	
	open func decode<D: Codable>(from data: Data, defaults: D) -> D {
		do {
			let json = try JSON(from: data)
			return decode(json: json, defaults: defaults)
		}	catch {
			return defaults
		}
	}
	
	func decoder(for json: JSON, defaults: JSON? = nil) -> Decoder {
		VDDecoder(unboxer: Unboxer(json: json, dateDecodingStrategy: dateDecodingStrategy, dataDecodingStrategy: dataDecodingStrategy, keyDecodingStrategy: keyDecodingStrategy, decodeOneObjectAsArray: decodeOneObjectAsArray, tryDecodeFromQuotedString: tryDecodeFromQuotedString, customDecoding: customDecoding, defaults: defaults))
	}
}

fileprivate struct Unboxer: DecodingUnboxer {
    
	let userInfo: [CodingUserInfoKey: Any] = [:]
	let codingPath: [CodingKey]
	let dateDecodingStrategy: any DateDecodingStrategy
	let dataDecodingStrategy: VDJSONDecoder.DataDecodingStrategy
	let keyDecodingStrategy: KeyDecodingStrategy?
	let decodeOneObjectAsArray: Bool
	let customDecoding: (([CodingKey], JSON) -> JSON)?
	let tryDecodeFromQuotedString: Bool
	let input: JSON
	let defaults: JSON?
	
	init(input: JSON, path: [CodingKey], other unboxer: Unboxer) {
		self.input = unboxer.customDecoding?(path, input) ?? input
		codingPath = path
		dateDecodingStrategy = unboxer.dateDecodingStrategy
		dataDecodingStrategy = unboxer.dataDecodingStrategy
		keyDecodingStrategy = unboxer.keyDecodingStrategy
		tryDecodeFromQuotedString = unboxer.tryDecodeFromQuotedString
		decodeOneObjectAsArray = unboxer.decodeOneObjectAsArray
		customDecoding = unboxer.customDecoding
		defaults = path.last.flatMap { unboxer.defaults?[$0] }
	}
	
	init(
        json: JSON,
        dateDecodingStrategy: any DateDecodingStrategy,
        dataDecodingStrategy: VDJSONDecoder.DataDecodingStrategy,
        keyDecodingStrategy: KeyDecodingStrategy?,
        decodeOneObjectAsArray: Bool,
        tryDecodeFromQuotedString: Bool,
        customDecoding: (([CodingKey], JSON) -> JSON)?,
        defaults: JSON?
    ) {
		self.dateDecodingStrategy = dateDecodingStrategy
		self.dataDecodingStrategy = dataDecodingStrategy
		self.keyDecodingStrategy = keyDecodingStrategy
		self.tryDecodeFromQuotedString = tryDecodeFromQuotedString
		self.decodeOneObjectAsArray = decodeOneObjectAsArray
		self.customDecoding = customDecoding
		self.codingPath = []
		self.defaults = defaults
		self.input = customDecoding?([], json) ?? json
	}
	
	func decodeArray() throws -> [JSON] {
		do {
			return try decodeArray(input: input)
		} catch {
			if let def = defaults, let result = try? decodeArray(input: def) {
				return result
			} else {
				throw error
			}
		}
	}
	
	private func decodeArray(input: JSON) throws -> [JSON] {
		switch input {
		case .string:
			return try decode([JSON].self) {
				let json = try JSON(from: &$0)~!
				return try self._decodeArray(json: json)
			}
		default:
			return try _decodeArray(json: input)
		}
	}
	
	private func _decodeArray(json: JSON) throws -> [JSON] {
		switch json {
		case .array(let result):
			return result
		default:
			if self.decodeOneObjectAsArray {
				return [json]
			} else {
				throw DecodingError.typeMismatch([JSON].self, DecodingError.Context(codingPath: self.codingPath, debugDescription: "Expected to decode array but found \(json.kind) instead."))
			}
		}
	}
	
	func decodeDictionary() throws -> [String: JSON] {
		var dictionary = try decode([String: JSON].self) { try JSON(from: &$0)~!.object~! }
		guard let keyDecodingStrategy else {
			return dictionary
		}
		for (key, value) in dictionary {
            try dictionary[keyDecodingStrategy.decode(currentKey: PlainCodingKey(key), codingPath: codingPath)] = value
		}
		return dictionary
	}
	
	@inline(__always)
	func decodeNil() -> Bool {
		if case .null = input { return true }
		if case .null = defaults { return true }
		return false
	}
	
	@inline(__always)
	func decode(_ type: Bool.Type) throws -> Bool {
		try decode(type) { try $0.nextBool() }
	}
	
	@inline(__always)
	func decode(_ type: String.Type) throws -> String {
		if case .string(let string) = input {
			return string
		}
		if case .string(let string) = defaults {
			return string
		}
		throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(type) but found \(input.kind) instead."))
	}
	
	@inline(__always)
	private func decode<T>(_ type: T.Type, block: @escaping (inout JSONScanner) throws -> T) throws -> T {
		do {
			return try decode(type, input: input, block: block)
		} catch {
			if let def = defaults, let result = try? decode(type, input: def, block: block) {
				return result
			} else {
				throw error
			}
		}
	}
	
	@inline(__always)
	private func decode<T>(_ type: T.Type, input: JSON, block: @escaping (inout JSONScanner) throws -> T) throws -> T {
		if let result = input.value as? T {
			return result
		}
		if tryDecodeFromQuotedString, case .string(let string) = input {
			let data = Data(string.utf8)
			return try data.withUnsafeBytes { rawPointer -> T in
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
		switch input {
		case .number(let dbl): return Double(dbl)
		default: break
		}
		switch defaults {
		case .number(let dbl): return Double(dbl)
		default: break
		}
		return try decode(type) { try $0.nextDouble() }
	}
	
	func decode(_ type: Int.Type) throws -> Int {
		switch input {
		case .number(let dbl): return (dbl as NSDecimalNumber).intValue
		default: break
		}
		switch defaults {
		case .number(let dbl): return (dbl as NSDecimalNumber).intValue
		default: break
		}
		return try decode(type) { try $0.nextSignedInteger() }
	}
	
	func decodeFor(unknown key: CodingKey) throws -> JSON? {
		defaults?[key]
	}
	
	@inline(__always)
	func decode<T: Decodable>(_ type: T.Type) throws -> T {
		do {
			return try decode(type, input: input)
		} catch {
			if let def = defaults, let result = try? decode(type, input: def) {
				return result
			} else {
				throw error
			}
		}
	}
	
	@inline(__always)
	private func decode<T: Decodable>(_ type: T.Type, input: JSON) throws -> T {
		if type == JSON.self, let result = input as? T { return result }
		let decoder = VDDecoder(unboxer: self)
		if type == Date.self || type as? NSDate.Type != nil {
			let result = try decodeDate(from: decoder)
			return try cast(result, as: type)
		}
		if type == Data.self || type as? NSData.Type != nil {
			let result = try decodeData(from: decoder)
			return try cast(result, as: type)
		}
		if type == URL.self || type as? NSURL.Type != nil {
			let string = try decode(String.self)
			let result = try decodeUrl(from: string)
			return try cast(result, as: type)
		}
		if type == Decimal.self || type as? NSDecimalNumber.Type != nil {
			let result = try decodeDecimal()
			return try cast(result, as: type)
		}
		return try T.init(from: decoder)
	}
	
	private func decodeDecimal() throws -> Decimal {
		switch input {
		case .number(let dbl): return dbl
		default: break
		}
		return try decode(Decimal.self) { try $0.nextDecimal() }
	}
	
	@inline(__always)
	private func decodeDate(from decoder: VDDecoder<Unboxer>) throws -> Date {
        try dateDecodingStrategy.decode(from: VDDecoder(unboxer: self))
	}
	
	@inline(__always)
	private func decodeData(from decoder: VDDecoder<Unboxer>) throws -> Data {
		switch dataDecodingStrategy {
		case .deferredToData: return try Data(from: decoder)
		case .base64:
			return try decode(Data.self) { try $0.nextBytesValue() }
		case .custom(let transform):
			return try transform(decoder)
		}
	}
	
	private func cast<A, T>(_ value: A, as type: T.Type) throws -> T {
		if let result = value as? T {
			return result
		} else {
			throw DecodingError.typeMismatch(type, DecodingError.Context(codingPath: codingPath, debugDescription: "Expected to decode \(type) but found \(String(describing: A.self)) instead."))
		}
	}
	
	private func decodeUrl(from string: String) throws -> URL {
		if let url = URL(string: string) { return url }
		if let url = URL(string: string.replacingOccurrences(of: "\\/", with: "/")) { return url }
		throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: codingPath, debugDescription: "Incorrect url \"\(string)\"", underlyingError: nil))
	}
}

fileprivate let _dateFormatter = DateFormatter()
@available(macOS 10.12, iOS 10.0, watchOS 3.0, tvOS 10.0, *)
internal let _iso8601Formatter: ISO8601DateFormatter = {
	let formatter = ISO8601DateFormatter()
	formatter.formatOptions = .withInternetDateTime
	return formatter
}()

public func printJSON<T: Encodable>(_ value: T) {
	do {
		let json = try VDJSONEncoder().encodeToJSON(value)
		print(json)
	} catch {
		dump(value)
	}
}
