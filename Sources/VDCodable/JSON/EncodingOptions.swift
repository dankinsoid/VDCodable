import Foundation

extension VDJSONEncoder {

    /// The strategy to use for decoding `Date` values.
    public enum DataEncodingStrategy {
        /// Defer to `Data` for encoding. This is the default strategy.
        case deferredToData
        case base64
        /// Encode the `Data` as a custom value encoded by the given closure.
        case custom((_ encoder: Encoder) throws -> Data)
    }
    
}

