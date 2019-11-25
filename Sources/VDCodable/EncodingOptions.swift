//
//  EncodingOptions.swift
//  VDCodable
//
//  Created by Daniil on 11.08.2019.
//

import Foundation

extension VDJSONEncoder {
    
    /// The strategy to use for decoding `Date` values.
    public enum DateEncodingStrategy {
        /// Defer to `Date` for encoding. This is the default strategy.
        case deferredFromDate
        
        /// Encode the `Date` as a UNIX timestamp from a JSON number.
        case secondsSince1970
        
        /// Encode the `Date` as UNIX millisecond timestamp from a JSON number.
        case millisecondsSince1970
        
        /// Encode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
        case iso8601
        
        /// Encode the `Date` as a string parsed by the given formatter.
        case formatted(DateFormatter)
        
        /// Encode the `Date` as a string parsed by the DateFormatter with the given string format.
        case stringFormat(String)
        
        /// Encode the `Date` as a custom value encoded by the given closure.
        case custom((_ encoder: Encoder) throws -> JSON)
    }
    
    /// The strategy to use for decoding `Date` values.
    public enum DataEncodingStrategy {
        /// Defer to `Data` for encoding. This is the default strategy.
        case deferredFromData
        case base64
        /// Encode the `Data` as a custom value encoded by the given closure.
        case custom((_ encoder: Encoder) throws -> Data)
    }
    
}

