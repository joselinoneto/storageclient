//
//  File.swift
//  
//
//  Created by José Neto on 03/03/2023.
//

import Foundation

extension String {
    var noQuote: String {
        self.replacingOccurrences(of: "'", with: "")
    }
}
