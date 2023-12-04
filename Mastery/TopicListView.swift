//
//  CardListView.swift
//  Mastery
//
//  Created by Andy Tieu on 11/30/23.
//

import SwiftUI
import SwiftData

// TODO: implement searching, test reordering, app-wide QA test.

struct TopicAlertView: View {
    @State public var topicAlertAction: TopicAlertAction
    @State public var topicName = ""
    
    enum TopicAlertAction {
        case addTopic(to: Deck)
        case editTopic(_ topic: Topic)
    }
    
    func normalizeTopicName() -> String {
        // Disabling the confirm button in the alert gives us weird behavior, so this will do for now.
        let isValidName = topicName.trimmingCharacters(in: .whitespaces).count != 0
        return isValidName ? topicName : "Cards"
    }
    
    func confirmTopicAlert() {
        let normalized_topic_name = normalizeTopicName()
        
        switch topicAlertAction {
        case .addTopic(let deck):
            let topic = Topic(name: normalized_topic_name, order: deck.topics.count)
            deck.topics.append(topic)
            topicName = ""
        case .editTopic(let topic):
            topic.name = normalized_topic_name
            topicName = normalized_topic_name
        }
    }
    
    var body: some View {
        ZStack {
            TextField("Name", text: $topicName)
            
            Button("Cancel", action: {
                switch topicAlertAction {
                case .addTopic(_):
                    topicName = ""
                case .editTopic(let topic):
                    topicName = topic.name // We can always assume that topic.name is normalized.
                }
            })
            Button("Confirm", action: {
                confirmTopicAlert()
                topicName = "" // Breaks the character limit code for some reason..
            })
        }
    }
}

struct TopicView: View {
    public var deck: Deck
    public var topic: Topic
    
    @State private var isDeleteAlertPresented = false
    @State private var isEditingTopic = false
    @Environment(\.modelContext) private var modelContext
    
    func deleteTopic(_ topic: Topic) {
        if let index = deck.topics.firstIndex(where: {$0.id == topic.id}) {
            deck.topics.remove(at: index)
            modelContext.delete(topic) // Needed because of a weird bug where deleting the topic from deck.topics will occasionally not update persistent data.
            
            let sortedTopics = deck.topics.sorted {$0.order > $1.order}
            for (i, topic) in sortedTopics.enumerated() {
                topic.order = (sortedTopics.count-1) - i
            } // Update the orders of all of topics in relation to the deletion.
        }
    }
    
    var body: some View {
        NavigationLink(destination: Text("Buh")) {
            Text("\(topic.name)")
                .foregroundStyle(Color(uiColor: .label))
        }
        .listRowBackground(Color(uiColor: .secondarySystemBackground))
        .padding(.vertical)
        .swipeActions(allowsFullSwipe: false) {
            Button(action: {
                isDeleteAlertPresented = true
            }) {
                Image(systemName: "trash")
            }
            .tint(.red)
            
            Button(action: {
                isEditingTopic = true
            }) {
                Image(systemName: "gearshape.fill")
            }
        }
        .alert("Are you sure you want to delete? \(topic.name)", isPresented: $isDeleteAlertPresented) {
            Button("Delete", role: .destructive, action: {
                deleteTopic(topic)
            })
        }
        .alert("Edit \(topic.name)", isPresented: $isEditingTopic) {
            TopicAlertView(topicAlertAction: .editTopic(topic), topicName: topic.name)
        }
    }
}

struct TopicListView: View {
    public var deck: Deck
    
    @State private var isAddingTopic = false
    
    var body: some View {
        VStack(alignment: .leading) {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    Text("\(deck.name)")
                        .font(.title2)
                        .bold()
                        .padding(.leading, 20)
                        .padding(.vertical)
                    
                    List {
                        var sortedTopics = deck.topics.sorted {$0.order > $1.order}
                        ForEach(sortedTopics) {topic in
                            TopicView(deck: deck, topic: topic)
                        }
                        .onMove(perform: { indices, newOffset in
                            sortedTopics.move(fromOffsets: indices, toOffset: newOffset)

                            for (i, topic) in sortedTopics.enumerated() {
                                topic.order = (sortedTopics.count-1) - i
                            } // Update the orders of all topics in relation to the move.
                        })
                    }
                    .listRowSpacing(10)
                    .scrollContentBackground(.hidden)
                }
                
                VStack {
                    Spacer()
                    Button(action: {
                        isAddingTopic = true
                    }) {
                        Label("Add Topic", systemImage: "plus")
                            .bold()
                            .padding()
                            .foregroundStyle(.white)
                            .background(Color.accentColor)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .shadow(radius: 4, y: 4)
                    }
                }
                .ignoresSafeArea(.keyboard)
            }
        }
        .navigationTitle("Topics")
        .alert("Add Topic", isPresented: $isAddingTopic) {
            TopicAlertView(topicAlertAction: .addTopic(to: deck))
        }
    }
}

// TODO: better testing
#Preview("Light") {
    ContentView()
        .modelContainer(for: Deck.self, inMemory: true)
}
