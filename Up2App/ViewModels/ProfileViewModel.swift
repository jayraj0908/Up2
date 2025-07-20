import Foundation
import SwiftUI
import Combine

@MainActor
class ProfileViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var profile: ProfileData = ProfileData()
    @Published var selectedAvatarImage: UIImage?
    @Published var selectedVibeTags: [VibeTag] = []
    
    // Form fields
    @Published var name: String = ""
    @Published var handle: String = ""
    @Published var bio: String = ""
    
    // Privacy & Settings
    @Published var showEventHistory: Bool = true
    @Published var isProfileDiscoverable: Bool = true
    @Published var receiveNotifications: Bool = true
    
    // Validation
    @Published var validation = ProfileValidation()
    @Published var isFormValid: Bool = false
    
    // UI State
    @Published var isLoading: Bool = false
    @Published var isSaving: Bool = false
    @Published var errorMessage: String?
    @Published var successMessage: String?
    @Published var currentStep: ProfileCreationStep = .basicInfo
    
    // Handle availability checking
    @Published var isCheckingHandle: Bool = false
    @Published var handleAvailabilityMessage: String?
    
    // MARK: - Private Properties
    
    private let profileService = ProfileService.shared
    private let authService = SupabaseAuthService.shared
    private let eventService = EventService.shared
    private var cancellables = Set<AnyCancellable>()
    private var handleCheckTask: Task<Void, Never>?
    
    // MARK: - Initialization
    
    init() {
        setupValidation()
        setupHandleValidation()
    }
    
    // MARK: - Public Methods
    
    func loadProfile(for userId: UUID) async {
        isLoading = true
        errorMessage = nil
        
        do {
            if let existingProfile = try await profileService.getProfile(for: userId) {
                profile = existingProfile
                populateFields(from: existingProfile)
            }
        } catch {
            errorMessage = "Failed to load profile: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func loadCurrentUserProfile() async {
        guard let currentUser = authService.currentUser,
              let userId = UUID(uuidString: currentUser.id) else {
            errorMessage = "No authenticated user found or invalid user ID"
            return
        }
        
        await loadProfile(for: userId)
    }
    
    func createProfile() async {
        guard let currentUser = authService.currentUser else {
            errorMessage = "No authenticated user found"
            return
        }
        
        guard isFormValid else {
            errorMessage = "Please fix validation errors before saving"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            guard let userId = UUID(uuidString: currentUser.id) else {
                errorMessage = "Invalid user ID format"
                return
            }
            
            let newProfile = createProfileData(for: userId)
            let savedProfile = try await profileService.createProfile(newProfile, for: userId)
            profile = savedProfile
            successMessage = "Profile created successfully!"
            
            // Track profile creation event
            await eventService.trackProfileCreation(savedProfile, userId: userId)
            
            // Move to next step or complete
            if currentStep != .complete {
                currentStep = .complete
            }
        } catch {
            errorMessage = "Failed to create profile: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func updateProfile() async {
        guard let currentUser = authService.currentUser else {
            errorMessage = "No authenticated user found"
            return
        }
        
        guard isFormValid else {
            errorMessage = "Please fix validation errors before saving"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            guard let userId = UUID(uuidString: currentUser.id) else {
                errorMessage = "Invalid user ID format"
                return
            }
            
            let oldProfile = profile
            let updatedProfile = createProfileData(for: userId)
            let savedProfile = try await profileService.updateProfile(updatedProfile)
            profile = savedProfile
            successMessage = "Profile updated successfully!"
            
            // Track profile update events with specific changes
            await trackProfileChanges(oldProfile: oldProfile, newProfile: savedProfile, userId: userId)
        } catch {
            errorMessage = "Failed to update profile: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func deleteProfile() async {
        guard let currentUser = authService.currentUser else {
            errorMessage = "No authenticated user found"
            return
        }
        
        isSaving = true
        errorMessage = nil
        
        do {
            guard let userId = UUID(uuidString: currentUser.id) else {
                errorMessage = "Invalid user ID format"
                return
            }
            
            try await profileService.deleteProfile(for: userId)
            resetForm()
            successMessage = "Profile deleted successfully"
        } catch {
            errorMessage = "Failed to delete profile: \(error.localizedDescription)"
        }
        
        isSaving = false
    }
    
    func nextStep() {
        let allSteps = ProfileCreationStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex < allSteps.count - 1 {
            currentStep = allSteps[currentIndex + 1]
        }
    }
    
    func previousStep() {
        let allSteps = ProfileCreationStep.allCases
        if let currentIndex = allSteps.firstIndex(of: currentStep),
           currentIndex > 0 {
            currentStep = allSteps[currentIndex - 1]
        }
    }
    
    func canProceedToNextStep() -> Bool {
        switch currentStep {
        case .basicInfo:
            return validation.nameValidation.isValid && validation.handleValidation.isValid
        case .avatar:
            return true // Avatar is optional
        case .vibeTags:
            return !selectedVibeTags.isEmpty && validation.vibeTagsValidation.isValid
        case .bio:
            return validation.bioValidation.isValid
        case .complete:
            return false
        }
    }
    
    func resetForm() {
        profile = ProfileData()
        selectedAvatarImage = nil
        selectedVibeTags = []
        name = ""
        handle = ""
        bio = ""
        validation = ProfileValidation()
        currentStep = .basicInfo
        clearMessages()
    }
    
    func clearMessages() {
        errorMessage = nil
        successMessage = nil
        handleAvailabilityMessage = nil
    }
    
    // MARK: - Private Methods
    
    private func setupValidation() {
        // Real-time validation
        Publishers.CombineLatest4(
            $name.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $handle.debounce(for: .milliseconds(300), scheduler: RunLoop.main),
            $selectedVibeTags,
            $bio.debounce(for: .milliseconds(300), scheduler: RunLoop.main)
        )
        .map { name, handle, tags, bio in
            ProfileValidation(
                nameValidation: ProfileValidation.validateName(name),
                handleValidation: ProfileValidation.validateHandle(handle),
                vibeTagsValidation: ProfileValidation.validateVibeTags(tags),
                bioValidation: ProfileValidation.validateBio(bio)
            )
        }
        .assign(to: \.validation, on: self)
        .store(in: &cancellables)
        
        // Update form validity
        $validation
            .map { $0.isValid }
            .assign(to: \.isFormValid, on: self)
            .store(in: &cancellables)
    }
    
    private func setupHandleValidation() {
        $handle
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] handle in
                self?.checkHandleAvailability(handle)
            }
            .store(in: &cancellables)
    }
    
    private func checkHandleAvailability(_ handle: String) {
        // Cancel previous check
        handleCheckTask?.cancel()
        
        guard !handle.isEmpty,
              handle.count >= 3,
              validation.handleValidation.isValid else {
            handleAvailabilityMessage = nil
            return
        }
        
        // Skip check if it's the current user's handle
        if handle.lowercased() == profile.handle.lowercased() {
            handleAvailabilityMessage = nil
            return
        }
        
        isCheckingHandle = true
        handleAvailabilityMessage = nil
        
        handleCheckTask = Task {
            let isAvailable = await profileService.isHandleAvailable(handle)
            
            if !Task.isCancelled {
                isCheckingHandle = false
                handleAvailabilityMessage = isAvailable ? "✓ Username is available" : "✗ Username is taken"
            }
        }
    }
    
    private func populateFields(from profile: ProfileData) {
        self.name = profile.name
        self.handle = profile.handle
        self.bio = profile.bio
        self.selectedVibeTags = profile.vibeTags
    }
    
    // MARK: - Event Tracking Helpers
    
    private func trackProfileChanges(oldProfile: ProfileData, newProfile: ProfileData, userId: UUID) async {
        var changes: [String: Any] = [:]
        
        // Track name changes
        if oldProfile.name != newProfile.name {
            changes["old_name"] = oldProfile.name
            changes["new_name"] = newProfile.name
        }
        
        // Track handle changes
        if oldProfile.handle != newProfile.handle {
            changes["old_handle"] = oldProfile.handle
            changes["new_handle"] = newProfile.handle
        }
        
        // Track bio changes
        if oldProfile.bio != newProfile.bio {
            await eventService.trackBioUpdate(userId: userId, oldBio: oldProfile.bio, newBio: newProfile.bio)
        }
        
        // Track avatar changes
        if oldProfile.avatar != newProfile.avatar {
            if let newAvatarURL = newProfile.avatar {
                await eventService.trackAvatarUpload(userId: userId, avatarURL: newAvatarURL)
            }
            changes["avatar_changed"] = true
        }
        
        // Track vibe tags changes
        if oldProfile.vibeTags != newProfile.vibeTags {
            await eventService.trackVibeTagsUpdate(userId: userId, oldTags: oldProfile.vibeTags, newTags: newProfile.vibeTags)
        }
        
        // Track general profile update if there were other changes
        if !changes.isEmpty {
            await eventService.trackProfileUpdate(userId: userId, changes: changes)
        }
    }
    
    private func createProfileData(for userId: UUID) -> ProfileData {
        ProfileData(
            id: userId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            handle: handle.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(),
            avatar: profile.avatar, // This will be set by avatar upload
            vibeTags: selectedVibeTags,
            bio: bio.trimmingCharacters(in: .whitespacesAndNewlines),
            createdAt: profile.createdAt,
            updatedAt: Date()
        )
    }
}

// MARK: - Profile Creation Steps Helper

extension ProfileViewModel {
    var currentStepTitle: String {
        currentStep.title
    }
    
    var currentStepNumber: Int {
        ProfileCreationStep.allCases.firstIndex(of: currentStep) ?? 0
    }
    
    var totalSteps: Int {
        ProfileCreationStep.allCases.count
    }
    
    var progressPercentage: Double {
        Double(currentStepNumber) / Double(totalSteps - 1)
    }
    
    var isLastStep: Bool {
        currentStep == .complete
    }
    
    var isFirstStep: Bool {
        currentStep == .basicInfo
    }
} 