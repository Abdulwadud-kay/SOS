




import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Firebase

struct AuthenticationPage: View {
    @Binding var isAuthenticated: Bool
    @ObservedObject var authManager: FirebaseAuthManager

    @State private var isLogin = true
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false

    var body: some View {
        VStack(spacing: 24) {
            Image("Logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .padding(.top, 40)

            Text(isLogin ? "Login to SOS" : "Create an Account")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.black)

            VStack(spacing: 16) {
                AuthTextField(
                    icon: "envelope.fill",
                    placeholder: "Email",
                    text: $email
                )
                if !isLogin {
                    AuthTextField(
                        icon: "phone.fill",
                        placeholder: "Phone",
                        text: $phone
                    )
                }
                AuthSecureField(
                    icon: "lock.fill",
                    placeholder: "Password",
                    text: $password,
                    isVisible: $showPassword
                )
                if !isLogin {
                    AuthSecureField(
                        icon: "lock.rotation.open",
                        placeholder: "Confirm Password",
                        text: $confirmPassword,
                        isVisible: $showConfirmPassword
                    )
                }
            }

            Button(action: {
                if isLogin {
                    authManager.login(email: email, password: password) { success, error in
                        if !success {
                            errorMessage = error
                            showErrorAlert = true
                        }
                    }
                } else {
                    guard password == confirmPassword else {
                        errorMessage = "Passwords do not match."
                        showErrorAlert = true
                        return
                    }
                    authManager.signUp(email: email, password: password) { success, error in
                        if !success {
                            errorMessage = error
                            showErrorAlert = true
                        }
                    }
                }
            }) {
                Text(isLogin ? "Login" : "Sign Up")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red)
                    .cornerRadius(10)
                    .shadow(radius: 2)
            }

            HStack {
                Button(action: { isLogin.toggle() }) {
                    Text(isLogin ? "New user? Sign up" : "Already have an account? Login")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
                Spacer()
                if isLogin {
                    Button("Forgot password?") {
                        // Add functionality if desired
                    }
                    .font(.footnote)
                    .foregroundColor(.gray)
                }
            }
        }
        .padding()
        .background(Color.white.ignoresSafeArea())
        .alert(isPresented: $showErrorAlert) {
            Alert(title: Text("Error"), message: Text(errorMessage ?? "Something went wrong"), dismissButton: .default(Text("OK")))
        }
    }
}

struct AuthTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            TextField(placeholder, text: $text)
                .autocapitalization(.none)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}

struct AuthSecureField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    @Binding var isVisible: Bool

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.gray)
            if isVisible {
                TextField(placeholder, text: $text)
            } else {
                SecureField(placeholder, text: $text)
            }
            Button(action: {
                isVisible.toggle()
            }) {
                Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .shadow(radius: 1)
    }
}


struct AuthenticationPage_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationPage(isAuthenticated: .constant(false), authManager: FirebaseAuthManager())
    }
}
