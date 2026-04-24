import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService

    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Logo / Title
            VStack(spacing: 12) {
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 56))
                    .foregroundStyle(.blue)

                Text("Inspector Pro")
                    .font(.largeTitle.bold())

                Text("כניסה לחשבון")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 40)

            // Form
            VStack(spacing: 16) {
                VStack(alignment: .trailing, spacing: 6) {
                    Text("אימייל")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    TextField("", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .textFieldStyle(.roundedBorder)
                        .environment(\.layoutDirection, .leftToRight)
                }

                VStack(alignment: .trailing, spacing: 6) {
                    Text("סיסמה")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)

                    SecureField("", text: $password)
                        .textContentType(.password)
                        .textFieldStyle(.roundedBorder)
                        .environment(\.layoutDirection, .leftToRight)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }

                Button {
                    login()
                } label: {
                    Group {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("כניסה")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || email.isEmpty || password.isEmpty)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    private func login() {
        guard !email.isEmpty, !password.isEmpty else { return }

        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signIn(email: email, password: password)
                // Auth state observer handles navigation automatically
            } catch {
                await MainActor.run {
                    errorMessage = hebrewErrorMessage(for: error)
                    isLoading = false
                }
            }
        }
    }

    private func hebrewErrorMessage(for error: Error) -> String {
        let message = error.localizedDescription.lowercased()

        if message.contains("invalid login credentials") || message.contains("invalid_credentials") {
            return "אימייל או סיסמה שגויים. אנא נסה שוב."
        }
        if message.contains("email not confirmed") {
            return "חשבון זה טרם אומת. יש לפנות לתמיכה."
        }
        if message.contains("too many requests") || message.contains("rate limit") {
            return "יותר מדי ניסיונות כניסה. יש להמתין מספר דקות."
        }
        if message.contains("network") || message.contains("internet") || message.contains("offline") {
            return "אין חיבור לאינטרנט. יש לבדוק את החיבור ולנסות שוב."
        }

        // Fallback: use the service error description if it's already Hebrew
        if error is AuthServiceError {
            return error.localizedDescription
        }

        return "שגיאת כניסה. יש לבדוק את הפרטים ולנסות שוב."
    }
}
