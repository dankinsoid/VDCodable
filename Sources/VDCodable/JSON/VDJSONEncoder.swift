import Foundation
import SimpleCoders

open class VDJSONEncoder: CodableEncoder {
	
    open var dateEncodingStrategy: any DateEncodingStrategy
    open var dataEncodingStrategy: DataEncodingStrategy
    open var keyEncodingStrategy: any KeyEncodingStrategy
    open var maximumFractionLength: Int32?
    open var customEncoding: (([CodingKey], Data) throws -> Data)?
    
    public init(
        dateEncodingStrategy: any DateEncodingStrategy = DefferedToDateCodingStrategy(),
        dataEncodingStrategy: VDJSONEncoder.DataEncodingStrategy = .deferredToData,
        keyEncodingStrategy: any KeyEncodingStrategy = UseDeafultKeyCodingStrategy(),
        maximumFractionLength: Int32? = nil,
        customEncoding: (([CodingKey], Data) throws -> Data)? = nil
    ) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.maximumFractionLength = maximumFractionLength
        self.customEncoding = customEncoding
    }
	
	open func encode<T: Encodable>(_ value: T) throws -> Data {
        var encoder = VDEncoder(
            boxer: Boxer(
                dateEncodingStrategy: dateEncodingStrategy,
                keyEncodingStrategy: keyEncodingStrategy,
                dataEncodingStrategy: dataEncodingStrategy,
                maximumFractionLength: maximumFractionLength,
                customEncoding: customEncoding
            )
        )
        let data = try encoder.encode(value)
        return data
	}
    
    open func encodeToJSON<T: Encodable>(_ value: T) throws -> JSON {
        if let result = value as? JSON {
            return result
        }
        let json = try JSON(from: encode(value))
        return json
    }
	
}

private struct Boxer: EncodingBoxer {
    
    let codingPath: [CodingKey]
    let dateEncodingStrategy: any DateEncodingStrategy
    let dataEncodingStrategy: VDJSONEncoder.DataEncodingStrategy
    let keyEncodingStrategy: any KeyEncodingStrategy
    let customEncoding: (([CodingKey], Data) throws -> Data)?
    let maximumFractionLength: Int32?
    private var encoder: ProtobufJSONEncoder {
        return ProtobufJSONEncoder(maxFractionDigits: maximumFractionLength)
    }
    
    init(dateEncodingStrategy: any DateEncodingStrategy, keyEncodingStrategy: any KeyEncodingStrategy, dataEncodingStrategy: VDJSONEncoder.DataEncodingStrategy, maximumFractionLength: Int32?, customEncoding: (([CodingKey], Data) throws -> Data)?) {
        self.dateEncodingStrategy = dateEncodingStrategy
        self.dataEncodingStrategy = dataEncodingStrategy
        self.keyEncodingStrategy = keyEncodingStrategy
        self.codingPath = []
        self.maximumFractionLength = maximumFractionLength
        self.customEncoding = customEncoding
    }
    
    init(path: [CodingKey], other boxer: Boxer) {
        codingPath = path
        dateEncodingStrategy = boxer.dateEncodingStrategy
        dataEncodingStrategy = boxer.dataEncodingStrategy
        maximumFractionLength = boxer.maximumFractionLength
        keyEncodingStrategy = boxer.keyEncodingStrategy
        customEncoding = boxer.customEncoding
    }
    
    private func encodeAny(_ json: Data) throws -> Data {
        return try customEncoding?(codingPath, json) ?? json
    }
    
    func encodeNil() throws -> Data {
        var encoder = self.encoder
        encoder.putNullValue()
        return try encodeAny(encoder.dataResult)
    }
    func encode(_ array: [Data]) throws -> Data {
        var encoder = self.encoder
        encoder.openSquareBracket()
        if let value = array.first {
            encoder.append(utf8Data: value)
            var index = 1
            while index < array.count {
                encoder.comma()
                encoder.append(utf8Data: array[index])
                index += 1
            }
        }
        encoder.closeSquareBracket()
        return try encodeAny(encoder.dataResult)
    }
    func encode(_ value: Bool) throws -> Data {
        var encoder = self.encoder
        encoder.putBoolValue(value: value)
        return try encodeAny(encoder.dataResult)
    }
    func encode(_ value: String) throws -> Data {
        var encoder = self.encoder
        encoder.putStringValue(value: value)
        return try encodeAny(encoder.dataResult)
    }
    func encode(_ value: Double) throws -> Data {
        var encoder = self.encoder
        encoder.putDoubleValue(value: value)
        return try encodeAny(encoder.dataResult)
    }
    func encode(_ value: Float) throws -> Data {
        var encoder = self.encoder
        encoder.putFloatValue(value: value)
        return try encodeAny(encoder.dataResult)
    }
    func encode(_ value: Int) throws -> Data {
        var encoder = self.encoder
        encoder.appendInt(value: Int64(value))
        return try encodeAny(encoder.dataResult)
    }
    
    func encode(_ dictionary: [String: Data]) throws -> Data {
        var encoder = self.encoder
        encoder.separator = nil
        encoder.openCurlyBracket()
        for (key, value) in dictionary {
            try encoder.startField(name: self.key(for: key))
            encoder.append(utf8Data: value)
        }
        encoder.closeCurlyBracket()
        return try encodeAny(encoder.dataResult)
    }
    
    private func key(for string: String) throws -> String {
        try keyEncodingStrategy.encode(currentKey: PlainCodingKey(string), codingPath: codingPath)
    }
    
    func encode(date: Date) throws -> Data {
        var encoder = VDEncoder(boxer: self)
        try dateEncodingStrategy.encode(date, to: encoder)
        return try encoder.get()
    }
    
    func encode(data: Data) throws -> Data {
        switch dataEncodingStrategy {
        case .deferredToData:
            var encoder = VDEncoder(boxer: self)
            return try encoder.encode(data)
        case .base64:
            var encoder = self.encoder
            encoder.putBytesValue(value: data)
            return try encodeAny(encoder.dataResult)
        case .custom(let block):
            return try encodeAny(block(VDEncoder(boxer: self)))
        }
    }
    
    func encode(decimal: Decimal) throws -> Data {
        var encoder = self.encoder
        encoder.putDecimalValue(value: decimal)
        return try encodeAny(encoder.dataResult)
    }
    
    func encode<T: Encodable>(value: T) throws -> Data {
        if let date = value as? Date {
            return try encode(date: date)
        }
        if let data = value as? Data {
            return try encode(data: data)
        }
        if let decimal = value as? Decimal {
            return try encode(decimal: decimal)
        }
        var encoder = VDEncoder(boxer: self)
        return try encoder.encode(value)
    }
    
}
