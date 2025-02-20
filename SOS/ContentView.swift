//
//  ContentView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("SOS")
                    .font(.largeTitle)
                    .bold()
                
                Text("Emergency AI Diagnosis")
                    .font(.headline)
                
                NavigationLink(destination: ImageCaptureView()) {
                    Text("Upload Image / Take Photo")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            .padding()
            .navigationTitle("Welcome")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

