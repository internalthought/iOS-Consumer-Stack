import SwiftUI

struct SurveyView: View {
    @ObservedObject var viewModel: SurveyViewModel
    var onComplete: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            if let question = viewModel.currentQuestion() {
                Text(question.text)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
                    .accessibilityIdentifier("SurveyQuestionText")

                VStack(spacing: 16) {
                    switch question.type {
                    case "text":
                        TextField(
                            String(localized: "survey.text.placeholder"),
                            text: Binding<String>(
                                get: { viewModel.responses[question.id] ?? "" },
                                set: { viewModel.responses[question.id] = $0 }
                            )
                        )
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal)

                        Button(action: {
                            let answer = viewModel.responses[question.id] ?? ""
                            viewModel.selectResponse(for: question.id, response: answer)
                            if !viewModel.hasNext() {
                                onComplete()
                            } else {
                                _ = viewModel.nextQuestion()
                            }
                        }) {
                            Text(String(localized: "generic.next"))
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background((viewModel.responses[question.id] ?? "").isEmpty ? Color.gray.opacity(0.3) : Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                        .disabled((viewModel.responses[question.id] ?? "").isEmpty)
                        .padding(.horizontal)

                    case "multiple_choice", "single_choice", "rating":
                        if let options = question.options {
                            ForEach(options, id: \.self) { option in
                                Button(action: {
                                    viewModel.selectResponse(for: question.id, response: option)
                                    if !viewModel.hasNext() {
                                        onComplete()
                                    } else {
                                        _ = viewModel.nextQuestion()
                                    }
                                }) {
                                    Text(option)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                }
                                .accessibilityIdentifier("SurveyOption_\(option)")
                            }
                        } else {
                            Text(String(localized: "survey.options.missing"))
                                .foregroundColor(.secondary)
                        }
                    default:
                        Text(String(localized: "survey.unsupported_type"))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                ProgressView(value: viewModel.progress)
                    .padding(.horizontal)
                    .padding(.bottom)

            } else if viewModel.isLoading {
                ProgressView(String(localized: "survey.loading"))
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle.portrait")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary)
                    Text(String(localized: "survey.empty.title"))
                        .font(.headline)
                    Text(String(localized: "survey.empty.subtitle"))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.loadQuestions()
                await viewModel.attachUserAndFlushIfPossible()
            }
        }
        .onChange(of: viewModel.isCompleted) {
            if viewModel.isCompleted {
                onComplete()
            }
        }
    }
}

#Preview {
    SurveyView(
        viewModel: SurveyViewModel(service: MockSupabaseService(), surveyId: 1),
        onComplete: {}
    )
}

class MockSupabaseService: SupabaseServiceProtocol {
    func fetchOnboardingScreens(userProperty: String) async throws -> [OnboardingScreenDTO] {
        return []
    }

    func fetchSurveyQuestions(surveyId: Int) async throws -> [QuestionDTO] {
        return [QuestionDTO(id: 1, text: "Sample Question", type: "text", options: nil)]
    }

    func saveSurveyResponses(_ responses: [SurveyResponseDTO], for userId: String) async throws {}

    func linkPurchaser(withID identifier: String) async throws {}

    func createUser(_ userProfile: UserProfileDTO) async throws -> UserProfileDTO {
        return userProfile
    }

    func updateUser(userId: String, with userProfile: UserProfileDTO) async throws -> UserProfileDTO {
        return userProfile
    }

    func getCurrentUser() async throws -> UserProfileDTO? {
        return nil
    }

    func getUserSubscriptionStatus(userId: String) async throws -> Bool {
        return false
    }

    func syncSubscriptionStateFromClient(isPremium: Bool, subscriptionStatus: String?) async throws {}

    func deleteCurrentUserAccount() async throws { }
}