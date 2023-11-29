//
//  Deck.swift
//  Mastery
//
//  Created by Andy Tieu on 11/21/23.
//

import SwiftUI
import SwiftData

@Model
class Deck {
    public var name: String
    public var colorIndex: Int
    @Attribute(.externalStorage) public var image: Data?
    
    init(name: String, colorIndex: Int, image: Data?) {
        self.name = name
        self.colorIndex = colorIndex
        self.image = image
    }
}
