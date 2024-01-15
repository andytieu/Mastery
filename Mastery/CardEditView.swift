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
        .aspectRatio(contentMode: .fit)
        .frame(width: 300, height: 200)
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
    
    private func makeImageSection(for field: Field?) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if 
                let field,
                let data = field == .front ? frontImageData : backImageData,
                let uiImage = UIImage(data: data) 
            {
                Button(action: {
                    if field == .front {
                        frontImageData = nil
                    } else {
                        backImageData = nil
                    }
                }, label: {
                    Image(systemName: "trash")
                })
                
                makeImageFromUIImage(uiImage: uiImage)
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("Front Side")
                    .font(.headline)
                makeImageSection(for: .front)
                TextField("Front Text", text: $frontText, axis: .vertical)
                    .focused($focusedField, equals: .front)
                    .textFieldStyle(StandardTextFieldStyle())
                    .padding(.bottom)
                
                Text("Back Side")
                    .font(.headline)
                makeImageSection(for: .back)
                TextField("Back Text", text: $backText, axis: .vertical)
                    .focused($focusedField, equals: .back)
                    .textFieldStyle(StandardTextFieldStyle())
            }
            .padding()
        }
        .toolbar {
            Button(action: confirmEdits) {
                Text("Done")
                    .bold()
            }
            .disabled(isFormIncomplete())
        }
        .toolbar {
            ToolbarItem(placement: .keyboard) {
                PhotosPicker(selection: $photoItem, matching: .images) {
                    Image(systemName: "camera.fill")
                        .bold()
                }
                .onChange(of: photoItem, asyncloadPhotoToData)
            }
        }
        .onAppear {
            focusedField = .front
        }
        .navigationTitle(onFinishEditing.getTitle())
        .toolbarTitleDisplayMode(.inline)
    }
}
