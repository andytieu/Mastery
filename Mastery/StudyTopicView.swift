//
//  StudyTopicView.swift
//  Mastery
//
//  Created by Andy Tieu on 12/30/23.
//

import SwiftUI

enum Side {
    case front, back
}

struct CardView: View {
    public let card: Card
    @Binding public var side: Side
    private var sideData: CardSide {
        switch side {
        case .front:
            card.front
        case .back:
            card.back
        }
    }
    
    func toggleSide() {
        side = side == .front ? .back : .front
    }

    var body: some View {
        Button(action: {
            toggleSide()
        }) {
            VStack {
                Spacer()
                VStack(alignment: .center) {
                    Text(sideData.text)
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(Color(uiColor: .label))
                        .rotation3DEffect(.degrees(side == .back ? 180 : 0), axis: (x: 0, y: 1, z: 0)) // Because the entire card is rotated, we need to flip the text back.
                    if let data = sideData.image, let uiImage = UIImage(data: data) {
                        makeImageFromUIImage(uiImage: uiImage)
                    }
                }
                .animation(nil, value: UUID())
                .padding()
                Spacer()
            }
            .background(.background.secondary)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .rotation3DEffect(.degrees(side == .back ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .animation(.default, value: side == .back)
        .buttonStyle(.plain)
        .padding()
    }
}

struct StudyTopicView: View {
    @State private var cardIndex: Int
    @State private var side: Side
    @State private var cards: [Card]
    
    init(cards: [Card]) {
        self.cardIndex = 0 // Guaranteed to contain atleast 1 card, since this view isn't accessible otherwise.
        self.side = .front
        self.cards = cards
    }
    
    var body: some View {
        VStack {
            CardView(card: cards[cardIndex], side: $side)
            Text("Tap card to flip.")
                .font(.headline)
            HStack {
                    Button(action: {
                        cardIndex -= 1
                        side = .front
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.title)
                            .bold()
                    }
                    .disabled(cardIndex == 0)
                Spacer()
                Button(action: {
                    cardIndex += 1
                    side = .front
                }) {
                    Image(systemName: "arrow.right")
                        .font(.title)
                        .bold()
                }
                .disabled(cardIndex == cards.count-1)
            }
            .padding()
        }
        .onAppear {
            cards.shuffle()
        }
        .padding()
    }
}
