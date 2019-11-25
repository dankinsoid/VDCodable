//
//  DecodingOptions.swift
//  Develop
//
//  Created by Данил Войдилов on 06/01/2019.
//  Copyright © 2019 daniilVoidilov. All rights reserved.
//

import Foundation

extension VDJSONDecoder {
	
	/// The strategy to use for decoding `Date` values.
	public enum DateDecodingStrategy {
		/// Defer to `Date` for decoding. This is the default strategy.
		case deferredToDate
		
		/// Decode the `Date` as a UNIX timestamp from a JSON number.
		case secondsSince1970
		
		/// Decode the `Date` as UNIX millisecond timestamp from a JSON number.
		case millisecondsSince1970
		
		/// Decode the `Date` as an ISO-8601-formatted string (in RFC 3339 format).
		case iso8601
		
		/// Decode the `Date` as a string parsed by the given formatter.
		case formatted(DateFormatter)
		
		/// Decode the `Date` as a string parsed by the DateFormatter with the given string format.
		case stringFormats([String])
		
		/// Decode the `Date` as a custom value decoded by the given closure.
		case custom((_ decoder: Decoder) throws -> Date)
	}
	
    /// The strategy to use for decoding `Date` values.
    public enum DataDecodingStrategy {
        /// Defer to `Data` for decoding. This is the default strategy.
        case base64
        case deferredToData
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }
	
}

