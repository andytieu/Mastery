//
//  DeckCustomizeView.swift
//  Mastery
//
//  Created by Andy Tieu on 11/21/23.
//

import SwiftUI
import PhotosUI
import SwiftData

let DECK_COLORS: [Color] = [
    .clear, .gray, .pink, .red, .brown, .orange, .yellow, .green, .teal, .blue, .indigo, .purple
]

let PRESET_DECK_IMAGES: [ImageResource] = [
    .math, .geometry, .biology, .chemistry, .astronomy, .engineering, .physics, .computerEngineering, .history
]

private let DECK_NAME_LIMIT = 40

struct DeckCustomizeView: View {
    @State public var name = ""
    @State public var colorIndex = 1
    @State public var imageData: Data? {
        didSet {
            // If the user selected their first image and they are on the default color overlay then they probably don't want to see a color overlay yet.
            if oldValue == nil && imageData != nil && colorIndex == 1 {
                colorIndex = 0
            }
        }
    }
    public let onFinishCustomizing: OnFinishCustomizing

    @State private var isPresetPhotosPresented = false
    @State private var photoItem: PhotosPickerItem?
    private var image: Image? {
        guard let imageData, let uiImage = UIImage(data: imageData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    
    @Query private var decks: [Deck]
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @FocusState private var nameFieldFocused
    
    enum OnFinishCustomizing {
        case makeDeck
        case changeDeck(_ deck: Deck)
    }
    
    private func finishCustomizing() {
        dismiss()
        switch onFinishCustomizing {
        case .makeDeck:
            let deck = Deck(name: name, colorIndex: colorIndex, image: imageData, order: decks.count)
            modelContext.insert(deck)
        
        case .changeDeck(let deck):
            deck.name = name
            deck.colorIndex = colorIndex
            deck.image = imageData
        }
    }
    
    private func asyncloadPhotoToData() {
        Task {
            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                photoItem = nil // Deselect the photo in the PhotosPicker.
                imageData = data
            }
        }
    }
    
    private func clearImage() {
        photoItem = nil
        imageData = nil
        if isColorClear(colorIndex) {
            colorIndex = 1
        }
    }
    
    private func selectPresetImage(_ resource: ImageResource) {
        imageData = UIImage(resource: resource).pngData()
        isPresetPhotosPresented = false
    }
    
    private func getNavigationTitle() -> String {
        switch onFinishCustomizing {
        case .makeDeck:
            "Create Your Deck"
        case .changeDeck(let deck):
            deck.name
        }
    }
    
    private func isColorClear(_ index: Int) -> Bool {
        DECK_COLORS[index] == .clear
    }
    
    private func isFormIncomplete() -> Bool {
        name.trimmingCharacters(in: .whitespaces).count == 0
    }
    
    private func makeToolbarContent() -> some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                finishCustomizing()
            }) {
                Text("Done")
                    .bold()
            }
            .disabled(isFormIncomplete())
        }
    }
    
    private func makeColorSelector() -> some View {
        let BUTTON_SIZE: Double = 50
        
        func makeColorButton(_ index: Int) -> some View {
            Button(action: {
                colorIndex = index
            }) {
                ZStack {
                    Circle()
                        .stroke(Color.primary, lineWidth: isColorClear(index) ? 1.5 : 0)
                        .fill(DECK_COLORS[index])
                        .frame(height: BUTTON_SIZE)
                        if index == colorIndex {
                            Image(systemName: "checkmark")
                                .bold()
                                .foregroundStyle(isColorClear(index) ? Color.primary : Color.white)
                        }
                }
            }
        }
        
        return ZStack {
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: BUTTON_SIZE))], spacing: 15, content: {
                ForEach(0..<DECK_COLORS.count, id: \.self) {i in
                    if !(image == nil && isColorClear(i)) { // Hide the clear color option when there is no image, decks must have a color or an image (or both).
                        makeColorButton(i)
                    }
                }
            })
            .padding()
        }
    }
    
    private func makeImageSelector() -> some View {
        return HStack(spacing: 12) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Label("Your Photos", systemImage: "camera.fill")
            }
            .onChange(of: photoItem, asyncloadPhotoToData)
            .buttonStyle(StandardButtonStyle())
            
            Button(action: {
                isPresetPhotosPresented = true
            }) {
                Label("Presets", systemImage: "photo.on.rectangle.angled")
            }
            .buttonStyle(StandardButtonStyle())
            
            Spacer()
            if image != nil {
                Button(action: clearImage) {
                    Image(systemName: "trash")
                        .foregroundStyle(.appLabel)
                        .font(.title2)
                }
            }
        }
    }
    
    private func makePresetPhotosSheet() -> some View {
        func makeImageButton(_ resource: ImageResource) -> some View {
            Button(action: {
                selectPresetImage(resource)
            }) {
                Image(resource)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
                    .clipped()
                    .aspectRatio(1, contentMode: .fit)
            }
        }
        
        return VStack(alignment: .leading) {
            Button(action: {
                isPresetPhotosPresented = false
            }) {
                Image(systemName: "arrow.left")
                    .foregroundStyle(.appLabel)
                    .font(.title3)
                    .bold()
            }
            .padding(.bottom, 8)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], content: {
                    ForEach(PRESET_DECK_IMAGES, id: \.self) {resource in
                        makeImageButton(resource)
                    }
                })
            }
        }
        .padding()
    }
    
    func makeNameTextField() -> some View {
        let textField = TextField("English, Math, etc.", text: $name)
            .focused($nameFieldFocused)
            .onAppear {
                nameFieldFocused = name.isEmpty
            }
        
        return StandardTextField(
            textField: textField,
            fieldText: $name,
            labelText: "Name",
            charLimit: DECK_NAME_LIMIT
        )
    }
    
    func makeDeckOverlay() -> some View {
        Group {
            if image != nil {
                DeckOverlayView(colorIndex: colorIndex, imageData: imageData)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 8)) // Clip the image.
                    .contentShape(Rectangle()) // Clip the hitbox.
            }
        }
    }
    
    func displayNameLimitWarning() -> some View {
        let charsLeft = DECK_NAME_LIMIT - name.count
        let CHAR_LIMIT_WARNING = 5
        return Group {
            if charsLeft <= CHAR_LIMIT_WARNING {
                Text("\(DECK_NAME_LIMIT - name.count) Left")
                    .foregroundStyle(charsLeft == 0 ? .red : .appLabel)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {

                makeNameTextField()
                    .padding([.bottom, .top])
                
                Text("Color")
                    .font(.headline)
                makeColorSelector()
                    .padding(.bottom)
                
                Text("Image")
                    .font(.headline)
                makeImageSelector()
                    .padding(.bottom, 4)
                makeDeckOverlay()
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle(getNavigationTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: makeToolbarContent)
        .sheet(isPresented: $isPresetPhotosPresented, content: makePresetPhotosSheet)
    }
}

#Preview("Light") {
    NavigationStack {
        DeckCustomizeView(onFinishCustomizing: .makeDeck)
    }
}

#Preview("Dark") {
    NavigationStack {
        DeckCustomizeView(onFinishCustomizing: .makeDeck)
            .preferredColorScheme(.dark)
    }
}
