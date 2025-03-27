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
    @State private var navID = UUID()

    var body: some View {
        NavigationStack(path: $navPath) {
            if !authManager.isAuthenticated || !authManager.isLoggedInFromFirestore {
                AuthenticationPage(isAuthenticated: $authManager.isAuthenticated, authManager: authManager)
            } else {
                if let userType = authManager.userType {
                    if authManager.isQuestionnaireCompleted {
                        if userType == "Patient" {
                            HomePage()
                        } else {
                            ProfessionalHomePage()
                        }
                    } else {
                        QuestionnaireView(authManager: authManager, userId: authManager.userId, userType: userType)
                    }
                } else {
                    ProgressView("Loading user data...")
                        .onAppear {
                            authManager.fetchUserProgress(userID: authManager.userId)
                        }
                }
            }
        }
        .id(navID)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("UserDidLogoutNotification"))) { _ in
            navPath = NavigationPath()
            navID = UUID()
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
