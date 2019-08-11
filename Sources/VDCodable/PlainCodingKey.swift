//
//  PlainCodingKey.swift
//  VDCodable
//
//  Created by Daniil on 10.08.2019.
//

import Foundation

public struct PlainCodingKey: CodingKey {
    public var stringValue: String
    public var intValue: Int?
    
    public init?(intValue: Int) {
        self.intValue = intValue
        self.stringValue = "\(intValue)"
    }
    
    public init?(stringValue: String) {
        self.stringValue = stringValue
    }
    
    public init(_ string: String) {
        stringValue = string
    }
    
    public init(_ int: Int) {
        stringValue = "\(int)"
        intValue = int
    }
    
    public init(_ key: CodingKey) {
        stringValue = key.stringValue
        intValue = key.intValue
    }
    
}
