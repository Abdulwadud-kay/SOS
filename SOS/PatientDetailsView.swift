//
//  PatientDetailsView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/21/25.
//

import Foundation
import SwiftUI
import Firebase

struct PatientDetailsView: View {
    var caseDetails: Case
    var onBack: () -> Void  // New closure callback

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Button("Release Case") {
                        releaseCase(caseDetails)
                    }
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    Spacer()
                }
                Text("Patient: \(caseDetails.patientName), Age: \(caseDetails.age)")
                    .font(.title2)
                    .padding(.bottom, 5)
                Text("Medical History: \(caseDetails.medicalHistory)")
                    .foregroundColor(.gray)
                    .padding(.bottom, 5)
                Text("AI's Initial Diagnosis: \(caseDetails.aiDiagnosis)")
                    .foregroundColor(.green)
                    .bold()
                    .padding(.bottom, 5)
                Text("First Aid Recommended: \(caseDetails.aiFirstAid)")
                    .foregroundColor(.red)
                    .padding(.bottom, 10)
                Button(action: {}) {
                    HStack {
                        Text("View AI-Patient Chat History")
                        Image(systemName: "chevron.down")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                }
                HStack(spacing: 20) {
                    Button(action: {}) {
                        Image(systemName: "message.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.blue)
                    }
                    Button(action: {}) {
                        Image(systemName: "phone.fill")
                            .resizable()
                            .frame(width: 35, height: 35)
                            .foregroundColor(.blue)
                    }
                    Button(action: {}) {
                        Image(systemName: "video.fill")
                            .resizable()
                            .frame(width: 40, height: 30)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.top, 15)
                Spacer()
            }
            .padding()
            .navigationTitle("Patient File")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        onBack()  // Call the passed in closure
                    }) {
                        HStack {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                    }
                }
            }
        }
    }
    
    func releaseCase(_ caseDetails: Case) {
        let db = Firestore.firestore()
        db.collection("cases").document(caseDetails.id).updateData(["status": "Pending", "professionalID": ""])
    }
}

struct PatientDetailsView_Previews: PreviewProvider {
    static var previews: some View {
        PatientDetailsView(
            caseDetails: Case(
                id: "1",
                patientName: "Test",
                age: 30,
                medicalHistory: "None",
                ailment: "Ailment",
                aiDiagnosis: "Diagnosis",
                aiFirstAid: "First Aid",
                chatHistory: [],
                status: "Pending"
            ),
            onBack: { }
        )
    }
}
