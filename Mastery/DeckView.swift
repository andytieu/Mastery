//
//  DeckView.swift
//  Mastery
//
//  Created by Andy Tieu on 11/19/23.
//

import SwiftUI
import SwiftData

struct DeckOverlayView: View {
    public let colorIndex: Int
    public let imageData: Data?
    
    var body: some View {
        ZStack {
            DECK_COLORS[colorIndex]
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .grayscale(DECK_COLORS[colorIndex] == .clear ? 0 : 1)
                    .opacity(DECK_COLORS[colorIndex] == .clear ? 1: 0.5)
                // NOTE: isColorClear(index) exists as a method of DeckCustomizeView but refactoring this out is a little unnecessary for now.
            }
        }
    }
}

struct DeckView: View {
    public var deck: Deck
    
    @Environment(\.modelContext) var modelContext
    @State private var isDeleteAlertPresented = false
    @Query private let decks: [Deck]
    
    init(deck: Deck) {
        self.deck = deck
        if deck.colorIndex >= DECK_COLORS.count {
            // Could be out of bounds if colors are removed from DECK_COLORS in the future.
            deck.colorIndex = 1
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text(deck.name)
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.background.secondary)
        }
        .listRowBackground(DeckOverlayView(colorIndex: deck.colorIndex, imageData: deck.image))
        .background(
            NavigationLink("", value: deck)
                .opacity(0)
        )
        .frame(height: 150)
        .listRowInsets(EdgeInsets())
        .swipeActions(allowsFullSwipe: false) {
            Button(action: {
                isDeleteAlertPresented = true
            }) {
                Image(systemName: "trash")
                    .tint(.red)
            }
            
            let deckCustomizer = DeckCustomizeView(
                name: deck.name,
                colorIndex: deck.colorIndex,
                imageData: deck.image,
                onFinishCustomizing: .changeDeck(deck)
            )
            NavigationLink(destination: deckCustomizer) {
                Image(systemName: "paintbrush.pointed.fill")
            }
        }
        .alert("Are you sure you want to delete \(deck.name)?", isPresented: $isDeleteAlertPresented) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(deck)
                    
                    let sortedDecks = decks.sorted {$0.order > $1.order}
                    for (i, deck) in sortedDecks.enumerated() {
                        deck.order = (sortedDecks.count-1) - i
                    } // Update the orders of all of decks in relation to the deletion.
                }
            }
        }
    }
}

#Preview("Light") {
    ContentView()
        .modelContainer(for: Deck.self, inMemory: true)
}

#Preview("Dark") {
    ContentView()
        .modelContainer(for: Deck.self, inMemory: true)
        .preferredColorScheme(.dark)
}
