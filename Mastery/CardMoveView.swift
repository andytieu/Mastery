//
//  CardMoveView.swift
//  Mastery
//
//  Created by Andy Tieu on 2/23/24.
//

import SwiftUI
import SwiftData

struct CardMoveView: View {
    @State public var selectedDeck: Deck
    @State public var selectedTopic: Topic
    @Binding public var cards: [Card]
    @Binding public var isShowingMoveCardSheet: Bool
    
    @Query var decks: [Deck]
    private let topicContainingCards: Topic
    @Environment(\.dismiss) var dismiss
    
    init(selectedDeck: Deck, selectedTopic: Topic, cards: Binding<[Card]>, isShowingMoveCardSheet: Binding<Bool>) {
        _selectedDeck = State(initialValue: selectedDeck)
        _selectedTopic = State(initialValue: selectedTopic)
        _isShowingMoveCardSheet = isShowingMoveCardSheet
        _cards = cards
        self.topicContainingCards = selectedTopic // Store the topic that holds the cards
    }
    
    func getMenuLabel(_ text: String) -> some View {
        Button(action: {}) { // we're using an action-less button so we can apply a button style.
            HStack {
                Text(text)
                Image(systemName: "chevron.down")
                    .font(.footnote)
            }
        }
        .buttonStyle(StandardButtonStyle())
        .padding(.bottom)
    }
    
    func moveCards() {
        topicContainingCards.cards.removeAll { card1 in
            cards.contains { card2 in
                card1.id == card2.id
            }
        }
        
        selectedTopic.cards.append(contentsOf: cards)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button(action: {
                    isShowingMoveCardSheet = false
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundStyle(.appLabel)
                        .font(.title2)
                        .bold()
                }
                Spacer()
            }
            .padding(.bottom)
            
            Text("Move Cards")
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
            
            Text("Deck")
                .foregroundStyle(.gray)
                .font(.title3)
                .bold()
            Menu {
                Picker("", selection: $selectedDeck) {
                    ForEach(decks.sorted {$0.order > $1.order}, id: \.self) {deck in
                        Text("\(deck.name)")
                    }
                }
                .onChange(of: selectedDeck) {
                    selectedTopic = selectedDeck.topics[0] // Safe to assume atleast 1 topic exists for each deck.
                }
            } label: {
                getMenuLabel(selectedDeck.name)
            }

            Text("Topic")
                .foregroundStyle(.gray)
                .font(.title3)
                .bold()
            Menu {
                Picker("", selection: $selectedTopic) {
                    ForEach(selectedDeck.topics.sorted {$0.timestamp > $1.timestamp}, id: \.self) {topic in
                        Text("\(topic.name)")
                    }
                }
            } label: {
                getMenuLabel(selectedTopic.name)
            }

            Spacer()
            Button(action: {
                moveCards()
                dismiss()
                cards.removeAll()
            }) {
                Text("Confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
    }
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
