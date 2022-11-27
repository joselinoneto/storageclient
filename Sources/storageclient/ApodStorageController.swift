//
//  File.swift
//  
//
//  Created by José Neto on 27/11/2022.
//

import Foundation
import Combine
import ToolboxStorageClient
import GRDB

public class ApodStorageController {
    // MARK: - Private
    private var cancellables: Set<AnyCancellable> = []
    private let worker: LocalStorageClient<ApodStorage>

    // MARK: - Public
    @Published public var items: [ApodStorage]?
    //@Published public var currentMonth: TimelineMonth = TimelineMonth.currentMonth
    
    // MARK: - Init
    public init(pathToSqlite: String?) {
        worker = LocalStorageClient<ApodStorage>(pathToSqlite: pathToSqlite)
        createTable()
    }
    
    //MARK: - Methods - Public
    
    public func saveItems(_ items: [ApodStorage]) throws {
        items.forEach { [weak self] (item: ApodStorage) in
            do {
                try self?.worker.save(item: item)
            } catch {
                print(error.localizedDescription)
            }
        }
    }
    
    public func getAllItems() throws -> [ApodStorage]? {
        try worker.getAll()
    }
    
    public func observeApods(startDate: Date?, endDate: Date?) {
        guard let dbQueue: DatabaseQueue = worker.dbQueue else { return }
        let observation = ValueObservation.tracking { db in
            try ApodStorage
                .filter(Column("postedDate") >= startDate && Column("postedDate") <= endDate)
                .fetchAll(db)
        }
        observation
            .publisher(in: dbQueue)
            .sink { result in
                switch result {
                case .finished:
                    break
                case .failure(let error):
                    print(error)
                }
            } receiveValue: { [weak self] (savedItems: [ApodStorage]?) in
                self?.items = savedItems
            }.store(in: &self.cancellables)
    }
    
    // MARK: - Methods - Private
    private func createTable() {
        guard let dbQueue: DatabaseQueue = worker.dbQueue else { return }
        try? dbQueue.write { db in
            try db.create(table: "ApodStorage", options: .ifNotExists) { t in
                t.column("id", .text).primaryKey()
                t.column("date", .text)
                t.column("postedDate", .text)
                t.column("explanation", .text)
                t.column("mediaType", .text)
                t.column("thumbnailUrl", .text)
                t.column("title", .text)
                t.column("url", .text)
                t.column("hdurl", .text)
                t.column("copyright", .text)
            }
        }
    }
}
