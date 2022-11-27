import XCTest
@testable import storageclient

final class storageclientTests: XCTestCase {
    func testDataBaseStorage() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let storage = ApodStorageController(pathToSqlite: nil)
        let items = storage.items
        XCTAssertNil(items)
    }
}
