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
    private let worker: LocalStorageClient<ApodStorage> = LocalStorageClient<ApodStorage>()

    // MARK: - Public
    @Published public var items: [ApodStorage]?
    //@Published public var currentMonth: TimelineMonth = TimelineMonth.currentMonth
    
    // MARK: - Init
    public init() {
    }
    
    //MARK: - Methods
    
    func saveItems(_ items: [ApodStorage]) {
        items.forEach { [weak self] (item: ApodStorage) in
            try? self?.worker.save(item: item)
        }
    }
    
    func observeApods(startDate: Date?, endDate: Date?) {
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
}
