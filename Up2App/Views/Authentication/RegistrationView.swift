import SwiftUI

struct RegistrationView: View {
    @StateObject private var viewModel = RegistrationViewModel()
    @EnvironmentObject var appStateManager: AppStateManager
    
    // Animation states
    @State private var formOffset: CGFloat = 50
    @State private var formOpacity: Double = 0
    @State private var buttonScale: CGFloat = 0.9
    @State private var backgroundOpacity: Double = 0
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                backgroundView
                
                VStack(spacing: Up2Spacing.xl) {
                    headerView
                    
                    switch viewModel.registrationState {
                    case .inputCredentials:
                        registrationFormView
                    case .completed:
                        registrationCompletedView
                    case .error(let message):
                        errorView(message: message)
                    default:
                        registrationFormView
                    }
                    
                    Spacer()
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
            // Base gradient - vibrant dark gradient (indigo → magenta)
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.0, blue: 0.3), // Deep indigo
                    Color(red: 0.3, green: 0.0, blue: 0.4), // Purple
                    Color(red: 0.5, green: 0.0, blue: 0.3), // Magenta
                    Color(red: 0.2, green: 0.0, blue: 0.2)  // Deep violet
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // UI Blur overlay
            Color.black.opacity(0.3)
                .blur(radius: 0)
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
            
            Text("Welcome to Up2")
                .font(Up2Typography.displayMedium)
                .foregroundColor(Up2Colors.textOnPrimary)
                .multilineTextAlignment(.center)
            
            Text("Sign up to connect with friends and discover what everyone's up to")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(.top, Up2Spacing.xxxl)
    }
    
    // MARK: - Registration Form View
    private var registrationFormView: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Email Input
            emailField
            
            // Password Input
            passwordField
            
            // Confirm Password Input
            confirmPasswordField
            
            // Continue Button
            continueButton
        }
        .offset(y: formOffset)
        .opacity(formOpacity)
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
                    get: { viewModel.registrationData.emailAddress },
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
                    get: { viewModel.registrationData.password },
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
            
            if let errorMessage = viewModel.passwordValidation.errorMessage {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                    .padding(.leading, Up2Spacing.lg)
            }
        }
    }
    
    // MARK: - Confirm Password Field
    private var confirmPasswordField: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            Text("Confirm Password")
                .font(Up2Typography.caption.weight(.medium))
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
            
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(Up2Colors.textOnPrimary.opacity(0.6))
                    .frame(width: 20)
                
                SecureField("Confirm your password", text: Binding(
                    get: { viewModel.registrationData.confirmPassword },
                    set: { viewModel.updateConfirmPassword($0) }
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
                        viewModel.confirmPasswordValidation.errorMessage != nil ? 
                        Up2Colors.error : Up2Colors.primary.opacity(0.3),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            
            if let errorMessage = viewModel.confirmPasswordValidation.errorMessage {
                Text(errorMessage)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                    .padding(.leading, Up2Spacing.lg)
            }
        }
    }
    
    // MARK: - Continue Button
    private var continueButton: some View {
        Up2Button(
            "Create Account",
            style: .primary,
            action: {
                Task {
                    await viewModel.signUp()
                }
            }
        )
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
    
    // MARK: - Registration Completed View
    private var registrationCompletedView: some View {
        VStack(spacing: Up2Spacing.xl) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundColor(Up2Colors.success)
            
            Text("Account Created!")
                .font(Up2Typography.heading2)
                .foregroundColor(Up2Colors.textOnPrimary)
            
            Text("Your account has been created successfully. You can now sign in with your email and password.")
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textOnPrimary.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Up2Button(
                "Sign In",
                style: .primary,
                size: .large
            ) {
                // Navigate back to login
                // Navigate to login
            }
        }
    }
    
    // MARK: - Error View
    private func errorView(message: String) -> some View {
        VStack(spacing: Up2Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundColor(Up2Colors.error)
            
            Text("Registration Error")
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
                viewModel.resetRegistration()
            }
        }
    }
    
    // MARK: - Animation Methods
    private func startAnimations() {
        withAnimation(.easeOut(duration: 0.8)) {
            backgroundOpacity = 1.0
        }
        
        withAnimation(.easeOut(duration: 0.6).delay(0.2)) {
            formOffset = 0
            formOpacity = 1.0
        }
    }
}

#Preview {
    RegistrationView()
        .environmentObject(AppStateManager())
} 