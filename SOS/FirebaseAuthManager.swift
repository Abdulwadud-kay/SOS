//
//  FirebaseAuthManager.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/19/25.
//

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
import FirebaseMessaging
import SwiftUI

class FirebaseAuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String = ""
    @Published var userType: String? = nil
    @Published var isFirstTimeUser = true
    @Published var isQuestionnaireCompleted = false
    @Published var isLoggedInFromFirestore = false
    @AppStorage("didLogout") private var didLogout: Bool = false

    private let auth = Auth.auth()
    private let db = Firestore.firestore()
    private var loginListener: ListenerRegistration?

    init() {
        checkAuthState()
    }

    func checkAuthState() {
        if let user = auth.currentUser, !didLogout {
            self.userId = user.uid
            self.isAuthenticated = true
            self.fetchUserProgress(userID: user.uid)
            self.startListeningForLoginStatus()
        } else {
            self.isAuthenticated = false
        }
    }

    func signUp(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let user = result?.user else {
                completion(false, "User creation failed")
                return
            }
            self.userId = user.uid
            self.initializeUser(userID: user.uid, email: email)
            self.isAuthenticated = true
            self.setLoggedIn(true)
            self.didLogout = false
            self.startListeningForLoginStatus()
            completion(true, nil)
        }
    }

    func login(email: String, password: String, completion: @escaping (Bool, String?) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(false, error.localizedDescription)
                return
            }
            guard let user = result?.user else {
                completion(false, "User login failed")
                return
            }
            self.userId = user.uid
            self.isAuthenticated = true
            self.setLoggedIn(true)
            self.didLogout = false
            self.fetchUserProgress(userID: user.uid)
            self.startListeningForLoginStatus()

            self.db.collection("users").document(user.uid).getDocument { snap, error in
                if let data = snap?.data(), error == nil,
                   let userType = data["userType"] as? String, userType == "Professional" {
                    Messaging.messaging().subscribe(toTopic: "professionals") { error in
                        if let error = error {
                            print("❌ Subscription failed: \(error.localizedDescription)")
                        } else {
                            print("✅ Subscribed to professionals topic successfully.")
                        }
                    }
                }
            }

            completion(true, nil)
        }
    }

    func fetchUserProgress(userID: String) {
        let userRef = db.collection("users").document(userID)
        userRef.getDocument { snapshot, error in
            guard let data = snapshot?.data(), error == nil else {
                self.isFirstTimeUser = true
                return
            }
            self.userType = data["userType"] as? String
            self.isQuestionnaireCompleted = data["questionnaireCompleted"] as? Bool ?? false
            self.isFirstTimeUser = (self.userType == nil)
            self.isLoggedInFromFirestore = data["isLoggedIn"] as? Bool ?? false
        }
    }

    private func initializeUser(userID: String, email: String) {
        db.collection("users").document(userID).setData([
            "email": email,
            "userType": NSNull(),
            "questionnaireCompleted": false,
            "isLoggedIn": true
        ])
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
                self.isFirstTimeUser = false
                completion(true, nil)
            }
        }
    }

    func logout() {
        do {
            try auth.signOut()
            Messaging.messaging().unsubscribe(fromTopic: "professionals") { error in
                if let error = error {
                    print("❌ Unsubscribe failed: \(error.localizedDescription)")
                } else {
                    print("✅ Unsubscribed from professionals topic successfully.")
                }
            }
            self.setLoggedIn(false)
            self.didLogout = true
            self.isAuthenticated = false
            self.userId = ""
            self.userType = nil
            loginListener?.remove()
            NotificationCenter.default.post(name: NSNotification.Name("UserDidLogoutNotification"), object: nil)
        } catch {
            print("Logout error: \(error.localizedDescription)")
        }
    }

    private func setLoggedIn(_ value: Bool) {
        guard !userId.isEmpty else { return }
        db.collection("users").document(userId).updateData(["isLoggedIn": value]) { error in
            if let error = error {
                print("Error updating isLoggedIn: \(error.localizedDescription)")
            }
        }
    }

    func startListeningForLoginStatus() {
        guard !userId.isEmpty else { return }
        loginListener = db.collection("users").document(userId)
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data(), error == nil else { return }
                if let loggedIn = data["isLoggedIn"] as? Bool, !loggedIn {
                    self.isAuthenticated = false
                    NotificationCenter.default.post(name: NSNotification.Name("UserDidLogoutNotification"), object: nil)
                }
            }
    }
}
