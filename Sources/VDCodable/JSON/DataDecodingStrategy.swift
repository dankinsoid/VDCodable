import Foundation

extension VDJSONDecoder {

    /// The strategy to use for decoding `Date` values.
    public enum DataDecodingStrategy {
        
        /// Defer to `Data` for decoding. This is the default strategy.
        case base64
        
        case deferredToData
        /// Decode the `Data` as a custom value decoded by the given closure.
        case custom((_ decoder: Decoder) throws -> Data)
    }
}
