import XCTest
import Foundation
@testable import VDCodable

final class VDCodableTests: XCTestCase {
	
    let value = SomeStruct.create()
    let data = try! JSONEncoder().encode(SomeStruct.create())
    
	func testExample() {
		do {
			let str = Struct()
			let json = try VDJSONEncoder().encodeToJSON(str)
			var wrongJson = json
			wrongJson["array"] = [1, 2, 3]
			wrongJson["inner"] = .null
			
			let value = VDJSONDecoder().decode(json: wrongJson, defaults: str)
			printJSON(value)
			XCTAssert(value.array == [1, 2, 3], "\(value.array)")
		} catch {
			print(error)
			XCTExpectFailure(error.localizedDescription, options: .init())
		}
	}
    
    func testJSONEncoder() {
        measure {
            blackHole(try! JSONEncoder().encode(value))
        }
    }
    
    
    func testVDJSONEncoder() {
        measure {
            blackHole(try! VDJSONEncoder().encode(value))
        }
    }
    
    func testJSONDecoder() {
        measure {
            blackHole(try! JSONDecoder().decode(SomeStruct.self, from: data))
        }
    }
    
    
    func testVDJSONDecoder() {
        measure {
            blackHole(try! VDJSONDecoder().decode(SomeStruct.self, from: data))
        }
    }
    
    func testURLQueryEncoder() throws {
        let encoder = URLQueryEncoder()
        encoder.nestedEncodingStrategy = .json
        encoder.trimmingSquareBrackets = true
        let params = try encoder.encodeParameters(QueryStruct())
        XCTAssertEqual(params["int"], "0")
        XCTAssertEqual(params["double"], "0")
        XCTAssertEqual(params["string"], "string")
        XCTAssertEqual(params["decimal"], "0")
    }
    
	static var allTests = [
		("testExample", testExample),
        ("testJSONEncoder", testJSONEncoder),
        ("testVDJSONEncoder", testVDJSONEncoder),
        ("testJSONDecoder", testJSONDecoder),
        ("testVDJSONDecoder", testVDJSONDecoder),
	]
    
    private func blackHole<T>(_ value: T) {
    }
}

struct SomeStruct: Codable {
    
    static func create(
        nested: Bool = true
    ) -> SomeStruct {
        SomeStruct(
            int: .random(in: Int.min...Int.max),
            float: .random(in: -1_000_000...1_000_000),
            someString: "Some string",
            someOptional: 12,
            someArray: nested ? [SomeStruct](repeating: .create(nested: false), count: Int.random(in: 300...1000)): [],
            someDictionary: nested ? [
                "firstValue": .create(nested: false)
            ] : [:]
        )
    }
    
    var int: Int = 0
    var float: Float = 0.0
    var someString: String = "string"
    var someOptional: Double? = 0.0
    var someArray: [SomeStruct] = []
    var someDictionary: [String: SomeStruct] = [:]
}

struct QueryStruct: Codable {
    
    var int = 0
    var double = 0.0
    var string = "string"
    var decimal = Decimal(0)
}

struct Struct: Codable {
    
	var array: [Int] = []
	var optional: Date?
	var inner = Inner()
	
	struct Inner: Codable {
		var string = "defaulString"
		var int = 0
		var date = Date()
	}
}
