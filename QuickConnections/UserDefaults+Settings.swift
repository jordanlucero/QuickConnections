//
//  UserDefaults+Settings.swift
//  QuickConnections
//
//  Created by Jordan Lucero on 6/11/25.
//

import Foundation

extension UserDefaults {
    private enum Keys {
        static let generationCount = "generationCount"
    }
    
    var generationCount: Int {
        get {
            let count = integer(forKey: Keys.generationCount)
            // Return default of 5 if no value set yet
            return count == 0 ? 5 : count
        }
        set {
            // Clamp value between 3 and 10
            let clampedValue = max(3, min(10, newValue))
            set(clampedValue, forKey: Keys.generationCount)
        }
    }
}