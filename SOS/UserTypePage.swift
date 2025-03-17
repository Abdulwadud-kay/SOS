//
//  UserTypePage.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/17/25.
//

import Foundation
import SwiftUI

struct UserTypePage: View {
    @State private var selectedUserType: String? = nil
    @State private var navigateToQuestionnaire = false
    @State private var userId: String = UUID().uuidString // Temporary User ID

    var body: some View {
        NavigationView {
            VStack {
                Text("Select Your User Type")
                    .font(.title)
                    .padding(.bottom, 30)

                HStack(spacing: 20) {
                    Button(action: {
                        selectedUserType = "Patient"
                        navigateToQuestionnaire = true
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.red)
                                .frame(width: 150, height: 150)
                                .cornerRadius(12)
                            Text("Patient")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                    
                    Button(action: {
                        selectedUserType = "Professional"
                        navigateToQuestionnaire = true
                    }) {
                        ZStack {
                            Rectangle()
                                .fill(Color.gray)
                                .frame(width: 150, height: 150)
                                .cornerRadius(12)
                            Text("Professional")
                                .foregroundColor(.white)
                                .font(.headline)
                        }
                    }
                }
                .padding()
                
                NavigationLink(
                    destination: QuestionnaireView(userId: userId, userType: selectedUserType ?? ""),
                    isActive: $navigateToQuestionnaire
                ) {
                    EmptyView()
                }
                .hidden()
            }
            .navigationBarBackButtonHidden(true) 
        }
    }
}

struct UserTypePage_Previews: PreviewProvider {
    static var previews: some View {
        UserTypePage()
    }
}
