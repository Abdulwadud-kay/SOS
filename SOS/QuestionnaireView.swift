//
//  QuestionnaireView.swift
//  SOS
//
//  Created by Abdulwadud Abdulkadir on 3/3/25.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct QuestionnaireQuestion {
    enum QuestionType {
        case text
        case date
        case multipleChoice([String])
        case agreement
    }
    var prompt: String
    var type: QuestionType
    var answer: String?
}

struct QuestionnaireView: View {
    @State private var questions: [QuestionnaireQuestion] = []
    @State private var currentIndex = 0
    @State private var showQuestionnaire = true
    @State private var neverAskAgain = false
    var userId: String
    var userType: String

    var body: some View {
        VStack {
            if questions.isEmpty {
                ProgressView("Loading questions...") // Show loading until questions are ready
                    .onAppear {
                        loadQuestions()
                    }
            } else if showQuestionnaire {
                VStack {
                    Text(questions[currentIndex].prompt)
                        .font(.headline)
                        .padding()
                    
                    contentForQuestion(questions[currentIndex])
                        .frame(height: 120)
                    
                    HStack {
                        Button("Skip") {
                            currentIndex = questions.count
                        }
                        Spacer()
                        Button("Never Ask Again") {
                            neverAskAgain = true
                            currentIndex = questions.count
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                    
                    Button("Next") {
                        withAnimation(.spring()) {
                            currentIndex += 1
                        }
                    }
                    .disabled(!isAnswerValid(questions[currentIndex]))
                    .padding(.bottom, 40)
                }
                .padding()
                .transition(.move(edge: .leading))
                .onChange(of: currentIndex) { newValue in
                    if newValue >= questions.count {
                        showQuestionnaire = false
                        if !neverAskAgain {
                            // Track logins if skipped
                        }
                        saveAnswersToFirestore()
                    }
                }
            }
        }
    }

    func loadQuestions() {
        DispatchQueue.main.async {
            if userType == "Patient" {
                questions = [
                    QuestionnaireQuestion(prompt: "What is your current ailment?", type: .text),
                    QuestionnaireQuestion(prompt: "When were you born?", type: .date),
                    QuestionnaireQuestion(prompt: "Which best describes your lifestyle?", type: .multipleChoice(["Active", "Moderate", "Sedentary"])),
                    QuestionnaireQuestion(prompt: "I agree to share my health data with doctors.", type: .agreement)
                ]
            } else {
                questions = [
                    QuestionnaireQuestion(prompt: "What is your professional medical license number?", type: .text),
                    QuestionnaireQuestion(prompt: "Which medical field do you specialize in?", type: .multipleChoice(["General Practitioner", "Specialist", "Surgeon", "Other"])),
                    QuestionnaireQuestion(prompt: "Upload proof of your certification", type: .text),
                    QuestionnaireQuestion(prompt: "I agree that any malpractice will be subject to legal consequences.", type: .agreement)
                ]
            }
        }
    }

    @ViewBuilder
    func contentForQuestion(_ q: QuestionnaireQuestion) -> some View {
        switch q.type {
        case .text:
            TextField("Enter here", text: Binding(
                get: { q.answer ?? "" },
                set: { val in updateAnswer(val) }
            ))
            .textFieldStyle(RoundedBorderTextFieldStyle())
        case .date:
            DatePicker("Choose date", selection: Binding(
                get: {
                    if let ans = q.answer, let d = ISO8601DateFormatter().date(from: ans) {
                        return d
                    }
                    return Date()
                },
                set: { newVal in updateAnswer(ISO8601DateFormatter().string(from: newVal)) }
            ), displayedComponents: .date)
            .labelsHidden()
        case .multipleChoice(let choices):
            VStack {
                ForEach(choices, id: \.self) { choice in
                    Button(choice) {
                        updateAnswer(choice)
                    }
                    .padding(6)
                    .background(q.answer == choice ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
            }
        case .agreement:
            Toggle(isOn: Binding(
                get: { q.answer == "true" },
                set: { val in updateAnswer(val ? "true" : "false") }
            )) {
                Text("I agree")
            }
        }
    }

    func updateAnswer(_ val: String) {
        questions[currentIndex].answer = val
    }

    func isAnswerValid(_ q: QuestionnaireQuestion) -> Bool {
        return q.answer != nil && !q.answer!.isEmpty
    }

    func saveAnswersToFirestore() {
        let db = Firestore.firestore()
        let answers = questions.map { [$0.prompt: $0.answer ?? ""] }
        db.collection("users").document(userId).collection("questionnaire").addDocument(data: ["answers": answers]) { _ in }
    }
}

struct QuestionnaireView_Previews: PreviewProvider {
    static var previews: some View {
        QuestionnaireView(userId: "testUserID", userType: "Patient")
    }
}
