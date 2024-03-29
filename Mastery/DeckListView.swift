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
    }
    
    private func makeToolbarContent() -> some ToolbarContent {
        Group {
            if isSearching {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: stopSearching) {
                        Image(systemName: "arrow.left")
                            .foregroundStyle(.appLabel)
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
                            .foregroundStyle(.appLabel)
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
                    .font(.title)
                    .bold()
                    .padding(.horizontal, 50)
            } else {
                if filterDecksFromSearch().isEmpty {
                    Text("No Search Results")
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

@MainActor
class PreviewHandler {
    static let previewContainer: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Deck.self, configurations: config)
            
            let modelDeck = Deck(name: "Astronomy", colorIndex: 0, image: UIImage(resource: .astronomy).pngData(), order: 0)
            
            container.mainContext.insert(modelDeck)
            
            return container
        } catch {
            fatalError("Failed to create model container for previewing: \(error.localizedDescription)")
        }
    }()
}

#Preview("Light") {
    return DeckListView()
        .modelContainer(PreviewHandler.previewContainer)
}

#Preview("Dark") {
    return DeckListView()
        .preferredColorScheme(.dark)
        .modelContainer(PreviewHandler.previewContainer)
}
