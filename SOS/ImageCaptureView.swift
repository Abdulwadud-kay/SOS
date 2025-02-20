//
//  ImageCaptureView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import SwiftUI

struct ImageCaptureView: View {
    @State private var selectedImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var navigateToDiagnosis = false
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = selectedImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 300)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 300)
                    .overlay(Text("No Image Selected").foregroundColor(.gray))
            }
            
            Button(action: {
                showImagePicker = true
            }) {
                Text("Select Image")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            // NavigationLink activated when an image is selected
            NavigationLink(
                destination: DiagnosisView(image: selectedImage),
                isActive: $navigateToDiagnosis,
                label: {
                    EmptyView()
                })
        }
        .padding()
        .sheet(isPresented: $showImagePicker, onDismiss: {
            // If an image was selected, navigate to the diagnosis screen.
            if selectedImage != nil {
                navigateToDiagnosis = true
            }
        }) {
            ImagePicker(image: $selectedImage)
        }
    }
}

struct ImageCaptureView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ImageCaptureView()
        }
    }
}
