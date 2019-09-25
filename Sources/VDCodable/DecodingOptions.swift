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
	/// The strategy to use for automatically changing the value of keys before decoding.
	public enum KeyDecodingStrategy {
		/// Use the keys specified by each type. This is the default strategy.
		case useDefaultKeys
		
		/// Convert from "snake_case_keys" to "camelCaseKeys" before attempting to match a key with the one specified by each type.
		///
		/// The conversion to upper case uses `Locale.system`, also known as the ICU "root" locale. This means the result is consistent regardless of the current user's locale and language preferences.
		///
		/// Converting from snake case to camel case:
		/// 1. Capitalizes the word starting after each `_`
		/// 2. Removes all `_`
		/// 3. Preserves starting and ending `_` (as these are often used to indicate private variables or other metadata).
		/// For example, `one_two_three` becomes `oneTwoThree`. `_one_two_three_` becomes `_oneTwoThree_`.
		///
		/// - Note: Using a key decoding strategy has a nominal performance cost, as each string key has to be inspected for the `_` character.
		case convertFromSnakeCase
		
		/// Provide a custom conversion from the key in the encoded JSON to the keys specified by the decoded types.
		/// The full path to the current decoding position is provided for context (in case you need to locate this key within the payload). The returned key is used in place of the last component in the coding path before decoding.
		/// If the result of the conversion is a duplicate key, then only one value will be present in the container for the type to decode from.
		case custom((_ path: [CodingKey]) -> String)
		
		public static func keyFromSnakeCase(_ stringKey: String) -> String {
			guard !stringKey.isEmpty else { return stringKey }
			var result = ""
			var needUppercase = false
			var i = 0
			let endIndex = stringKey.count - 1
			for char in stringKey {
				if char == "_", i > 0, i < endIndex {
					needUppercase = true
				} else if needUppercase {
					result += String(char).uppercased()
					needUppercase = false
				} else {
					result.append(char)
				}
				i += 1
			}
			return result
		}
		
	}
	
}

