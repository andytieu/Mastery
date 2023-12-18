//
//  DeckListView.swift
//  Mastery
//
//  Created by Andy Tieu on 11/19/23.
//

import SwiftUI
import SwiftData

struct DeckListView: View {
    
    @Query private var decks: [Deck]
    
    @State private var isSearching = false
    @State private var search = ""
    @FocusState private var searchbarFocused: Bool
    @State private var isOptionsPresented = false
    
    private func startSearching() {
        isSearching = true
        searchbarFocused = true
    }
    
    private func stopSearching() {
        isSearching = false
        searchbarFocused = false
        search = ""
    }
    
    private func filterDecksFromSearch() -> [Deck] {
        decks.filter { deck in
            deck.name.lowercased().hasPrefix(search.lowercased())
        }
        .sorted {
            $0.order > $1.order
        }
    } // TODO: improve search algorithm.
    private func makeToolbarContent() -> some ToolbarContent {
        Group {
            if isSearching {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: stopSearching) {
                        Image(systemName: "chevron.left")
                            .bold()
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    TextField("Search", text: $search)
                        .textFieldStyle(StandardTextFieldStyle())
                        .focused($searchbarFocused)
                        .onDisappear(perform: stopSearching)
                }
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: startSearching) {
                        Image(systemName: "magnifyingglass")
                            .bold()
                    }
                }
            }
        }
    }
    
    private func makeFloatingButton() -> some View {
        Image(systemName: "plus")
            .padding(25)
            .font(.title)
            .bold()
            .foregroundStyle(.white)
            .background(Color.accentColor)
            .clipShape(Circle())
            .shadow(radius: 4, y: 4)
            .padding()
    }
    
    private func makeDeckListOrPlaceholder() -> some View {
        ZStack {
            if decks.isEmpty {
                Text("Add a Deck.")
                    .foregroundStyle(.gray)
                    .font(.largeTitle)
                    .bold()
                    .padding(.horizontal, 50)
            } else {
                if filterDecksFromSearch().isEmpty {
                    Text("No Search Results")
                        .foregroundStyle(.gray)
                        .bold()
                } else {
                    var decks_copy = filterDecksFromSearch()
                    List {
                        ForEach(decks_copy) {deck in
                            DeckView(deck: deck)
                        }
                        .onMove(perform: { indices, newOffset in
                            decks_copy.move(fromOffsets: indices, toOffset: newOffset)
                            for (i, deck) in decks_copy.enumerated() {
                                deck.order = (decks_copy.count-1) - i
                            }
                        })
                        .moveDisabled(isSearching)
                    }
                    .listRowSpacing(20)
                    .scrollContentBackground(.hidden)
                }
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                makeDeckListOrPlaceholder()
                VStack {
                    Spacer()
                    HStack {
                        NavigationLink(
                            destination: DeckCustomizeView(onFinishCustomizing: .makeDeck),
                            label: makeFloatingButton
                        )
                        Spacer()
                    }
                }
            }
            .navigationDestination(for: Deck.self) { deck in
                TopicListView(deck: deck, currentTopic: deck.getRecentlyAddedTopic())
            }
            .navigationTitle("Decks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(decks.isEmpty ? .hidden : .visible, for: .navigationBar)
            .toolbar(content: makeToolbarContent)
        }
    }
}

#Preview("Light") {
    ContentView()
        .modelContainer(for: Deck.self, inMemory: true)
}

#Preview("Dark") {
    ContentView()
        .preferredColorScheme(.dark)
        .modelContainer(for: Deck.self, inMemory: true)
}
