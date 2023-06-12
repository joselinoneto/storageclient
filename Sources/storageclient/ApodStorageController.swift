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
import tools

public class ApodStorageController {
    // MARK: - Private
    private var cancellables: Set<AnyCancellable> = []
    private let worker: LocalStorageClient<ApodStorage>
    private let insertSql: String = "INSERT INTO APODSTORAGE (id, date, postedDate, explanation, mediaType, thumbnailUrl, title, url, hdurl, copyright, isfavorite) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"

    // MARK: - Public
    @Published public var items: [ApodStorage]?
    
    // MARK: - Init
    public init(inMemory: Bool = false) {
        let dbFile: String? = inMemory ? nil : "\(FileStorage.shared.folderUrl?.absoluteString ?? "")/apod.sqlite"
        worker = LocalStorageClient<ApodStorage>(pathToSqlite: dbFile)
        createTable()
        worker.valueObservation()

        worker
            .$items
            .assign(to: \.items, on: self)
            .store(in: &cancellables)
    }

    deinit {
        worker.cancelObservation()
    }
    
    //MARK: - Methods - Public
    public func saveItems(_ items: [ApodStorage]) async throws {
        try await worker.saveItems(items)
    }

    public func saveItemSql(_ item: ApodStorage) async throws {
        if let id = item.id, try getApod(id: id) == nil {
            try await saveSqlBatch(sql: insertSql,
                                   arguments: [item.id?.uuidString,
                                               item.date,
                                               item.postedDate?.databaseValue,
                                               item.explanation?.noQuote,
                                               item.mediaType,
                                               item.thumbnailUrl,
                                               item.title?.noQuote,
                                               item.url,
                                               item.hdurl,
                                               item.copyright?.noQuote,
                                               item.isFavorite])
        }
    }

    private func saveSqlBatch(sql: String, arguments: StatementArguments) async throws {
        try? await worker.save(query: sql, arguments: arguments)
    }

    public func saveItems(_ items: [ApodStorage]) throws {
        items.forEach { [weak self] (item: ApodStorage) in
            try? self?.worker.save(item: item)
        }
    }

    public func asyncSaveItem(_ item: ApodStorage) async throws {
        try? await worker.asyncSave(item: item)
    }

    public func searchApods(startMonth: String?, endMonth: String?) throws -> [ApodStorage]? {
        try worker.dbQueue?.read({ db in
            try ApodStorage
                .filter(Column("date") >= startMonth && Column("date") <= endMonth)
                .fetchAll(db)
        })
    }

    public func searchApods(_ text: String) throws -> [ApodStorage]? {
        try worker.dbQueue?.read({ db in
            try ApodStorage
                .filter(Column("title").like("%\(text)%"))
                .filter(Column("explanation").like("%\(text)%"))
                .fetchAll(db)
        })
    }

    public func searchFavorites() throws -> [ApodStorage]? {
        try worker.dbQueue?.read({ db in
            try ApodStorage
                .order(Column("postedDate").desc)
                .filter(Column("isfavorite") == true)
                .fetchAll(db)
        })
    }
    
    public func getApod(id: UUID) throws -> ApodStorage? {
        try? worker.get(key: id)
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
                t.column("postedDate", .datetime)
                t.column("explanation", .text)
                t.column("mediaType", .text)
                t.column("thumbnailUrl", .text)
                t.column("title", .text)
                t.column("url", .text)
                t.column("hdurl", .text)
                t.column("copyright", .text)
                t.column("isfavorite", .boolean).notNull().defaults(to: false)
            }
        }
    }
}
