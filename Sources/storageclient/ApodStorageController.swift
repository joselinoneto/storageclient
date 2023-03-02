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
    
    // MARK: - Init
    public init(pathToSqlite: String?) {
        worker = LocalStorageClient<ApodStorage>(pathToSqlite: pathToSqlite)
        createTable()
        worker.valueObservation()

        worker.$items.sink { (items: [ApodStorage]?) in
            self.items = items
        }.store(in: &cancellables)
    }

    deinit {
        worker.cancelObservation()
    }
    
    //MARK: - Methods - Public
    public func saveItemsSql(_ items: [ApodStorage]) throws {
        var sql: String = """
        INSERT INTO APODSTORAGE (id, date, postedDate, explanation, mediaType, thumbnailUrl, title, url, hdurl, copyright) VALUES
        """
        items.forEach { (item: ApodStorage) in
            sql.append(" ('\(item.id?.uuidString ?? "")',")
            sql.append("'\(item.date ?? "")',")
            sql.append("'\(item.postedDate?.databaseValue ?? Date().databaseValue)',")
            sql.append("'\(item.explanation ?? "")',")
            sql.append("'\(item.mediaType ?? "")',")
            sql.append("'\(item.thumbnailUrl ?? "")',")
            sql.append("'\(item.title ?? "")',")
            sql.append("'\(item.url ?? "")',")
            sql.append("'\(item.hdurl ?? "")',")
            sql.append("'\(item.copyright ?? "")'),")
        }
        sql.removeLast()

        do {
            try worker.save(query: sql)
        } catch {
            print(error.localizedDescription)
        }
    }

    public func saveItems(_ items: [ApodStorage]) throws {
        items.forEach { [weak self] (item: ApodStorage) in
            do {
                try self?.worker.save(item: item)
            } catch {
                print(error.localizedDescription)
            }
        }
    }

    public func asyncSaveItem(_ item: ApodStorage) async throws {
        do {
            try await worker.asyncSave(item: item)
        } catch {
            print(error.localizedDescription)
        }
    }
    
    public func getAllItems() throws -> [ApodStorage]? {
        try worker.getAll()
    }
    
    // MARK: - Methods - Private
    private func createTable() {
        guard let dbQueue: DatabaseQueue = worker.dbQueue else { return }
        try? dbQueue.write { db in
            try db.create(table: "ApodStorage", options: .ifNotExists) { t in
                t.column("id", .text).primaryKey()
                t.column("date", .text)
                t.column("postedDate", .date)
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
