//
//  ContentView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/4/25.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: FirebaseAuthManager
    @State private var navPath = NavigationPath()
    @State private var navID = UUID()

    var body: some View {
        NavigationStack(path: $navPath) {
            Group {
                if !authManager.isAuthenticated {
                    AuthenticationPage(isAuthenticated: $authManager.isAuthenticated)
                        .environmentObject(authManager)


                } else if !authManager.isLoggedInFromFirestore {
                    ProgressView("Loading your profile...")
                        .onAppear {
                            authManager.fetchUserProgress(userID: authManager.userId)
                        }

                } else if let userType = authManager.userType {
                    if authManager.isQuestionnaireCompleted {
                        if userType == "Patient" {
                            HomePage()
                        } else {
                            ProfessionalHomePage()
                        }
                    } else {
                        QuestionnaireView(
                            userId: authManager.userId,
                            userType: userType
                        )
                        .environmentObject(authManager)
                    }

                } else {
                    ProgressView("Loading user type...")
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
