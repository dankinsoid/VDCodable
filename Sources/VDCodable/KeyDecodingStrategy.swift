//
//  KeyDecodingStrategy.swift
//  TestProject
//
//  Created by Daniil on 26.11.2019.
//  Copyright © 2019 Daniil. All rights reserved.
//

import Foundation

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
