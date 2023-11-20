//
//  Item.swift
//  Mastery
//
//  Created by Andy Tieu on 11/19/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
