import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    
    // Animation states
    @State private var emailFieldOffset: CGFloat = 50
    @State private var passwordFieldOffset: CGFloat = 50
    @State private var emailFieldOpacity: Double = 0
    @State private var passwordFieldOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: Up2Spacing.xl) {
                    headerView
                    
                    switch viewModel.loginState {
                    case .inputCredentials:
                        loginFormView
                    case .completed:
                        loginCompletedView
                    case .error(let message):
                        errorView(message: message)
                    default:
                        loginFormView
                    }
                    
                    Spacer()
                    
                    // Link to registration for new users
                    registrationLinkView
                }
                .padding(.horizontal, Up2Spacing.screenEdge)
                .opacity(backgroundOpacity)
            }
            .navigationBarHidden(true)
            .onAppear {
                startAnimations()
            }
        }
    }
    
    // MARK: - Background View
    private var backgroundView: some View {
        ZStack {
            // Base gradient - black and blue theme
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.0, green: 0.0, blue: 0.0), // Pure black
                    Color(red: 0.05, green: 0.05, blue: 0.1), // Dark blue-black
                    Color(red: 0.0, green: 0.1, blue: 0.2), // Deep blue
                    Color(red: 0.0, green: 0.0, blue: 0.0)  // Pure black
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Subtle blue accent overlay
            Color(red: 0.0, green: 0.2, blue: 0.4).opacity(0.1)
        }
        .ignoresSafeArea()
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Logo
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            
            Text("Welcome Back")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textOnPrimary)
                .multilineTextAlignment(.center)
            
            Text("Sign in to your account to continue discovering events")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, Up2Spacing.xxxl)
    }
    
    // MARK: - Login Form View
    private var loginFormView: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Email input field
            emailField
            
            // Password input field
            passwordField
            
            // Sign in button
            signInButton
        }
        .offset(y: emailFieldOffset)
        .opacity(emailFieldOpacity)
    }
    
    // MARK: - Email Field
    private var emailField: some View {
            VStack(alignment: .leading, spacing: Up2Spacing.xs) {
                Text("Email Address")
                    .font(Up2Typography.caption.weight(.medium))
                    .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                
                HStack {
                    Image(systemName: "envelope.fill")
                        .foregroundColor(Up2Colors.textOnPrimary.opacity(0.6))
                        .frame(width: 20)
                    
                    TextField("Enter your email address", text: Binding(
                        get: { viewModel.loginData.emailAddress },
                        set: { viewModel.updateEmailAddress($0) }
                    ))
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(Up2Typography.body)
                    .foregroundColor(Up2Colors.textOnPrimary)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.vertical, Up2Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Up2Colors.surfaceElevated.opacity(0.2))
                    .stroke(
                        viewModel.emailValidation.errorMessage != nil ? 
                        Up2Colors.error : Up2Colors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Error message
            if let errorMessage = viewModel.emailValidation.errorMessage {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                    .padding(.leading, Up2Spacing.lg)
            }
        }
    }
    
    // MARK: - Password Field
    private var passwordField: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            Text("Password")
                .font(Up2Typography.caption.weight(.medium))
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(Up2Colors.textOnPrimary.opacity(0.6))
                    .frame(width: 20)
                
                SecureField("Enter your password", text: Binding(
                    get: { viewModel.loginData.password },
                    set: { viewModel.updatePassword($0) }
                ))
                .textFieldStyle(PlainTextFieldStyle())
                .font(Up2Typography.body)
                .foregroundColor(Up2Colors.textOnPrimary)
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.vertical, Up2Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Up2Colors.surfaceElevated.opacity(0.2))
                    .stroke(
                        viewModel.passwordValidation.errorMessage != nil ? 
                        Up2Colors.error : Up2Colors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            // Error message
            if let errorMessage = viewModel.passwordValidation.errorMessage {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                    .padding(.leading, Up2Spacing.lg)
            }
        }
    }
    
    // MARK: - Sign In Button
    private var signInButton: some View {
        Button(action: {
            viewModel.signIn()
        }) {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Up2Colors.textOnPrimary))
                        .scaleEffect(0.8)
                } else {
                    Text("Sign In")
                        .font(Up2Typography.buttonLarge.weight(.semibold))
                }
            }
            .foregroundColor(Up2Colors.textOnPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(red: 0.0, green: 0.48, blue: 1.0), // Blue
                        Color(red: 0.0, green: 0.32, blue: 0.8)  // Darker blue
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: Up2Colors.primary.opacity(0.3), radius: 10, x: 0, y: 5)
            .scaleEffect(buttonScale)
        }
        .disabled(viewModel.isLoading || !viewModel.isCurrentInputValid)
        .animation(.easeInOut(duration: 0.2), value: buttonScale)
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.1)) {
                buttonScale = 0.95
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.easeInOut(duration: 0.1)) {
                    buttonScale = 1.0
                }
            }
        }
    }
    
    // MARK: - Login Completed View
    private var loginCompletedView: some View {
        VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Up2Colors.success)
            
            Text("Welcome Back!")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textOnPrimary)
            
            Text("You have successfully signed in to your account.")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Up2Button(
                "Continue",
                style: .primary,
                size: .large
            ) {
                // Navigation is handled automatically by LoginViewModel
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: Up2Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Up2Colors.error)
            
            Text("Sign In Error")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textOnPrimary)
            
            Text(message)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Up2Button(
                "Try Again",
                style: .primary,
                size: .large
            ) {
                viewModel.resetLogin()
            }
        }
    }
    
    // MARK: - Registration Link View
    private var registrationLinkView: some View {
        VStack(spacing: Up2Spacing.xs) {
            Text("Don't have an account?")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            Button("Create one →") {
                // Navigate to registration view
                // Navigate to registration
            }
            .font(Up2Typography.buttonMedium)
            .foregroundColor(Color(red: 0.0, green: 0.48, blue: 1.0)) // Blue color
        }
        .padding(.bottom, Up2Spacing.xl)
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            emailFieldOffset = 0
            emailFieldOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.4)) {
            passwordFieldOffset = 0
            passwordFieldOpacity = 1.0
        }
    }
}

#Preview {
    LoginView()
        .environmentObject(AppStateManager())
} 