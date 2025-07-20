import SwiftUI

/// Up2 Design System Text Field Component
/// Provides consistent input styling with validation states and accessibility
struct Up2TextField: View {
    
    // MARK: - Field States
    
    enum FieldState {
        case normal
        case focused
        case error
        case success
        case disabled
    }
    
    enum FieldType {
        case text
        case email
        case password
        case phone
        case number
    }
    
    // MARK: - Properties
    
    @Binding var text: String
    let placeholder: String
    let label: String?
    let helperText: String?
    let errorText: String?
    let fieldType: FieldType
    let isRequired: Bool
    let isEnabled: Bool
    let maxLength: Int?
    
    @State private var isSecureField: Bool = true
    @State private var isFocused: Bool = false
    
    // MARK: - Initializer
    
    init(
        text: Binding<String>,
        placeholder: String,
        label: String? = nil,
        helperText: String? = nil,
        errorText: String? = nil,
        fieldType: FieldType = .text,
        isRequired: Bool = false,
        isEnabled: Bool = true,
        maxLength: Int? = nil
    ) {
        self._text = text
        self.placeholder = placeholder
        self.label = label
        self.helperText = helperText
        self.errorText = errorText
        self.fieldType = fieldType
        self.isRequired = isRequired
        self.isEnabled = isEnabled
        self.maxLength = maxLength
        
        // Set initial secure field state for password
        self._isSecureField = State(initialValue: fieldType == .password)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.xs) {
            // Label
            if let label = label {
                HStack(spacing: Up2Spacing.xs) {
                    Text(label)
                        .font(Up2Typography.label)
                        .foregroundColor(labelColor)
                    
                    if isRequired {
                        Text("*")
                            .font(Up2Typography.label)
                            .foregroundColor(Up2Colors.Raw.error)
                    }
                    
                    Spacer()
                }
            }
            
            // Input Field
            HStack(spacing: Up2Spacing.md) {
                inputField
                
                // Password visibility toggle
                if fieldType == .password {
                    Button(action: {
                        isSecureField.toggle()
                    }) {
                        Image(systemName: isSecureField ? "eye.slash" : "eye")
                            .foregroundColor(Up2Colors.Raw.primaryLight)
                            .frame(width: 20, height: 20)
                    }
                    .disabled(!isEnabled)
                }
            }
            .padding(.horizontal, Up2Spacing.lg)
            .padding(.vertical, Up2Spacing.md)
            .background(fieldBackgroundColor)
            .cornerRadius(Up2Spacing.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: Up2Spacing.radiusMD)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .onTapGesture {
                if isEnabled {
                    isFocused = true
                }
            }
            
            // Helper or Error Text
            if let errorText = errorText, !errorText.isEmpty {
                Text(errorText)
                    .font(Up2Typography.captionMedium)
                    .foregroundColor(Up2Colors.Raw.error)
            } else if let helperText = helperText, !helperText.isEmpty {
                Text(helperText)
                    .font(Up2Typography.captionMedium)
                    .foregroundColor(helperTextColor)
            }
            
            // Character count
            if let maxLength = maxLength {
                HStack {
                    Spacer()
                    Text("\(text.count)/\(maxLength)")
                        .font(Up2Typography.captionSmall)
                        .foregroundColor(characterCountColor)
                }
            }
        }
    }
    
    // MARK: - Input Field
    
    @ViewBuilder
    private var inputField: some View {
        switch fieldType {
        case .password:
            if isSecureField {
                SecureField(placeholder, text: $text)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
            } else {
                TextField(placeholder, text: $text)
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.Raw.primaryLight)
            }
            
        case .email:
            TextField(placeholder, text: $text)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.Raw.primaryLight)
            
        case .phone:
            TextField(placeholder, text: $text)
                .keyboardType(.phonePad)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.Raw.primaryLight)
            
        case .number:
            TextField(placeholder, text: $text)
                .keyboardType(.numberPad)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.Raw.primaryLight)
            
        case .text:
            TextField(placeholder, text: $text)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.Raw.primaryLight)
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentState: FieldState {
        if !isEnabled {
            return .disabled
        } else if errorText != nil && !errorText!.isEmpty {
            return .error
        } else if isFocused {
            return .focused
        } else {
            return .normal
        }
    }
    
    private var fieldBackgroundColor: Color {
        switch currentState {
        case .normal, .success:
            return Up2Colors.Raw.surfaceLight
        case .focused:
            return Up2Colors.Raw.surfaceLight
        case .error:
            return Up2Colors.Raw.surfaceLight
        case .disabled:
            return Up2Colors.Raw.backgroundSecondaryLight
        }
    }
    
    private var borderColor: Color {
        switch currentState {
        case .normal:
            return Color.gray.opacity(0.3)
        case .focused:
            return Up2Colors.Raw.primaryLight
        case .error:
            return Up2Colors.Raw.error
        case .success:
            return Up2Colors.Raw.success
        case .disabled:
            return Color.gray.opacity(0.2)
        }
    }
    
    private var borderWidth: CGFloat {
        switch currentState {
        case .normal:
            return 1
        case .focused, .error, .success:
            return 2
        case .disabled:
            return 1
        }
    }
    
    private var labelColor: Color {
        switch currentState {
        case .normal, .focused, .success:
            return Up2Colors.Raw.primaryLight
        case .error:
            return Up2Colors.Raw.error
        case .disabled:
            return Color.gray
        }
    }
    
    private var helperTextColor: Color {
        isEnabled ? Color.gray : Color.gray.opacity(0.6)
    }
    
    private var characterCountColor: Color {
        guard let maxLength = maxLength else { return Color.gray }
        let ratio = Double(text.count) / Double(maxLength)
        
        if ratio >= 1.0 {
            return Up2Colors.Raw.error
        } else if ratio >= 0.8 {
            return Up2Colors.Raw.warning
        } else {
            return Color.gray
        }
    }
}

// MARK: - Text Field Styling
// Note: Styles are applied inline for better SwiftUI compatibility

// MARK: - Convenience Initializers

extension Up2TextField {
    
    /// Email text field
    static func email(
        text: Binding<String>,
        placeholder: String = "Enter email address",
        label: String? = "Email",
        helperText: String? = nil,
        errorText: String? = nil,
        isRequired: Bool = false
    ) -> Up2TextField {
        Up2TextField(
            text: text,
            placeholder: placeholder,
            label: label,
            helperText: helperText,
            errorText: errorText,
            fieldType: .email,
            isRequired: isRequired
        )
    }
    
    /// Password text field
    static func password(
        text: Binding<String>,
        placeholder: String = "Enter password",
        label: String? = "Password",
        helperText: String? = nil,
        errorText: String? = nil,
        isRequired: Bool = false
    ) -> Up2TextField {
        Up2TextField(
            text: text,
            placeholder: placeholder,
            label: label,
            helperText: helperText,
            errorText: errorText,
            fieldType: .password,
            isRequired: isRequired
        )
    }
    
    /// Phone text field
    static func phone(
        text: Binding<String>,
        placeholder: String = "Enter phone number",
        label: String? = "Phone Number",
        helperText: String? = nil,
        errorText: String? = nil,
        isRequired: Bool = false
    ) -> Up2TextField {
        Up2TextField(
            text: text,
            placeholder: placeholder,
            label: label,
            helperText: helperText,
            errorText: errorText,
            fieldType: .phone,
            isRequired: isRequired
        )
    }
    
    /// Standard text field
    static func text(
        text: Binding<String>,
        placeholder: String,
        label: String? = nil,
        helperText: String? = nil,
        errorText: String? = nil,
        isRequired: Bool = false,
        maxLength: Int? = nil
    ) -> Up2TextField {
        Up2TextField(
            text: text,
            placeholder: placeholder,
            label: label,
            helperText: helperText,
            errorText: errorText,
            fieldType: .text,
            isRequired: isRequired,
            maxLength: maxLength
        )
    }
}

// MARK: - Preview

#if DEBUG
struct Up2TextField_Previews: PreviewProvider {
    @State static var emailText = ""
    @State static var passwordText = ""
    @State static var phoneText = ""
    @State static var textWithError = ""
    @State static var disabledText = "Disabled field"
    
    static var previews: some View {
        ScrollView {
            VStack(spacing: Up2Spacing.xl) {
                // Email field
                Up2TextField.email(
                    text: $emailText,
                    helperText: "We'll never share your email"
                )
                
                // Password field
                Up2TextField.password(
                    text: $passwordText,
                    helperText: "Must be at least 8 characters",
                    isRequired: true
                )
                
                // Phone field
                Up2TextField.phone(
                    text: $phoneText
                )
                
                // Text field with error
                Up2TextField(
                    text: $textWithError,
                    placeholder: "Enter your name",
                    label: "Full Name",
                    errorText: "This field is required",
                    fieldType: .text,
                    isRequired: true
                )
                
                // Disabled field
                Up2TextField(
                    text: $disabledText,
                    placeholder: "Disabled field",
                    label: "Disabled Field",
                    fieldType: .text,
                    isEnabled: false
                )
                
                // Text field with character limit
                Up2TextField(
                    text: $textWithError,
                    placeholder: "Bio",
                    label: "Bio",
                    helperText: "Tell us about yourself",
                    fieldType: .text,
                    maxLength: 100
                )
            }
            .padding(Up2Spacing.xl)
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Up2TextField Variants")
    }
}
#endif 