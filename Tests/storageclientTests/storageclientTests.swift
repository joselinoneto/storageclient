import XCTest
import SwifterSwift
import Combine

@testable import storageclient

final class storageclientTests: XCTestCase {
    func testDataBaseStorage() throws {
        let storage = ApodStorageController(pathToSqlite: nil)

        let item = ApodStorage()
        item.id = UUID()
        item.title = "Mock Data"
        item.postedDate = Date()

        let item1 = ApodStorage()
        item1.id = UUID()
        item1.title = "Mock Data"
        item1.postedDate = Date()

        let item2 = ApodStorage()
        item2.id = UUID()
        item2.title = "Mock Data"
        item2.postedDate = Date()

        try storage.saveItems([item, item1, item2])

        let countEmittedExpected: Int = 5
        let apodPublisher = storage.$items.collect(countEmittedExpected).first()
        let counterArray = try awaitPublisher(apodPublisher)
        XCTAssertEqual(countEmittedExpected, counterArray.count)

        let array: [ApodStorage]? = counterArray.last ?? []
        XCTAssertEqual(array?.first?.id, item.id)
    }

    func testSQLBaseStorage() throws {
        let storage = ApodStorageController(pathToSqlite: nil)

        let item = ApodStorage()
        item.id = UUID()
        item.title = "Mock Data"
        item.postedDate = Date().adding(.year, value: -1)

        let item1 = ApodStorage()
        item1.id = UUID()
        item1.title = "Mock Data"
        item1.postedDate = Date().adding(.year, value: -2)

        let item2 = ApodStorage()
        item2.id = UUID()
        item2.title = "Mock Data"
        item2.postedDate = Date().adding(.year, value: -3)

        try storage.saveItemsSql([item, item1, item2])

        let items = try storage.getAllItems()

        XCTAssertEqual(items?.first?.id, item.id)
        XCTAssertEqual(items?.last?.id, item2.id)
    }
    
    func testCrud() throws {
        let controller = ApodStorageController(pathToSqlite: nil)
        let mock = ApodStorage()
        mock.id = UUID()
        mock.title = "MockTitle"
        mock.postedDate = Date()
        try controller.saveItems([mock])

        let items = try controller.getAllItems()

        XCTAssertNotNil(items)
        XCTAssertEqual(items?.first?.id, mock.id)
    }

    func testCrudAsync() async throws {
        let controller = ApodStorageController(pathToSqlite: nil)
        let mock = ApodStorage()
        mock.id = UUID()
        mock.title = "MockTitle"
        mock.postedDate = Date()
        try await controller.asyncSaveItem(mock)

        let items = try controller.getAllItems()

        XCTAssertNotNil(items)
        XCTAssertEqual(items?.first?.id, mock.id)
    }
}

extension XCTestCase {
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 10,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> T.Output {
        // This time, we use Swift's Result type to keep track
        // of the result of our Combine pipeline:
        var result: Result<T.Output, Error>?
        let expectation = self.expectation(description: "Awaiting publisher")

        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }

                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )

        // Just like before, we await the expectation that we
        // created at the top of our test, and once done, we
        // also cancel our cancellable to avoid getting any
        // unused variable warnings:
        waitForExpectations(timeout: timeout)
        cancellable.cancel()

        // Here we pass the original file and line number that
        // our utility was called at, to tell XCTest to report
        // any encountered errors at that original call site:
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )

        return try unwrappedResult.get()
    }
}
