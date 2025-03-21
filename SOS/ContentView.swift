//
//  ContentView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import SwiftUI

struct ContentView: View {
    // Observe the same FirebaseAuthManager
    @ObservedObject var authManager = FirebaseAuthManager()
    @State private var navPath = NavigationPath()
    @State private var navID = UUID()  // unique id for the NavigationStack
    
    var body: some View {
        NavigationStack(path: $navPath) {
            if !authManager.isAuthenticated {
                AuthenticationPage(
                    isAuthenticated: $authManager.isAuthenticated,
                    authManager: authManager
                )
            } else {
                if authManager.userType == nil {
                    if authManager.isFirstTimeUser {
                        UserTypePage(authManager: authManager)
                    } else {
                        ProgressView("Loading user type...")
                            .onAppear {
                                authManager.fetchUserProgress(userID: authManager.userId)
                            }
                    }
                } else {
                    if authManager.isQuestionnaireCompleted {
                        switch authManager.userType! {
                        case "Patient":
                            HomePage()
                        case "Professional":
                            ProfessionalHomePage()
                        default:
                            Text("Unknown user type: \(authManager.userType!)")
                        }
                    } else {
                        QuestionnaireView(
                            authManager: authManager,
                            userId: authManager.userId,
                            userType: authManager.userType ?? "Patient"
                        )
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
