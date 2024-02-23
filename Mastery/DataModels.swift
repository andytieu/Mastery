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
    
    @Relationship(deleteRule: .cascade) public var topics: [Topic]
    
    init(name: String, colorIndex: Int, image: Data?, order: Int, topics: [Topic] = [Topic(name: "Topic")]) {
        self.name = name
        self.colorIndex = colorIndex
        self.image = image
        self.order = order
        self.topics = topics
    }
    
    public func getRecentlyAddedTopic() -> Topic {
        return topics.sorted {$0.timestamp > $1.timestamp}.first!
    }
}

@Model
final class Topic {
    public var name: String
    public let timestamp = Date.now
    
    @Relationship(deleteRule: .cascade) public var cards = [Card]()
    
    init(name: String, cards: [Card] = []) {
        self.name = name
        self.cards = cards
    }
}

@Model
final class Card {
    @Relationship(deleteRule: .cascade) public var front: CardSide
    @Relationship(deleteRule: .cascade) public var back: CardSide
    public let timestamp = Date.now
    
    init(front: CardSide, back: CardSide) {
        self.front = front
        self.back = back
    }
}

@Model
final class CardSide {
    public var text: String
    public var image: Data?
    
    init(text: String, image: Data?) {
        self.text = text
        self.image = image
    }
}
