//
//  FirebaseAuthManager.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/19/25.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Firebase

class FirebaseAuthManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var userId: String = ""
    @Published var userType: String? = nil
    @Published var isFirstTimeUser = true
    @Published var isQuestionnaireCompleted = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()

    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign up error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            guard let user = result?.user else {
                let message = "User creation failed"
                print(message)
                completion(false, message)
                return
            }
            self.userId = user.uid
            self.initializeUser(userID: user.uid, email: email)
            self.isAuthenticated = true
            completion(true, nil)
        }
    }

    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Login error: \(error.localizedDescription)")
                completion(false, error.localizedDescription)
                return
            }
            guard let user = result?.user else {
                let message = "User login failed"
                print(message)
                completion(false, message)
                return
            }
            self.userId = user.uid
            self.isAuthenticated = true
            self.fetchUserProgress(userID: user.uid)
            completion(true, nil)
        }
    }

    func fetchUserProgress(userID: String) {
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                print("No user data found, assuming first time user.")
                self.isFirstTimeUser = true
                return
            }
            self.userType = data["userType"] as? String
            self.isQuestionnaireCompleted = data["questionnaireCompleted"] as? Bool ?? false
            self.isFirstTimeUser = (self.userType == nil)
        }
    }

    private func initializeUser(userID: String, email: String) {
        db.collection("users").document(userID).setData([
            "email": email,
            "userType": NSNull(),
            "questionnaireCompleted": false
        ]) { error in
            if let error = error {
                print("Error saving new user: \(error.localizedDescription)")
            } else {
                print("User successfully saved!")
            }
        }
        self.isFirstTimeUser = true
    }
    
    func updateUserType(_ type: String, completion: @escaping (Bool, String?) -> Void) {
        guard !userId.isEmpty else {
            completion(false, "User ID is empty")
            return
        }
        let userRef = db.collection("users").document(userId)
        userRef.setData(["userType": type], merge: true) { error in
            if let error = error {
                completion(false, error.localizedDescription)
            } else {
                self.userType = type
                self.isFirstTimeUser = false // Mark as not first time anymore
                completion(true, nil)
            }
        }
    }

    
    func logout() {
        do {
            try auth.signOut()
            isAuthenticated = false
            userId = ""
            userType = nil
        } catch {
            print("Logout error: \(error.localizedDescription)")
        }
    }
}
