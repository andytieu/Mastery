//
//  CardEditView.swift
//  Mastery
//
//  Created by Andy Tieu on 12/7/23.
//

import SwiftUI
import PhotosUI

func makeImageFromUIImage(uiImage: UIImage) -> some View {
    Image(uiImage: uiImage)
        .resizable()
        .scaledToFit()
        .frame(maxHeight: 300, alignment: .top)
}

struct CardEditView: View {
    public let onFinishEditing: OnFinishEditing
    @State public var frontText = ""
    @State public var backText = ""
    @State public var frontImageData: Data?
    @State public var backImageData: Data?
    
    @State private var photoItem: PhotosPickerItem?
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?

    enum OnFinishEditing {
        case addCard(to: Topic)
        case editCard(front: CardSide, back: CardSide)

        func getTitle() -> String {
            switch self {
            case .addCard(_):
                "Add Card"
            case .editCard(_, _):
                "Edit Card"
            }
        }
    }
    
    enum Field {
        case front
        case back
    }
    
    private func confirmEdits() {
        switch onFinishEditing {
        case .addCard(let topic):
            topic.cards.append(
                Card(front: CardSide(text: frontText, image: frontImageData), back: CardSide(text: backText, image: backImageData))
            )
            frontText = ""
            backText = ""
            frontImageData = nil
            backImageData = nil
            focusedField = .front
        case .editCard(let front, let back):
            front.text = frontText
            back.text = backText
            front.image = frontImageData
            back.image = backImageData
            dismiss()
        }
    }
    
    private func asyncloadPhotoToData() {
        Task {
            if let data = try? await photoItem?.loadTransferable(type: Data.self) {
                photoItem = nil // Deselect the photo in the PhotosPicker.
                switch focusedField {
                case .front:
                    frontImageData = data
                case .back:
                    backImageData = data
                case nil:
                    return
                }
            }
        }
    }
    
    private func isFormIncomplete() -> Bool {
        !(
            (frontImageData != nil || frontText.trimmingCharacters(in: .whitespaces).count != 0)
            && (backImageData != nil || backText.trimmingCharacters(in: .whitespaces).count != 0)
        )
    }
    
    @ViewBuilder
    private func makeImageSection(for field: Field) -> some View {
        if
            let data = (field == .front ? frontImageData : backImageData),
            let uiImage = UIImage(data: data)
        {
            makeImageFromUIImage(uiImage: uiImage)
                .border(.appBackground2)
        }
    }
    
    @ViewBuilder
    private func makeFieldHeader(for field: Field) -> some View {
        HStack {
            Text("\(field == .front ? "Front" : "Back") Side")
                .font(.headline)
            Spacer()
            if  ((field == .front) && frontImageData != nil) || ((field == .back) && backImageData != nil) {
                Button(action: {
                    switch field {
                    case .front:
                        frontImageData = nil
                    case .back:
                        backImageData = nil
                    }
                }) {
                    Image(systemName: "trash")
                }
            }
        }
    }
    
    private func makeNavigationBar() -> some ToolbarContent {
        ToolbarItem(placement: .navigation) {
            Button(action: confirmEdits) {
                Text("Done")
                    .bold()
            }
            .disabled(isFormIncomplete())
        }
    }
    
    private func makeKeyboardBar() -> some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            PhotosPicker(selection: $photoItem, matching: .images) {
                Image(systemName: "camera.fill")
                    .foregroundStyle(.appLabel)
                    .bold()
            }
            .onChange(of: photoItem, asyncloadPhotoToData)
            
            Button(action: {
                switch focusedField {
                case .front:
                    frontText += "___"
                case .back:
                    backText += "___"
                case nil:
                    return
                }
            }) {
                Text("__")
                    .font(.headline)
                    .foregroundStyle(.appLabel)
            }
        }
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    makeFieldHeader(for: .front)
                    makeImageSection(for: .front)
                    StandardTextField(
                        textField: 
                            TextField("Front Text", text: $frontText, axis: .vertical)
                            .focused($focusedField, equals: .front),
                        fieldText: $frontText,
                        clearTextButtonEnabled: false
                    )
                    .padding(.bottom)
                    
                    makeFieldHeader(for: .back)
                    makeImageSection(for: .back)
                    StandardTextField(
                        textField:
                            TextField("Back Text", text: $backText, axis: .vertical)
                                .focused($focusedField, equals: .back),
                        fieldText: $backText,
                        clearTextButtonEnabled: false
                    )
                    .padding(.bottom)
                }
                .padding()
            }
            .toolbar(content: makeNavigationBar)
            .toolbar(content: makeKeyboardBar)
            .onAppear {
                focusedField = .front
            }
            .navigationTitle(onFinishEditing.getTitle())
            .toolbarTitleDisplayMode(.inline)
        }
    }
}
