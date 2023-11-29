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
    .clear, .gray, .pink, .red, .brown, .orange, .yellow, .green, .teal, .blue, .indigo
]

let PRESET_DECK_IMAGES: [ImageResource] = [
    .math, .geometry, .biology, .chemistry, .genetics, .astronomy, .engineering, .circuits, .physics
]

let DECK_NAME_MAX_LENGTH = 40

struct DeckCustomizeView: View {
    @State public var name: String = ""
    @State public var colorIndex: Int = 1
    @State public var imageData: Data? {
        didSet {
            // If the user has the default color overlay and no current image then they probably don't want to see a color overlay yet.
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
    
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @FocusState var nameFieldFocused
    
    enum OnFinishCustomizing: Hashable {
        case makeDeck
        case changeDeck(_ deck: Deck)
    }
    
    private func finishCustomizing() {
        dismiss()
        switch onFinishCustomizing {
        case .makeDeck:
            let deck = Deck(name: name, colorIndex: colorIndex, image: imageData)
            modelContext.insert(deck)
        
        case .changeDeck(let deck):
            deck.name = name
            deck.colorIndex = colorIndex
            deck.image = imageData
        }
    }
    
    private func isColorClear(_ index: Int) -> Bool {
        DECK_COLORS[index] == .clear
    }
    
    private func clearImage() {
        withAnimation {
            photoItem = nil
            imageData = nil
            if isColorClear(colorIndex) {
                colorIndex = 1
            }
        }
    }
    
    private func asyncloadPhotoToData() {
        Task {
            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                withAnimation {
                    photoItem = nil // Deselect the photo in the PhotosPicker.
                    imageData = data
                }
            }
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
    
    private func isFormIncomplete() -> Bool {
        name.trimmingCharacters(in: .whitespaces).count == 0
    }
    
    private func makeColorSelector() -> some View {
        func makeColorButton(index: Int) -> some View {
            Button(action: {
                colorIndex = index
            }) {
                Circle()
                    .stroke(Color.primary, lineWidth: isColorClear(index) ? 2 : 0)
                    .fill(DECK_COLORS[index])
                    .frame(height: 50)
                    .overlay {
                        if index == colorIndex {
                            Image(systemName: "checkmark")
                                .bold()
                                .foregroundStyle(isColorClear(index) ? Color.primary : Color.white)
                        }
                    }
            }
        }
        
        return HStack(spacing: 0) {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(0..<DECK_COLORS.count, id: \.self) {i in
                        if !(image == nil && isColorClear(i)) { // Hide the clear color option when there is no image, decks must have a color or an image (or both).
                            makeColorButton(index: i)
                        }
                    }
                }
                .padding()
            }
            
            Rectangle() // Helps indicate that this is a scrollable view (flashScrollIndicators is broken for some reason so this will do).
                .frame(width: 20)
                .shadow(color: .primary, radius: 5, x: -6)

                .colorInvert()
        }
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
    
    private func makeImageSelector() -> some View {
        Group {
            // Buttons
            HStack {
                Spacer()
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Label("Your Photos", systemImage: "camera.fill")
                        .foregroundStyle(.foreground)
                        .bold()
                }
                
                Spacer();Divider(); Spacer()
                
                Button(action: {
                    isPresetPhotosPresented = true
                }) {
                    Label("Presets", systemImage: "photo.on.rectangle.angled")
                        .foregroundStyle(.foreground)
                        .bold()
                }
                Spacer()
                
                if (image != nil) {
                    Divider()
                    Spacer()
                    Button(action: clearImage) {
                        Image(systemName: "trash")
                            .bold()
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            
            // Image
            DeckImageOverlay(colorIndex: colorIndex, imageData: imageData)
                .frame(height: 200)
        }
        .onChange(of: photoItem, asyncloadPhotoToData)
    }
    
    private func makePresetPhotosSheet() -> some View {
        VStack(alignment: .leading) {
            Button(action: {
                isPresetPhotosPresented = false
            }) {
                Text("Cancel")
            }
            .padding(.bottom)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], content: {
                    ForEach(PRESET_DECK_IMAGES, id: \.self) {resource in
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
                        .buttonStyle(.plain)
                    }
                })
            }
        }
        .padding()
    }
    
    var body: some View {
        Form {
            Section("Name") {
                TextField(text: $name) {
                    Text("Math, Biology, etc.")
                }
                .focused($nameFieldFocused)
                .onAppear(perform: {
                    nameFieldFocused = name.isEmpty
                })
                .onChange(of: name, {
                    name = String(name.prefix(DECK_NAME_MAX_LENGTH))
                })
                .padding()
            }
            .listRowInsets(EdgeInsets())
            
            Section("Color") {
                makeColorSelector()
            }
            .listRowInsets(EdgeInsets())
            
            Section("Image") {
                // Your options are: No image, Select from a set of preset images, select from camera roll.
                makeImageSelector()
            }
            .listRowInsets(EdgeInsets())
        }
        .navigationTitle(getNavigationTitle())
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(content: makeToolbarContent)
        .sheet(isPresented: $isPresetPhotosPresented, content: makePresetPhotosSheet)
    }
}

#Preview("Light") {
    DeckCustomizeView(onFinishCustomizing: .makeDeck)
}

#Preview("Dark") {
    DeckCustomizeView(onFinishCustomizing: .makeDeck)
        .preferredColorScheme(.dark)
}
