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
    .math, .geometry, .biology, .chemistry, .genetics, .astronomy, .engineering, .circuits, .physics
]

struct StandardTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<_Label>) -> some View {
        ZStack {
            configuration
                .padding(10)
                .overlay {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color(uiColor: .systemGray3), lineWidth: 1)
                }
        }
    }
}

struct StandardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
        .bold()
        .frame(height: 35)
        .padding(.horizontal, 10)
        .foregroundStyle(.white)
        .background(Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct DeckCustomizeView: View {
    @State public var name: String = ""
    @State public var colorIndex: Int = 1
    @State public var imageData: Data? {
        didSet {
            // If the user selected their first image then they probably don't want to see a color overlay yet.
            if oldValue == nil && imageData != nil {
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
            "Create Deck"
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
        return HStack {
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
            Button("Cancel", action: {
                isPresetPhotosPresented = false
            })
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
        TextField(text: $name) {
            Text("English, Math, etc.")
        }
        .focused($nameFieldFocused)
        .onAppear(perform: {
            nameFieldFocused = name.isEmpty
        })
        .onChange(of: name) {
            let DECK_NAME_MAX_LENGTH = 40
            name = String(name.prefix(DECK_NAME_MAX_LENGTH))
        }
        .textFieldStyle(StandardTextFieldStyle())
    }
    
    func makeDeckOverlayPreview() -> some View {
        ZStack {
            if image != nil {
                DeckOverlayView(colorIndex: colorIndex, imageData: imageData)
                    .frame(height: 200)
                    .clipped()
                    .contentShape(Rectangle())
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                Text("Name")
                    .font(.headline)
                makeNameTextField()
                    .padding(.bottom)
                
                Text("Color")
                    .font(.headline)
                makeColorSelector()
                    .padding(.bottom)
                
                Text("Image")
                    .font(.headline)
                makeImageSelector()
                    .padding(.bottom, 4)
                makeDeckOverlayPreview()
                
                Spacer()
            }
            .padding(.horizontal)
        }
        .padding(.top)
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
