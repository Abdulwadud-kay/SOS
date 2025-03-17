//
//  AuthenticationPage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 2/24/25.
//
import SwiftUI

struct AuthenticationPage: View {
    @Binding var isAuthenticated: Bool
    @State private var isLogin = false
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToUserType = false

    var body: some View {
        NavigationView {
            VStack {
                NavigationLink(destination: UserTypePage(), isActive: $navigateToUserType) {
                    EmptyView()
                }
                .hidden()
                
                VStack {
                    if isLogin {
                        Text("Login")
                            .font(.title)
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Login") {
                            navigateToUserType = true
                        }
                        .padding()
                        
                        HStack {
                            Button("New user? Sign up") { isLogin = false }
                            Spacer()
                            Button("Forgot password?") {}
                        }
                    } else {
                        Text("Sign Up")
                            .font(.title)
                        TextField("Email", text: $email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        TextField("Phone", text: $phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SecureField("Password", text: $password)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        Button("Sign Up") {
                            navigateToUserType = true
                        }
                        .padding()
                        
                        Button("Already have an account? Login") {
                            isLogin = true
                        }
                    }
                }
                .padding()
            }
            .navigationBarHidden(true) // Hide navigation bar for a cleaner UI
        }
    }
}

struct AuthenticationPage_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationPage(isAuthenticated: .constant(false))
    }
}
