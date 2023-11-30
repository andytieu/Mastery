//
//  DeckView.swift
//  Mastery
//
//  Created by Andy Tieu on 11/19/23.
//

import SwiftUI

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
                    .opacity(DECK_COLORS[colorIndex] == .clear ? 1: 0.3)
                // isColorClear(index) exists as a method of DeckCustomizeView but refactoring this out is a little unnecessary for now.
            }
        }
    }
}

struct DeckView: View {
    public var deck: Deck
    @Environment(\.modelContext) var modelContext
    @State private var isDeckDeleteAlertPresented = false
    
    init(deck: Deck) {
        self.deck = deck
        if deck.colorIndex >= DECK_COLORS.count {
            // Could be out of bounds if colors are removed from DECK_COLORS in the future.
            deck.colorIndex = 1
        }
    }
    
    var body: some View {
        let nameOverlay = Rectangle()
            .foregroundStyle(.background.secondary)
            .overlay {
                HStack {
                    Spacer()
                    Text(deck.name)
                }
                .padding()
            }
        
        let cardsDueOverlay = HStack {
            Spacer()
            
            Image(systemName: "rectangle.portrait.on.rectangle.portrait.angled.fill")
                .foregroundStyle(.white)
            Text("0 Due")
                .bold()
                .foregroundStyle(.white)
                .padding(.trailing)
        }
        .padding(.top)
        
        VStack {
            cardsDueOverlay
            
            nameOverlay
                .padding(.top, 50)
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
                isDeckDeleteAlertPresented = true
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
                Image(systemName: "gearshape")
            }
        }
        .alert("Are you sure you want to delete \(deck.name)?", isPresented: $isDeckDeleteAlertPresented) {
            Button("Delete", role: .destructive) {
                withAnimation {
                    modelContext.delete(deck)
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
