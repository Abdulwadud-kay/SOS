//
//  UserTypePage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/17/25.
//

import SwiftUI

struct UserTypePage: View {
    @ObservedObject var authManager: FirebaseAuthManager
    @State private var selectedType: String = ""
    @State private var navigateToQuestionnaire = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    
    // For example purposes, we list two types.
    let userTypes = ["Patient", "Professional"]

    var body: some View {
        VStack(spacing: 20) {
            Text("Select Your User Type")
                .font(.title)
            
            ForEach(userTypes, id: \.self) { type in
                Button(action: {
                    selectedType = type
                    // Save the user type to Firestore.
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
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(selectedType == type ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2))
                        .cornerRadius(8)
                }
            }
            
            NavigationLink(
                destination: QuestionnaireView(
                    authManager: authManager,
                    userId: authManager.userId,
                    userType: authManager.userType ?? ""),
                isActive: $navigateToQuestionnaire
            ) {
                EmptyView()
            }
        }
        .padding()
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "An error occurred."), dismissButton: .default(Text("OK")))
        }
    }
}

struct UserTypePage_Previews: PreviewProvider {
    static var previews: some View {
        UserTypePage(authManager: FirebaseAuthManager())
    }
}
