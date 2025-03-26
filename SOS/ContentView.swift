//
//  ContentView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var authManager = FirebaseAuthManager()
    @State private var navPath = NavigationPath()
    @State private var navID = UUID()  // unique id for the NavigationStack
    
    var body: some View {
        NavigationStack(path: $navPath) {
            if !authManager.isAuthenticated {
                // User is not logged in: show the login page.
                AuthenticationPage(
                    isAuthenticated: $authManager.isAuthenticated,
                    authManager: authManager
                )
            } else {
                // User is authenticated:
                if let userType = authManager.userType {
                    // If userType is set, check if the questionnaire is completed.
                    if authManager.isQuestionnaireCompleted {
                        switch userType {
                        case "Patient":
                            HomePage()
                        case "Professional":
                            ProfessionalHomePage()
                        default:
                            Text("Unknown user type: \(userType)")
                        }
                    } else {
                        // Questionnaire not completed: show it.
                        QuestionnaireView(
                            authManager: authManager,
                            userId: authManager.userId,
                            userType: userType
                        )
                    }
                } else {
                    // If userType is nil, assume that user is not a first-time user.
                    // Show a ProgressView while fetching the user data.
                    ProgressView("Loading user data...")
                        .onAppear {
                            authManager.fetchUserProgress(userID: authManager.userId)
                        }
                }
            }
        }
        .id(navID) // Attach the unique ID to the NavigationStack
        .onChange(of: authManager.isAuthenticated) { newValue in
            if !newValue {
                // When the user logs out, clear the navigation stack and assign a new ID.
                navPath = NavigationPath()
                navID = UUID()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
