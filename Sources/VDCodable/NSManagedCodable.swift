//
//  NSManagedCodable.swift
//  CoreDataWrapper
//
//  Created by Данил Войдилов on 09/05/2019.
//  Copyright © 2019 danil.voidilov. All rights reserved.
//

import Foundation
import CoreData

public protocol NSManagedDecodable: Decodable where Self: NSManagedObject {}
public protocol NSManagedEncodable: Encodable where Self: NSManagedObject {}
public typealias NSManagedCodable = NSManagedDecodable & NSManagedEncodable

extension NSManagedEncodable {
	
	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: PlainCodingKey.self)
		try encode(to: &container, ignore: [], entity: entity)
	}
	
}

extension NSManagedDecodable {
	
	public init(from decoder: Decoder) throws {
		self.init(entity: Self.entity(), insertInto: nil)
		try update(from: decoder)
	}
	
	public func update(from decoder: Decoder) throws {
		try decode(from: decoder.container(keyedBy: PlainCodingKey.self), ignore: [], entity: entity)
	}
	
	public func update<T: Encodable>(from value: T) throws {
		try update(from:VDJSONDecoder().decoder(for: VDJSONEncoder().encodeToJSON(value)))
	}
	
}

extension NSManagedObject {
	
	fileprivate func decode(from container: KeyedDecodingContainer<PlainCodingKey>, ignore: Set<String>, entity: NSEntityDescription) throws {
		for (name, attribute) in entity.attributesByName {
			let key = PlainCodingKey(name)
			if attribute.isOptional {
				guard container.contains(key) else { continue }
			} else {
				guard container.contains(key) else {
					throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: ""))
				}
			}
			let value: Any?
			switch attribute.attributeType {
			case .undefinedAttributeType:
				value = nil
			case .integer16AttributeType:
				value = try container.decode(Int16.self, forKey: key)
			case .integer32AttributeType:
				value = try container.decode(Int32.self, forKey: key)
			case .integer64AttributeType:
				value = try container.decode(Int64.self, forKey: key)
			case .decimalAttributeType:
				value = try container.decode(Decimal.self, forKey: key)
			case .doubleAttributeType:
				value = try container.decode(Double.self, forKey: key)
			case .floatAttributeType:
				value = try container.decode(Float.self, forKey: key)
			case .stringAttributeType:
				value = try container.decode(String.self, forKey: key)
			case .booleanAttributeType:
				value = try container.decode(Bool.self, forKey: key)
			case .dateAttributeType:
				value = try container.decode(Date.self, forKey: key)
			case .binaryDataAttributeType:
				value = try container.decode(Data.self, forKey: key)
			case .UUIDAttributeType:
				value = try container.decode(UUID.self, forKey: key)
			case .URIAttributeType:
				value = try container.decode(URL.self, forKey: key)
			case .transformableAttributeType:
//                ValueTransformer()
//                NSValueTransformerName.keyedUnarchiveFromDataTransformerName
				value = self.value(forKey: name) as? NSObject
			//try container.encodeIfPresent(value, forKey: key)
			case .objectIDAttributeType:
				value = nil
			default:
				value = nil
			}
			if let val = value {
				setValue(val, forKey: name)
			} else if !attribute.isOptional {
				throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: ""))
			}
		}
		for (name, relationship) in entity.relationshipsByName {
			guard !ignore.contains(name), let dest = relationship.destinationEntity else { continue }
			let key = PlainCodingKey(name)
			if relationship.isOptional {
				guard container.contains(key) else { continue }
			} else {
				guard container.contains(key) else {
					throw DecodingError.keyNotFound(key, DecodingError.Context(codingPath: [], debugDescription: ""))
				}
			}
			var _ignore = ignore
			if let inverseKey = relationship.inverseRelationship?.name {
				_ignore.insert(inverseKey)
			}
			let value: Any
			switch relationship.isToMany {
			case true:
				var unkeyed = try container.nestedUnkeyedContainer(forKey: key)
				var array: [NSManagedObject] = []
				array.reserveCapacity(unkeyed.count ?? 0)
				while !unkeyed.isAtEnd {
					let object = NSManagedObject(entity: dest, insertInto: nil)
					try object.decode(from: unkeyed.nestedContainer(keyedBy: PlainCodingKey.self), ignore: _ignore, entity: dest)
					if let inverseKey = relationship.inverseRelationship?.name {
						object.setValue(self, forKey: inverseKey)
					}
					array.append(object)
				}
				if relationship.isOrdered {
					value = NSOrderedSet(array: array)
				} else {
					value = NSSet(array: array)
				}
			case false:
				let _container = try container.nestedContainer(keyedBy: PlainCodingKey.self, forKey: key)
				let object = NSManagedObject(entity: dest, insertInto: nil)
				try object.decode(from: _container, ignore: _ignore, entity: dest)
				if let inverse = relationship.inverseRelationship {
					if inverse.isToMany {
						if inverse.isOrdered {
							object.setValue(NSOrderedSet(array: [self]), forKey: inverse.name)
						} else {
							object.setValue(NSSet(array: [self]), forKey: inverse.name)
						}
					} else {
						object.setValue(self, forKey: inverse.name)
					}
				}
				value = object
			}
			setValue(value, forKey: name)
		}
	}

	fileprivate func encode(to container: inout KeyedEncodingContainer<PlainCodingKey>, ignore: Set<String>, entity: NSEntityDescription) throws {
		for (name, attribute) in entity.attributesByName {
			let key = PlainCodingKey(name)
			switch (attribute.attributeType, attribute.isOptional) {
			case (.undefinedAttributeType, _):
				break
			case (.integer16AttributeType, false):
				let value: Int16 = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.integer16AttributeType, true):
				let value = self.value(forKey: name) as? Int16
				try container.encodeIfPresent(value, forKey: key)
			case (.integer32AttributeType, false):
				let value: Int32 = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.integer32AttributeType, true):
				let value = self.value(forKey: name) as? Int32
				try container.encodeIfPresent(value, forKey: key)
			case (.integer64AttributeType, false):
				let value: Int64 = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.integer64AttributeType, true):
				let value = self.value(forKey: name) as? Int64
				try container.encodeIfPresent(value, forKey: key)
			case (.decimalAttributeType, false):
				let value: Decimal = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.decimalAttributeType, true):
				let value = self.value(forKey: name) as? Decimal
				try container.encodeIfPresent(value, forKey: key)
			case (.doubleAttributeType, false):
				let value: Double = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.doubleAttributeType, true):
				let value = self.value(forKey: name) as? Double
				try container.encodeIfPresent(value, forKey: key)
			case (.floatAttributeType, false):
				let value: Float = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.floatAttributeType, true):
				let value = self.value(forKey: name) as? Float
				try container.encodeIfPresent(value, forKey: key)
			case (.stringAttributeType, false):
				let value: String = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.stringAttributeType, true):
				let value = self.value(forKey: name) as? String
				try container.encodeIfPresent(value, forKey: key)
			case (.booleanAttributeType, false):
				let value: Bool = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.booleanAttributeType, true):
				let value = self.value(forKey: name) as? Bool
				try container.encodeIfPresent(value, forKey: key)
			case (.dateAttributeType, false):
				let value: Date = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.dateAttributeType, true):
				let value = self.value(forKey: name) as? Date
				try container.encodeIfPresent(value, forKey: key)
			case (.binaryDataAttributeType, false):
				let value: Data = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.binaryDataAttributeType, true):
				let value = self.value(forKey: name) as? Data
				try container.encodeIfPresent(value, forKey: key)
			case (.UUIDAttributeType, false):
				let value: UUID = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.UUIDAttributeType, true):
				let value = self.value(forKey: name) as? UUID
				try container.encodeIfPresent(value, forKey: key)
			case (.URIAttributeType, false):
				let value: URL = try getValue(forKey: name)
				try container.encode(value, forKey: key)
			case (.URIAttributeType, true):
				let value = self.value(forKey: name) as? URL
				try container.encodeIfPresent(value, forKey: key)
			case (.transformableAttributeType, _):
                break
//                ValueTransformer()
//                NSValueTransformerName.keyedUnarchiveFromDataTransformerName
//                let value = self.value(forKey: name) as? NSObject
			//try container.encodeIfPresent(value, forKey: key)
			case (.objectIDAttributeType, _):
				break
			default:
				break
			}
		}
		for (name, relationship) in entity.relationshipsByName {
			guard !ignore.contains(name), let dest = relationship.destinationEntity else { continue }
			let key = PlainCodingKey(name)
			var _ignore = ignore
			if let inverseKey = relationship.inverseRelationship?.name {
				_ignore.insert(inverseKey)
			}
			switch (relationship.isToMany, relationship.isOptional) {
			case (true, true):
				var set: Set<AnyHashable>?
				if relationship.isOrdered {
					let nsset = value(forKey: name) as? NSOrderedSet
					set = nsset?.set
				} else {
					let nsset = value(forKey: name) as? NSSet
					set = nsset?.addingObjects(from: [])
				}
				try set?.encodeNSMO(to: &container, ignore: _ignore, for: key)
			case (true, false):
				var set: Set<AnyHashable>
				if relationship.isOrdered {
					let nsset: NSOrderedSet = try getValue(forKey: name)
					set = nsset.set
				} else {
					let nsset: NSSet = try getValue(forKey: name)
					set = nsset.addingObjects(from: [])
				}
				try set.encodeNSMO(to: &container, ignore: _ignore, for: key)
			case (false, true):
				let object = value(forKey: name) as? NSManagedObject
				var _container = container.nestedContainer(keyedBy: PlainCodingKey.self, forKey: key)
				try object?.encode(to: &_container, ignore: _ignore, entity: dest)
			case (false, false):
				let object: NSManagedObject = try getValue(forKey: name)
				var _container = container.nestedContainer(keyedBy: PlainCodingKey.self, forKey: key)
				try object.encode(to: &_container, ignore: _ignore, entity: dest)
			}
		}
	}
	
	fileprivate func getValue<T>(forKey key: String) throws -> T {
		guard let value = value(forKey: key) as? T else {
			throw DecodingError.keyNotFound(PlainCodingKey(key), DecodingError.Context(codingPath: [], debugDescription: ""))
		}
		return value
	}
	
}

extension Set where Element == AnyHashable {
	
	fileprivate func encodeNSMO(to keyed: inout KeyedEncodingContainer<PlainCodingKey>, ignore: Set<String>, for key: PlainCodingKey) throws {
		var unkeyed = keyed.nestedUnkeyedContainer(forKey: key)
		try forEach {
			guard let object = $0 as? NSManagedObject else { throw NSError() }
			var _container = unkeyed.nestedContainer(keyedBy: PlainCodingKey.self)
			try object.encode(to: &_container, ignore: ignore, entity: object.entity)
		}
	}
	
}
