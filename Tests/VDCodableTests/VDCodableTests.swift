import XCTest
@testable import VDCodable

final class VDCodableTests: XCTestCase {
	
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
	
	static var allTests = [
		("testExample", testExample),
	]
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
