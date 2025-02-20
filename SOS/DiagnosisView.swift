//
//  DiagnosisView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import SwiftUI

struct DiagnosisView: View {
    var image: UIImage?
    @StateObject private var viewModel = DiagnosisViewModel()
    
    var body: some View {
        VStack(spacing: 20) {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 200)
            }
            
            if viewModel.isLoading {
                ProgressView("Analyzing...")
                    .padding()
            } else if let diagnosis = viewModel.diagnosis {
                Text("Diagnosis: \(diagnosis)")
                    .font(.headline)
                    .padding()
                
                Text("Next Steps:")
                    .font(.subheadline)
                    .bold()
                Text(viewModel.nextSteps)
                    .padding()
            } else {
                Text("No diagnosis available yet.")
                    .padding()
            }
            
            Spacer()
            
            Button(action: {
                viewModel.analyzeImage(image: image)
            }) {
                Text("Analyze Image")
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
        .navigationTitle("Diagnosis")
    }
}

struct DiagnosisView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DiagnosisView(image: nil)
        }
    }
}
