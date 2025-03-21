




import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase

struct AuthenticationPage: View {
    @Binding var isAuthenticated: Bool
    @ObservedObject var authManager: FirebaseAuthManager
    @State private var isLogin = true  // default is login now
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var navigateToUserType = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    var body: some View {
        NavigationView {
            VStack {
                if authManager.isAuthenticated {
                    if authManager.userType == nil {
                        UserTypePage(authManager: authManager)
                    } else if !authManager.isQuestionnaireCompleted {
                        QuestionnaireView(
                            authManager: authManager,
                            userId: authManager.userId,
                            userType: authManager.userType ?? "Patient"
                        )
                    } else {
                        if authManager.userType == "Patient" {
                            HomePage()
                        } else {
                            ProfessionalHomePage()
                        }
                    }
                } else {
                    VStack {
                        NavigationLink(
                            destination: UserTypePage(authManager: authManager),
                            isActive: $navigateToUserType
                        ) {
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
                                    authManager.login(email: email, password: password) { success, error in
                                        if success {
                                            navigateToUserType = true
                                        } else {
                                            errorMessage = error
                                            showErrorAlert = true
                                        }
                                    }
                                }
                                .padding()
                                
                                HStack {
                                    Button("New user? Sign up") { isLogin = false }
                                    Spacer()
                                    Button("Forgot password?") {
                                        // Add forgot password logic here.
                                    }
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
                                    guard password == confirmPassword else {
                                        errorMessage = "Passwords do not match."
                                        showErrorAlert = true
                                        return
                                    }
                                    authManager.signUp(email: email, password: password) { success, error in
                                        if success {
                                            navigateToUserType = true
                                        } else {
                                            errorMessage = error
                                            showErrorAlert = true
                                        }
                                    }
                                }
                                .padding()
                                
                                Button("Already have an account? Login") {
                                    isLogin = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationBarHidden(true)
            .navigationBarBackButtonHidden(true)
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Error"),
                    message: Text(errorMessage ?? "An error occurred."),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
        .navigationViewStyle(StackNavigationViewStyle()) // Ensure no back arrow appears on iPad
    }
}

struct AuthenticationPage_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationPage(
            isAuthenticated: .constant(false),
            authManager: FirebaseAuthManager()
        )
    }
}
