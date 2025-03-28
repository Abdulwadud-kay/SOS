//
//  SplashScreenView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/28/25.
//


import SwiftUI

struct SplashScreenView: View {
    @State private var isActive = false

    var body: some View {
        if isActive {
            ContentView()
        } else {
            ZStack {
                Color.white.ignoresSafeArea()
                VStack {
                    Image("Logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 350, height: 350)


                    Text("SOS HEALTH")
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.black)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation {
                        isActive = true
                    }
                }
            }
        }
    }
}

struct SplashScreenView_Previews: PreviewProvider {
    static var previews: some View {
        SplashScreenView()
    }
}
