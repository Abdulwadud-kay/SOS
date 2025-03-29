//
//  UserTypePage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/17/25.
//

import SwiftUI

struct UserTypePage: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var selectedType: String = ""
    @State private var navigateToQuestionnaire = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    let userTypes = ["Patient", "Professional"]

    var body: some View {
        ZStack {
            Color(UIColor.systemBackground).ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Select Your User Type")
                    .font(.title2)
                    .fontWeight(.bold)

                ForEach(userTypes, id: \.self) { type in
                    Button(action: {
                        selectedType = type
                        authManager.updateUserType(type) { success, error in
                            if success {
                                navigateToQuestionnaire = true
                            } else {
                                errorMessage = error
                                showErrorAlert = true
                            }
                        }
                    }) {
                        Text(type)
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(selectedType == type ? Color.red.opacity(0.8) : Color(UIColor.secondarySystemBackground))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                            .shadow(radius: 1)
                    }
                }

                NavigationLink(
                    destination: QuestionnaireView(
                        userId: authManager.userId,
                        userType: authManager.userType ?? ""
                    )
                    .environmentObject(authManager),
                    isActive: $navigateToQuestionnaire
                ) {
                    EmptyView()
                }
            }
            .padding()
        }
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "An error occurred."), dismissButton: .default(Text("OK")))
        }
    }
}
