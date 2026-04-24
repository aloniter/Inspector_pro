import SwiftUI

struct LoginView: View {
    @Environment(AuthService.self) private var authService

    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @FocusState private var focusedField: LoginField?

    private enum LoginField { case email, password }

    // Design accent — blueprint blue
    private let accent = Color(red: 47/255, green: 111/255, blue: 229/255)

    var body: some View {
        ZStack {
            // Background
            Color(red: 250/255, green: 250/255, blue: 249/255)
                .ignoresSafeArea()

            // Glow backdrop (radial gradient from top)
            RadialGradient(
                colors: [accent.opacity(0.10), .clear],
                center: UnitPoint(x: 0.5, y: 0.0),
                startRadius: 0,
                endRadius: 340
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // ── App icon + tagline ─────────────────────────────────────
                VStack(spacing: 18) {
                    Image("AppLogo")
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 132, height: 132)
                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                        .shadow(color: Color(red: 12/255, green: 24/255, blue: 52/255).opacity(0.22),
                                radius: 20, x: 0, y: 18)
                        .shadow(color: Color(red: 12/255, green: 24/255, blue: 52/255).opacity(0.10),
                                radius: 5, x: 0, y: 4)

                    Text("מערכת לניהול דוחות")
                        .font(.system(size: 15.5))
                        .foregroundStyle(Color(red: 107/255, green: 114/255, blue: 128/255))
                }
                .padding(.bottom, 40)

                // ── Form ──────────────────────────────────────────────────
                VStack(spacing: 14) {

                    // Email
                    fieldContainer(
                        label: "אימייל",
                        isFocused: focusedField == .email,
                        hasError: false
                    ) {
                        Image(systemName: "envelope")
                            .font(.system(size: 16))
                            .foregroundStyle(focusedField == .email ? accent : .init(red: 156/255, green: 163/255, blue: 175/255))
                            .frame(width: 20)

                        TextField("name@company.com", text: $email)
                            .focused($focusedField, equals: .email)
                            .keyboardType(.emailAddress)
                            .textContentType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                            .font(.system(size: 17))
                            .foregroundStyle(Color(red: 17/255, green: 24/255, blue: 39/255))
                            .environment(\.layoutDirection, .leftToRight)
                            .multilineTextAlignment(.leading)
                            .submitLabel(.next)
                            .onSubmit { focusedField = .password }
                    }

                    // Password
                    fieldContainer(
                        label: "סיסמה",
                        isFocused: focusedField == .password,
                        hasError: errorMessage != nil
                    ) {
                        Image(systemName: "lock")
                            .font(.system(size: 16))
                            .foregroundStyle(focusedField == .password ? accent : .init(red: 156/255, green: 163/255, blue: 175/255))
                            .frame(width: 20)

                        Group {
                            if showPassword {
                                TextField("", text: $password)
                            } else {
                                SecureField("", text: $password)
                            }
                        }
                        .focused($focusedField, equals: .password)
                        .font(.system(size: 17))
                        .foregroundStyle(Color(red: 17/255, green: 24/255, blue: 39/255))
                        .textContentType(.password)
                        .autocorrectionDisabled()
                        .autocapitalization(.none)
                        .environment(\.layoutDirection, .leftToRight)
                        .multilineTextAlignment(.leading)
                        .submitLabel(.go)
                        .onSubmit { login() }

                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .font(.system(size: 16))
                                .foregroundStyle(Color(red: 156/255, green: 163/255, blue: 175/255))
                        }
                        .buttonStyle(.plain)
                    }

                    // Error row
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.circle")
                            .font(.system(size: 14))
                            .foregroundStyle(Color(red: 229/255, green: 72/255, blue: 77/255))
                        Text(errorMessage ?? "")
                            .font(.system(size: 13.5, weight: .medium))
                            .foregroundStyle(Color(red: 196/255, green: 35/255, blue: 42/255))
                        Spacer()
                    }
                    .padding(.horizontal, 4)
                    .frame(height: 20)
                    .opacity(errorMessage != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.16), value: errorMessage)

                    // Login button
                    let inactive = email.isEmpty || password.isEmpty || isLoading
                    Button(action: login) {
                        ZStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                                    .scaleEffect(0.9)
                            } else {
                                Text("התחברות")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(inactive ? Color(red: 200/255, green: 211/255, blue: 232/255) : accent)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .shadow(color: accent.opacity(inactive ? 0 : 0.32), radius: 7, x: 0, y: 4)
                        .animation(.easeInOut(duration: 0.12), value: inactive)
                    }
                    .disabled(inactive)
                    .padding(.top, 4)

                    // Contact admin link
                    Link(destination: URL(string: "mailto:iteralon@gmail.com")!) {
                        HStack(spacing: 4) {
                            Text("נתקלת בבעיה?")
                                .foregroundStyle(Color(red: 138/255, green: 148/255, blue: 166/255))
                            Text("פנה למנהל המערכת")
                                .foregroundStyle(accent)
                                .fontWeight(.medium)
                        }
                        .font(.system(size: 13.5))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 28)

                Spacer()
                Spacer()

                // Version footer
                Text("v\(appVersion) · Secure sign-in")
                    .font(.system(size: 11))
                    .tracking(0.4)
                    .foregroundStyle(Color(red: 184/255, green: 190/255, blue: 201/255))
                    .environment(\.layoutDirection, .leftToRight)
                    .padding(.bottom, 36)
            }
        }
        .environment(\.layoutDirection, .rightToLeft)
    }

    // MARK: - Field container builder

    @ViewBuilder
    private func fieldContainer<Content: View>(
        label: String,
        isFocused: Bool,
        hasError: Bool,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .trailing, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color(red: 107/255, green: 114/255, blue: 128/255))
                .padding(.horizontal, 4)
                .frame(maxWidth: .infinity, alignment: .trailing)

            HStack(spacing: 10) {
                content()
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        hasError
                            ? Color(red: 229/255, green: 72/255, blue: 77/255)
                            : isFocused
                                ? accent.opacity(0.55)
                                : Color(red: 60/255, green: 60/255, blue: 67/255).opacity(0.18),
                        lineWidth: 1
                    )
            )
            .shadow(color: isFocused ? accent.opacity(0.12) : .clear, radius: 4)
            .animation(.easeInOut(duration: 0.12), value: isFocused)
            .environment(\.layoutDirection, .leftToRight)
        }
    }

    // MARK: - Actions

    private func login() {
        guard !email.isEmpty, !password.isEmpty, !isLoading else { return }
        focusedField = nil
        isLoading = true
        errorMessage = nil

        Task {
            do {
                try await authService.signIn(email: email, password: password)
                // Auth state observer handles navigation
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
        if error is AuthServiceError {
            return error.localizedDescription
        }
        return "שגיאת כניסה. יש לבדוק את הפרטים ולנסות שוב."
    }

    // MARK: - Helpers

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }
}
