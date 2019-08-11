// Sources/JSONDecodingError.swift - JSON decoding errors
//
// Copyright (c) 2014 - 2017 Apple Inc. and the project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See LICENSE.txt for license information:
// https://github.com/apple/swift-protobuf/blob/master/LICENSE.txt
//
// -----------------------------------------------------------------------------
///
/// JSON decoding errors
///
// -----------------------------------------------------------------------------

import Foundation

public enum JSONDecodingError: String, LocalizedError {
    case failure = "Something was wrong"
    case malformedNumber = "A number could not be parsed"
    case numberRange = "Numeric value was out of range or was not an integer value when expected"
    case malformedMap = "A map could not be parsed"
    case malformedBool = "A bool could not be parsed"
    case malformedString = "We expected a quoted string, or a quoted string has a malformed backslash sequence"
    case invalidUTF8 = "We encountered malformed UTF8"
    case missingFieldNames = "The message does not have fieldName information"
    case schemaMismatch = "The data type does not match the schema description"
    case illegalNull = "A 'null' token appeared in an illegal location"
    case unquotedMapKey = "A map key was not quoted"
    case leadingZero = "JSON RFC 7519 does not allow numbers to have extra leading zeros"
    case truncated = "We hit the end of the JSON string and expected something more..."
    case malformedDuration = "A JSON Duration could not be parsed"
    case malformedTimestamp = "A JSON Timestamp could not be parsed"
    case malformedFieldMask = "A FieldMask could not be parsed"
    case trailingGarbage = "Extraneous data remained after decoding should have been complete"
    case conflictingOneOf = "More than one value was specified for the same oneof field"
    case messageDepthLimit = "Reached the nesting limit for messages within messages while decoding."
	public var errorDescription: String? { return rawValue }
}
