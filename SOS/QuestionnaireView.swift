


import SwiftUI
import Firebase
import FirebaseFirestore

struct QuestionnaireQuestion {
    enum QuestionType {
        case text, date, multipleChoice([String]), agreement
    }
    var prompt: String
    var type: QuestionType
    var answer: String?
}

struct QuestionnaireView: View {
    @ObservedObject var authManager: FirebaseAuthManager
    @State private var questions: [QuestionnaireQuestion] = []
    @State private var currentIndex = 0
    @State private var isFinished = false
    @State private var isSaving = false
    @State private var navigateToHome = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert = false
    var userId: String
    var userType: String

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    if questions.isEmpty {
                        ProgressView("Loading questions...")
                            .onAppear { loadQuestions() }
                    } else if !isFinished {
                        VStack {
                            Text(questions[currentIndex].prompt)
                                .font(.headline)
                                .padding()
                            contentForQuestion(questions[currentIndex])
                                .frame(height: 120)
                            HStack {
                                if currentIndex > 0 {
                                    Button("Back") { withAnimation(.spring()) { currentIndex -= 1 } }
                                }
                                Spacer()
                                if currentIndex < questions.count - 1 {
                                    Button("Next") { withAnimation(.spring()) { currentIndex += 1 } }
                                        .disabled(!isAnswerValid(questions[currentIndex]))
                                } else {
                                    Button("Finish") { withAnimation(.spring()) { isFinished = true } }
                                        .disabled(!isAnswerValid(questions[currentIndex]))
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 40)
                        }
                        .padding()
                    } else {
                        ReviewAnswersView(questions: questions, submitAction: { saveAnswersToFirestore() }, editAction: { withAnimation(.spring()) { isFinished = false } })
                    }
                    NavigationLink(
                        destination: userType == "Patient" ? AnyView(HomePage()) : AnyView(ProfessionalHomePage()),
                        isActive: $navigateToHome
                    ) { EmptyView() }
                    .hidden()
                }
                if isSaving {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Submitting your answers...")
                        .foregroundColor(.white)
                        .scaleEffect(1.5)
                        .padding()
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(10)
                }
            }
            .navigationTitle("Questionnaire")
            .alert(isPresented: $showErrorAlert) {
                Alert(title: Text("Error"), message: Text(errorMessage ?? "An error occurred."), dismissButton: .default(Text("OK")))
            }
        }
    }
    
    @ViewBuilder
    func contentForQuestion(_ q: QuestionnaireQuestion) -> some View {
        switch q.type {
        case .text:
            TextField("Enter here", text: Binding(get: { q.answer ?? "" }, set: { updateAnswer($0) }))
                .textFieldStyle(RoundedBorderTextFieldStyle())
        case .date:
            DatePicker("Choose date", selection: Binding(get: {
                if let ans = q.answer, let d = ISO8601DateFormatter().date(from: ans) { return d }
                return Date()
            }, set: { newVal in updateAnswer(ISO8601DateFormatter().string(from: newVal)) }), displayedComponents: .date)
                .labelsHidden()
        case .multipleChoice(let choices):
            if choices.count > 4 {
                let columns = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: columns, spacing: 10) {
                    ForEach(choices, id: \.self) { choice in
                        Button { updateAnswer(choice) } label: {
                            Text(choice)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(q.answer == choice ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                VStack {
                    ForEach(choices, id: \.self) { choice in
                        Button { updateAnswer(choice) } label: {
                            Text(choice)
                                .padding(6)
                                .frame(maxWidth: .infinity)
                                .background(q.answer == choice ? Color.blue.opacity(0.2) : Color.clear)
                                .cornerRadius(8)
                        }
                    }
                }
            }
        case .agreement:
            Toggle(isOn: Binding(get: { q.answer == "true" }, set: { updateAnswer($0 ? "true" : "false") })) {
                Text("I agree")
            }
        }
    }
    
    func updateAnswer(_ newValue: String) {
        questions[currentIndex].answer = newValue
    }
    
    func isAnswerValid(_ q: QuestionnaireQuestion) -> Bool {
        return !(q.answer?.isEmpty ?? true)
    }
    
    func loadQuestions() {
        DispatchQueue.main.async {
            if userType == "Patient" {
                questions = [
                    QuestionnaireQuestion(prompt: "What is your full name?", type: .text),
                    QuestionnaireQuestion(prompt: "When were you born?", type: .date),
                    QuestionnaireQuestion(prompt: "What is your gender?", type: .multipleChoice(["Male", "Female", "Other"])),
                    QuestionnaireQuestion(prompt: "What is your blood type?", type: .multipleChoice(["A+", "A-", "B+", "B-", "AB+", "AB-", "O+", "O-"])),
                    QuestionnaireQuestion(prompt: "Do you have any known allergies?", type: .text),
                    QuestionnaireQuestion(prompt: "Do you have any chronic conditions?", type: .text),
                    QuestionnaireQuestion(prompt: "Have you had any surgeries in the past?", type: .text),
                    QuestionnaireQuestion(prompt: "Are you currently on any medications?", type: .text),
                    QuestionnaireQuestion(prompt: "Do you smoke?", type: .multipleChoice(["Yes", "No", "Occasionally"])),
                    QuestionnaireQuestion(prompt: "Do you consume alcohol?", type: .multipleChoice(["Yes", "No", "Occasionally"])),
                    QuestionnaireQuestion(prompt: "What is your emergency contact name?", type: .text),
                    QuestionnaireQuestion(prompt: "What is your emergency contact number?", type: .text),
                    QuestionnaireQuestion(prompt: "What is your current ailment or health concern?", type: .text),
                    QuestionnaireQuestion(prompt: "I agree to share my health data with doctors.", type: .agreement)
                ]
            } else {
                questions = [
                    QuestionnaireQuestion(prompt: "What is your full name?", type: .text),
                    QuestionnaireQuestion(prompt: "What is your professional medical license number?", type: .text),
                    QuestionnaireQuestion(prompt: "Which medical field do you specialize in?", type: .multipleChoice(["General Practitioner", "Specialist", "Surgeon", "Psychologist", "Other"])),
                    QuestionnaireQuestion(prompt: "Upload proof of your certification (enter document ID)", type: .text),
                    QuestionnaireQuestion(prompt: "What institution issued your medical certification?", type: .text),
                    QuestionnaireQuestion(prompt: "How many years of experience do you have in the medical field?", type: .text),
                    QuestionnaireQuestion(prompt: "Where do you currently practice?", type: .text),
                    QuestionnaireQuestion(prompt: "Have you ever faced malpractice accusations?", type: .multipleChoice(["Yes", "No"])),
                    QuestionnaireQuestion(prompt: "Are you currently licensed to practice?", type: .multipleChoice(["Yes", "No"])),
                    QuestionnaireQuestion(prompt: "Have you previously worked in emergency medicine?", type: .multipleChoice(["Yes", "No"])),
                    QuestionnaireQuestion(prompt: "I agree that any malpractice will be subject to legal consequences.", type: .agreement),
                    QuestionnaireQuestion(prompt: "I agree to allow my certification to be used for authentication purposes.", type: .agreement),
                    QuestionnaireQuestion(prompt: "I agree that my data may be used anonymously for medical research.", type: .agreement),
                    QuestionnaireQuestion(prompt: "I acknowledge that I will not intentionally provide false or misleading medical guidance.", type: .agreement),
                    QuestionnaireQuestion(prompt: "I understand that I may be removed from the platform if found violating the integrity agreement.", type: .agreement)
                ]
            }
        }
    }
    
    func saveAnswersToFirestore() {
        guard !userId.isEmpty else {
            errorMessage = "User identifier is missing."
            showErrorAlert = true
            return
        }
        isSaving = true
        let db = Firestore.firestore()
        let answers = questions.map { [$0.prompt: $0.answer ?? ""] }
        db.collection("questionnaire").document(userId).setData(["answers": answers]) { error in
            isSaving = false
            if let error = error {
                errorMessage = "Error saving your responses: \(error.localizedDescription)"
                showErrorAlert = true
            } else {
                let userRef = db.collection("users").document(userId)
                userRef.updateData(["questionnaireCompleted": true]) { err in
                    if let err = err {
                        errorMessage = "Error updating user data: \(err.localizedDescription)"
                        showErrorAlert = true
                    } else {
                        authManager.isQuestionnaireCompleted = true
                        DispatchQueue.main.async {
                            navigateToHome = true
                        }
                    }
                }
            }
        }
    }
}

struct ReviewAnswersView: View {
    var questions: [QuestionnaireQuestion]
    var submitAction: () -> Void
    var editAction: () -> Void
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(questions.indices, id: \.self) { index in
                        VStack(alignment: .leading) {
                            Text(questions[index].prompt)
                                .font(.subheadline)
                                .foregroundColor(.gray)
                            Text(questions[index].answer ?? "No answer")
                                .font(.body)
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding()
            }
            .navigationTitle("Review Answers")
            HStack {
                Button("Edit Answers") { editAction() }
                    .padding()
                Spacer()
                Button("Submit") { submitAction() }
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .padding(.horizontal)
        }
    }
}
