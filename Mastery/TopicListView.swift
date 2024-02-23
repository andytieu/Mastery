//
//  CardListView.swift
//  Mastery
//
//  Created by Andy Tieu on 11/30/23.
//

import SwiftUI
import SwiftData

struct TopicSheetView: View {
    public let onFinishEditing: OnFinishEditing
    @State public var topicName = ""
    public var callback: ((Topic) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    
    enum OnFinishEditing {
        case addTopic(to: Deck)
        case editTopic(_ topic: Topic)
        
        func getTitle() -> String {
            switch self {
            case .addTopic(_):
                "Add Topic"
            case .editTopic(_):
                "Edit Topic"
            }
        }
    }
    
    private func confirmTopicSheet() {
        switch onFinishEditing {
        case .addTopic(let deck):
            let newTopic = Topic(name: topicName)
            deck.topics.append(newTopic)
            if let callback {
                callback(newTopic)
            }
        case .editTopic(let topic):
            topic.name = topicName
        }
    }
    
    private func canCreateTopic() -> Bool {
        return topicName.trimmingCharacters(in: .whitespaces).count > 0
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                Spacer()
                Text(onFinishEditing.getTitle())
                    .bold()
                Spacer()
                Button("Done") {
                    confirmTopicSheet()
                    dismiss()
                }
                .disabled(!canCreateTopic())
            }
            .padding(.bottom)
            
            Text("Name")
                .font(.headline)
            TextField("Topic Name", text: $topicName)
                .onChange(of: topicName) {
                    let TOPIC_NAME_MAX_LENGTH = 40
                    topicName = String(topicName.prefix(TOPIC_NAME_MAX_LENGTH))
                }
                .textFieldStyle(StandardTextFieldStyle())
            
            Spacer()
        }
        .padding()
    }
}

struct CardMoveView: View {
    @State public var selectedDeck: Deck
    @State public var selectedTopic: Topic
    public let cards: [Card]
    @Binding public var isShowingMoveCardSheet: Bool
    @Query var decks: [Deck]
    
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
            
            Text("Move Card" + (cards.count == 1 ? "" : "s"))
                .font(.largeTitle)
                .bold()
                .padding(.bottom)
            
            Text("Deck")
                .foregroundStyle(.gray)
                .font(.title3)
                .bold()
            Menu {
                Picker("", selection: $selectedDeck) {
                    ForEach(decks, id: \.self) {deck in
                        Text("\(deck.name)")
                    }
                }
                .onChange(of: selectedDeck) {
                    selectedTopic = selectedDeck.topics[0] // TODO: implement safe index just to make sure.
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
                    ForEach(selectedDeck.topics, id: \.self) {topic in
                        Text("\(topic.name)")
                    }
                }
            } label: {
                getMenuLabel(selectedTopic.name)
            }

            Spacer()
            Button(action: {}, label: {
                Text("Confirm")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            })
        }
        .padding()
    }
}

struct TopicListView: View {
    public var deck: Deck
    @State public var currentTopic: Topic
    
    @State private var isAddingTopic = false
    @State private var isEditingTopic = false
    @State private var isDeletingTopic = false
    @Environment(\.modelContext) private var modelContext
    
    @State private var isShowingCardSelectionDialog = false
    @State private var isShowingMoveCardSheet = false
    @State private var selectedCards = [Card]()
    @Query private var decks: [Deck]
    
    func deleteCurrentTopic() {
        if let index = deck.topics.firstIndex(where: {$0.id == currentTopic.id}) {
            deck.topics.remove(at: index)
            modelContext.delete(currentTopic) // Needed because of a weird bug where deleting the topic from deck.topics will occasionally not update persistent data.
            currentTopic = deck.getRecentlyAddedTopic()
        }
    }
    
    private func makeTopicSelector() -> some View {
        HStack {
            Menu {
                Button(action: {
                    isAddingTopic = true
                }) {
                    Label("New Topic", systemImage: "plus")
                }
                
                Button(action: {
                    isEditingTopic = true
                }) {
                    Label("Edit Topic", systemImage: "pencil")
                }
                
                if deck.topics.count > 1 {
                    Button(action: {
                        isDeletingTopic = true
                    }) {
                        Label("Delete Topic", systemImage: "trash")
                    }
                }
            } label: {
                Button(action: {}) {
                    Image(systemName: "ellipsis.circle")
                        .font(.title2)
                }
            }
            
            Menu { // Replace menu with sheet of list of topics that are rearrangable
                let sortedTopics = deck.topics.sorted {$0.timestamp > $1.timestamp}
                Picker("", selection: $currentTopic) {
                    ForEach(sortedTopics, id: \.self) {topic in
                        Text("\(topic.name)")
                    }
                }
                .onChange(of: currentTopic) {
                    selectedCards.removeAll()
                }
            } label: {
                Text("\(currentTopic.name)")
                    .font(.title3)
                    .bold()
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
    }
    
    private func makeBottomBar() -> some View {
        HStack {
            Spacer()
            if currentTopic.cards.count > 0 {
                NavigationLink(destination: StudyTopicView(cards: currentTopic.cards)) {
                    VStack(spacing: 5) {
                        Image(systemName: "rectangle.fill.on.rectangle.angled.fill")
                            .font(.title)
                        Text("Study Topic")
                            .foregroundStyle(.appLabel)
                            .bold()
                    }
                }
                Spacer()
            }
            NavigationLink(destination: CardEditView(onFinishEditing: .addCard(to: currentTopic))) {
                VStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title)
                    Text("Add Cards")
                        .foregroundStyle(.appLabel)
                        .bold()
                }
            }
            Spacer()
        }
        .padding(.top)
        .background(.background)
    }
    
    private func makeImageView(data: Data?) -> some View {
        ZStack {
            if let data, let uiImage = UIImage(data: data) {
                Button(action: {
                    
                }) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 50, height: 50)
                        .clipped()
                        .contentShape(Rectangle())
                }
            }
        }
    }
    
    private func makeCardList() -> some View {
        func makeCard(_ card: Card) -> some View {
            Button(action: {
                if let index = selectedCards.firstIndex(where: { $0.id == card.id }) {
                    selectedCards.remove(at: index)
                } else {
                    selectedCards.append(card)
                }
            }) {
                VStack(alignment: .leading) {
                    Text("Front")
                        .font(.headline)
                        .foregroundStyle(.gray)
                    makeImageView(data: card.front.image)
                    Text(card.front.text)
                        .multilineTextAlignment(.leading)
                    
                    Text("Back")
                        .font(.headline)
                        .foregroundStyle(.gray)
                        .padding(.top, 5)
                    makeImageView(data: card.back.image)
                    Text(card.back.text)
                        .multilineTextAlignment(.leading)
                }
                .foregroundStyle(.appLabel)
            }
            .swipeActions(allowsFullSwipe: false) {
                Button(action: {
                    if let index = currentTopic.cards.firstIndex(where: { $0.id == card.id }) {
                        currentTopic.cards.remove(at: index)
                        modelContext.delete(card)
                    }
                }) {
                    Image(systemName: "trash")
                        .tint(.red)
                }
                
                let cardEditView = CardEditView(
                    onFinishEditing: .editCard(front: card.front, back: card.back),
                    frontText: card.front.text,
                    backText: card.back.text,
                    frontImageData: card.front.image,
                    backImageData: card.back.image
                )
                NavigationLink(destination: cardEditView) {
                    Image(systemName: "pencil")
                }
            }
        }
        
        return List {
            ForEach(currentTopic.cards.sorted{$0.timestamp < $1.timestamp}) {card in
                let isSelected = selectedCards.contains(where: {$0.id == card.id})
                makeCard(card)
                    .listRowBackground(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color(uiColor: isSelected ? .systemGray2 : .clear), lineWidth: 2)
                            .background(Color(uiColor: .secondarySystemBackground))
                    )
            }
        }
        .listRowSpacing(20)
        .scrollContentBackground(.hidden)
    }
    
    var body: some View {
        VStack {
            VStack(alignment: .leading) {
                Text("\(deck.name)")
                    .font(.title2)
                    .bold()
                makeTopicSelector()
                    .padding(.bottom)
            }
            .padding(.horizontal)
            makeCardList()
            makeBottomBar()
        }
        .onDisappear {
            selectedCards.removeAll()
        }
        .toolbar {
            if selectedCards.count > 0 {
                Button(action: {
                    isShowingCardSelectionDialog = true
                }) {
                    Image(systemName: "square.and.pencil")
                        .foregroundStyle(.appLabel)
                        .bold()
                }
            }
        }
        .confirmationDialog("", isPresented: $isShowingCardSelectionDialog) {
            let cardsInfo = "\(selectedCards.count)" + " Card" + (selectedCards.count == 1 ? "" : "s")
            Button("Move \(cardsInfo)") {
                isShowingMoveCardSheet = true
            }
        }
        .sheet(isPresented: $isAddingTopic) {
            TopicSheetView(onFinishEditing: .addTopic(to: deck)) { newTopic in
                currentTopic = newTopic
            }
        }
        .sheet(isPresented: $isEditingTopic) {
            TopicSheetView(
                onFinishEditing: .editTopic(currentTopic),
                topicName: currentTopic.name
            )
        }
        .sheet(isPresented: $isShowingMoveCardSheet) {
            // We pass a copy of the selected cards so we can clear the actual array of selected cards to update the card list view.
            CardMoveView(
                selectedDeck: deck,
                selectedTopic: currentTopic,
                cards: selectedCards,
                isShowingMoveCardSheet: $isShowingMoveCardSheet
            )
        }
        .alert("Are you sure you want to delete \(currentTopic.name)?", isPresented: $isDeletingTopic) {
            Button("Delete", role: .destructive, action: deleteCurrentTopic)
        }
        .padding(.top)
    }
}

#Preview("Light") {
    DeckListView()
        .modelContainer(PreviewHandler.previewContainer)
}

#Preview("Dark") {
    DeckListView()
        .preferredColorScheme(.dark)
        .modelContainer(PreviewHandler.previewContainer)
}
