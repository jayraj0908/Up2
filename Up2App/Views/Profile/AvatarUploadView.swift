import SwiftUI
import UIKit

struct AvatarUploadView: View {
    @StateObject private var viewModel = AvatarUploadViewModel()
    @Binding var selectedImage: UIImage?
    @Binding var avatarURL: String?
    
    let size: CGFloat
    let userId: UUID
    
    init(selectedImage: Binding<UIImage?>, avatarURL: Binding<String?>, size: CGFloat = 120, userId: UUID) {
        self._selectedImage = selectedImage
        self._avatarURL = avatarURL
        self.size = size
        self.userId = userId
    }
    
    var body: some View {
        VStack(spacing: Up2Spacing.lg) {
            // Avatar Display using Up2Avatar component
            Button(action: viewModel.showImagePicker) {
                Up2Avatar(
                    imageURL: selectedImage != nil ? nil : avatarURL,
                    initials: "UP",
                    size: .custom(size),
                    style: .circle
                )
                        .overlay(
                    // Camera Icon Overlay
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                Image(systemName: "camera.fill")
                                .foregroundColor(Up2Colors.textOnPrimary)
                                .padding(Up2Spacing.sm)
                                .background(Up2Colors.primary)
                                    .clipShape(Circle())
                                .shadow(color: Up2Colors.primary.opacity(0.3), radius: 4, x: 0, y: 2)
                                .offset(x: -Up2Spacing.xs, y: -Up2Spacing.xs)
                        }
                    }
                    .opacity(viewModel.isUploading ? 0 : 1)
                )
            }
            .disabled(viewModel.isUploading)
            
            // Upload Status
            if viewModel.isUploading {
                VStack(spacing: Up2Spacing.xs) {
                    Text("Uploading...")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    ProgressView(value: viewModel.uploadProgress)
                        .progressViewStyle(LinearProgressViewStyle(tint: Up2Colors.primary))
                        .frame(maxWidth: 200)
                }
            } else if let errorMessage = viewModel.errorMessage {
                VStack(spacing: Up2Spacing.sm) {
                    Text("Upload Failed")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.error)
                    
                    Text(errorMessage)
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    Up2Button(
                        "Try Again",
                        style: .secondary,
                        size: .small
                    ) {
                        viewModel.retryUpload()
                    }
                }
            } else if viewModel.uploadSuccess {
                HStack(spacing: Up2Spacing.xs) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Up2Colors.success)
                    
                    Text("Photo uploaded successfully")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.success)
                }
            }
            
            // Action Buttons
            if selectedImage != nil || avatarURL != nil {
                HStack(spacing: Up2Spacing.sm) {
                    Up2Button(
                        "Change Photo",
                        style: .secondary,
                        size: .small
                    ) {
                        viewModel.showImagePicker()
                    }
                    .disabled(viewModel.isUploading)
                    
                    Up2Button(
                        "Remove",
                        style: .ghost,
                        size: .small
                    ) {
                        Task {
                            await viewModel.removeAvatar()
                        }
                    }
                    .disabled(viewModel.isUploading)
                }
            } else {
                Up2Button(
                    "Add Photo",
                    style: .secondary,
                    size: .medium
                ) {
                    viewModel.showImagePicker()
                }
                .disabled(viewModel.isUploading)
            }
        }
        .sheet(isPresented: $viewModel.showingImagePicker) {
            ImagePicker(image: $selectedImage) { image in
                if let image = image {
                    Task {
                        await viewModel.uploadAvatar(image: image, userId: userId)
                    }
                }
            }
        }
        .actionSheet(isPresented: $viewModel.showingActionSheet) {
            ActionSheet(
                title: Text("Select Photo")
                    .font(Up2Typography.heading3),
                buttons: [
                    .default(Text("Camera")) {
                        viewModel.sourceType = .camera
                        viewModel.showingImagePicker = true
                    },
                    .default(Text("Photo Library")) {
                        viewModel.sourceType = .photoLibrary
                        viewModel.showingImagePicker = true
                    },
                    .cancel()
                ]
            )
        }
        .onChange(of: selectedImage) { _, image in
            if let image = image {
                Task {
                    await viewModel.uploadAvatar(image: image, userId: userId)
                }
            }
        }
    }
}

// MARK: - Avatar Upload View Model

@MainActor
class AvatarUploadViewModel: ObservableObject {
    @Published var isUploading = false
    @Published var uploadProgress: Double = 0.0
    @Published var uploadSuccess = false
    @Published var errorMessage: String?
    @Published var showingImagePicker = false
    @Published var showingActionSheet = false
    @Published var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func showImagePicker() {
        clearMessages()
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            showingActionSheet = true
        } else {
            sourceType = .photoLibrary
            showingImagePicker = true
        }
    }
    
    func uploadAvatar(image: UIImage, userId: UUID) async {
        isUploading = true
        errorMessage = nil
        uploadSuccess = false
        uploadProgress = 0.0
        
        do {
            // Create avatar upload
            let avatarUpload = AvatarUpload(image: image, userId: userId)
            
            // Simulate upload progress
            for i in 1...10 {
                uploadProgress = Double(i) / 10.0
                try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            }
            
            // Upload to storage service
            let avatarURL = try await ProfileService.shared.uploadAvatar(avatarUpload)
            
            uploadSuccess = true
            
            // Clear success message after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.uploadSuccess = false
            }
            
        } catch {
            errorMessage = "Failed to upload photo: \(error.localizedDescription)"
        }
        
        isUploading = false
        uploadProgress = 0.0
    }
    
    func removeAvatar() async {
        isUploading = true
        errorMessage = nil
        
        do {
            // Note: In a real implementation, would need avatar URL to delete
            // For now, just clear the local state
            uploadSuccess = false
        } catch {
            errorMessage = "Failed to remove photo: \(error.localizedDescription)"
        }
        
        isUploading = false
    }
    
    func retryUpload() {
        clearMessages()
        showImagePicker()
    }
    
    private func clearMessages() {
        errorMessage = nil
        uploadSuccess = false
    }
    
    // Note: Image compression is handled by AvatarUpload model
}

// Note: AvatarError is defined in ProfileModels.swift

// MARK: - Image Picker

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    let onImageSelected: (UIImage?) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.image = editedImage
                parent.onImageSelected(editedImage)
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.image = originalImage
                parent.onImageSelected(originalImage)
            }
            
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}

#Preview {
            AvatarUploadView(
        selectedImage: .constant(nil),
        avatarURL: .constant(nil),
                    userId: UUID()
                )
} 