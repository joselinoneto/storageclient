import XCTest
import SwifterSwift
import Combine

@testable import storageclient

final class storageclientTests: XCTestCase {
    func testDataBaseStorage() throws {
        let storage = ApodStorageController(pathToSqlite: nil)
        storage.observeApods(startDate: Date().adding(.day, value: -1), endDate: Date().adding(.day, value: 1))
        let item = ApodStorage()
        item.id = UUID()
        item.title = "Mock Data"
        item.postedDate = Date()
        try storage.saveItems([item])
        let items: [ApodStorage]? = try storage.getAllItems()

        XCTAssertNotNil(items)
        
        let countEmittedExpected: Int = 3
        let apodPublisher = storage.$items.collect(countEmittedExpected).first()
        let counterArray = try awaitPublisher(apodPublisher)
        XCTAssertEqual(countEmittedExpected, counterArray.count)
        
        let array: [ApodStorage]? = counterArray.last ?? []
        XCTAssertEqual(array?.first?.id, item.id)
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
