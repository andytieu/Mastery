//
//  Deck.swift
//  Mastery
//
//  Created by Andy Tieu on 11/21/23.
//

import SwiftUI
import SwiftData

@Model
final class Deck {
    public var name: String
    public var colorIndex: Int
    @Attribute(.externalStorage) public var image: Data?
    public var order: Int // Save the order in which Decks are displayed.
    
    @Relationship(deleteRule: .cascade) public var topics = [Topic]()
    
    init(name: String, colorIndex: Int, image: Data?, order: Int) {
        self.name = name
        self.colorIndex = colorIndex
        self.image = image
        self.order = order
    }
}

@Model
final class Topic {
    public var name: String
    public var order: Int // Save the order in which Topics are displayed.
    
    init(name: String, order: Int) {
        self.name = name
        self.order = order
    }
}
