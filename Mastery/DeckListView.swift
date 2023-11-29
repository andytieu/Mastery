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
            .foregroundStyle(Color.accentColor)
            .background(.background.tertiary)
            .clipShape(Circle())
            .shadow(radius: 4, y: 4)
    }
    
    private func makeDeckListOrPlaceholder() -> some View {
        ZStack {
            if decks.isEmpty {
                Text("Create a Deck")
                    .foregroundStyle(.gray)
                    .bold()
            } else {
                if filterDecksFromSearch().isEmpty {
                    Text("No Search Results")
                        .foregroundStyle(.gray)
                        .bold()
                } else {
                    List {
                        ForEach(filterDecksFromSearch()) {deck in
                            DeckView(deck: deck)
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .listSectionSpacing(.compact)
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                makeDeckListOrPlaceholder()
                Spacer()
                HStack {
                    NavigationLink(
                        destination: DeckCustomizeView(onFinishCustomizing: .makeDeck),
                        label: makeFloatingButton
                    )
                    .buttonStyle(.plain)
                    .padding(.leading)
                    Spacer()
                }
            }
            .navigationDestination(for: Deck.self) { deck in
                Text("\(deck.name)")
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
