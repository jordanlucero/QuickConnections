//
//  Item.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/10/25.
//

// Boilerplate, not needed.

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
