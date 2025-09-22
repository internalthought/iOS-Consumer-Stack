import SwiftUI

struct OnboardingView: View {
    @StateObject var viewModel: OnboardingViewModel
    let onComplete: () -> Void

    @State private var freeTextAnswer: String = ""

    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if let error = viewModel.error {
                errorView(error)
            } else if !viewModel.questions.isEmpty {
                surveyView
            } else {
                emptyStateView
            }
        }
        .onAppear {
            Task {
                await viewModel.fetchQuestions()
            }
        }
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading Survey...")
                .foregroundColor(.secondary)
        }
    }

    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 50))
                .foregroundColor(.orange)
            Text("Unable to Load Survey")
                .font(.title)
            Text(error)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            HStack(spacing: 20) {
                Button("Retry") {
                    Task {
                        await viewModel.fetchQuestions()
                    }
                }
                .buttonStyle(.borderedProminent)

                Button("Skip") {
                    onComplete()
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
    }

    private var surveyView: some View {
        let currentQuestion = viewModel.questions[viewModel.currentIndex]
        
        return VStack(spacing: 30) {
            ProgressView(value: Double(viewModel.currentIndex + 1), total: Double(viewModel.questions.count))
                .progressViewStyle(LinearProgressViewStyle())
                .padding(.horizontal)

            Text(currentQuestion.text)
                .font(.largeTitle)
                .multilineTextAlignment(.center)
                .padding()
                .accessibilityIdentifier("QuestionText")

            switch currentQuestion.type {
            case "multiple_choice", "single_choice":
                multipleChoiceView(for: currentQuestion)
            case "text":
                freeTextView(for: currentQuestion)
            default:
                unknownQuestionView(for: currentQuestion)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func multipleChoiceView(for question: QuestionDTO) -> some View {
        VStack(spacing: 15) {
            ForEach(question.options ?? [], id: \.self) { option in
                Button(action: {
                    handleAnswer(option)
                }) {
                    Text(option)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("OptionButton_\(option)")
            }
        }
    }
    
    private func freeTextView(for question: QuestionDTO) -> some View {
        VStack(spacing: 20) {
            TextField("Type your answer here...", text: $freeTextAnswer)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .accessibilityIdentifier("FreeTextField")
            
            Button("Next") {
                handleAnswer(freeTextAnswer)
                freeTextAnswer = ""
            }
            .buttonStyle(.borderedProminent)
            .disabled(freeTextAnswer.isEmpty)
        }
    }

    private func unknownQuestionView(for question: QuestionDTO) -> some View {
        VStack {
            Text("Unsupported question type: \(question.type)")
                .foregroundColor(.red)
            Button("Skip Question") {
                handleAnswer("")
            }
            .buttonStyle(.bordered)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Text("You're all set!")
                .font(.largeTitle)
            Button("Continue") {
                onComplete()
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private func handleAnswer(_ answer: String) {
        viewModel.answerCurrentQuestion(with: answer)
        
        if viewModel.currentIndex < viewModel.questions.count - 1 {
            viewModel.nextQuestion()
        } else {
            Task {
                await viewModel.submitSurvey()
                onComplete()
            }
        }
    }
}

#if DEBUG
struct OnboardingView_Previews: PreviewProvider {
    static var previews: some View {
        let serviceLocator = ServiceLocator.shared

        let loadingVM = OnboardingViewModel(supabaseService: serviceLocator.supabaseService, authService: serviceLocator.authenticationService)
        loadingVM.questions = []
        loadingVM.isLoading = true

        let errorVM = OnboardingViewModel(supabaseService: serviceLocator.supabaseService, authService: serviceLocator.authenticationService)
        errorVM.error = "Failed to connect to the server. Please check your network connection."

        let surveyVM_mc = OnboardingViewModel(supabaseService: serviceLocator.supabaseService, authService: serviceLocator.authenticationService)
        surveyVM_mc.questions = [
            QuestionDTO(id: 1, text: "What is your primary goal?", type: "multiple_choice", options: ["Fitness", "Productivity", "Learning", "Finance"])
        ]

        let surveyVM_text = OnboardingViewModel(supabaseService: serviceLocator.supabaseService, authService: serviceLocator.authenticationService)
        surveyVM_text.questions = [
            QuestionDTO(id: 2, text: "What is one thing you want to improve?", type: "text", options: nil)
        ]
        surveyVM_text.currentIndex = 0
        
        return Group {
            OnboardingView(viewModel: loadingVM, onComplete: {})
                .previewDisplayName("Loading State")

            OnboardingView(viewModel: errorVM, onComplete: {})
                .previewDisplayName("Error State")
            
            OnboardingView(viewModel: surveyVM_mc, onComplete: {})
                .previewDisplayName("Multiple Choice Question")

            OnboardingView(viewModel: surveyVM_text, onComplete: {})
                .previewDisplayName("Text Input Question")
        }
    }
}
#endif