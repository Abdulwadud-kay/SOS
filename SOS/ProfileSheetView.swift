//
//  ProfileSheetView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/28/25.
//


import SwiftUI

struct ProfileSheetView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var showSettings = false
    let onClose: () -> Void

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)

                Text("User Profile")
                    .font(.title3)
                    .fontWeight(.semibold)

                Button {
                    showSettings = true
                } label: {
                    Label("Settings", systemImage: "gearshape.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray5))
                        .cornerRadius(10)
                }

                Button {
                    authManager.logout()
                    onClose()
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right.fill")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red)
                        .cornerRadius(10)
                }

                Button("Dismiss") {
                    onClose()
                }
                .padding(.top, 10)
            }
            .padding()
            .navigationTitle("Profile")
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
        }
    }
}
