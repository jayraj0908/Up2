import XCTest
@testable import Up2App

final class ProfileViewModelTests: XCTestCase {
    var viewModel: ProfileViewModel!
    var mockProfileService: MockProfileService!
    var mockAvatarUploader: MockAvatarUploader!
    var mockVibeTagsManager: MockVibeTagsManager!
    
    override func setUp() {
        super.setUp()
        mockProfileService = MockProfileService()
        mockAvatarUploader = MockAvatarUploader()
        mockVibeTagsManager = MockVibeTagsManager()
        viewModel = ProfileViewModel(
            profileService: mockProfileService,
            avatarUploader: mockAvatarUploader,
            vibeTagsManager: mockVibeTagsManager
        )
    }
    
    override func tearDown() {
        viewModel = nil
        mockProfileService = nil
        mockAvatarUploader = nil
        mockVibeTagsManager = nil
        super.tearDown()
    }
    
    func testLoadProfile() async throws {
        // Prepare test data
        let testProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: "https://example.com/avatar.jpg",
            vibeTags: ["fun", "social"],
            bio: "Test bio"
        )
        mockProfileService.mockProfile = testProfile
        
        // Test successful load
        await viewModel.loadProfile(id: "test-id")
        XCTAssertEqual(viewModel.profile, testProfile)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        
        // Test load failure
        mockProfileService.shouldFail = true
        await viewModel.loadProfile(id: "test-id")
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testSaveProfile() async throws {
        // Prepare test data
        let testProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: nil,
            vibeTags: ["fun"],
            bio: "Test bio"
        )
        mockProfileService.mockProfile = testProfile
        
        // Test successful save
        await viewModel.saveProfile(testProfile)
        XCTAssertEqual(viewModel.profile, testProfile)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        
        // Test save failure
        mockProfileService.shouldFail = true
        await viewModel.saveProfile(testProfile)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testUploadAvatar() async throws {
        // Prepare test data
        let testImageData = "test-image-data".data(using: .utf8)!
        let expectedUrl = "https://example.com/avatar.jpg"
        mockAvatarUploader.mockUploadUrl = expectedUrl
        
        // Test successful upload
        await viewModel.uploadAvatar(imageData: testImageData)
        XCTAssertEqual(viewModel.profile?.avatarUrl, expectedUrl)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertNil(viewModel.error)
        
        // Test upload failure
        mockAvatarUploader.shouldFail = true
        await viewModel.uploadAvatar(imageData: testImageData)
        XCTAssertNotNil(viewModel.error)
        XCTAssertFalse(viewModel.isLoading)
    }
    
    func testVibeTagsManagement() {
        // Test adding tag
        viewModel.addVibeTag("fun")
        XCTAssertTrue(viewModel.profile?.vibeTags.contains("fun") ?? false)
        
        // Test removing tag
        viewModel.removeVibeTag("fun")
        XCTAssertFalse(viewModel.profile?.vibeTags.contains("fun") ?? true)
        
        // Test max tags limit
        for i in 1...5 {
            viewModel.addVibeTag("tag\(i)")
        }
        viewModel.addVibeTag("tag6")
        XCTAssertEqual(viewModel.profile?.vibeTags.count, 5)
    }
    
    func testHandleValidation() async {
        // Test available handle
        mockProfileService.mockHandleAvailable = true
        let isAvailable = await viewModel.checkHandleAvailability("newhandle")
        XCTAssertTrue(isAvailable)
        
        // Test taken handle
        mockProfileService.mockHandleAvailable = false
        let isTaken = await viewModel.checkHandleAvailability("takenhandle")
        XCTAssertFalse(isTaken)
    }
    
    func testProfileValidation() {
        // Test valid profile
        let validProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: nil,
            vibeTags: ["fun"],
            bio: "Test bio"
        )
        XCTAssertTrue(viewModel.validateProfile(validProfile))
        
        // Test invalid profile (empty name)
        var invalidProfile = validProfile
        invalidProfile.name = ""
        XCTAssertFalse(viewModel.validateProfile(invalidProfile))
        
        // Test invalid profile (invalid handle)
        invalidProfile = validProfile
        invalidProfile.handle = "test@user"
        XCTAssertFalse(viewModel.validateProfile(invalidProfile))
    }
}

// Mock Services for testing
private class MockProfileService {
    var mockProfile: ProfileData?
    var mockHandleAvailable = true
    var shouldFail = false
    
    func fetchProfile(id: String) async throws -> ProfileData {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        guard let profile = mockProfile else {
            throw NSError(domain: "MockError", code: -2)
        }
        return profile
    }
    
    func updateProfile(_ profile: ProfileData) async throws -> ProfileData {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        return profile
    }
    
    func isHandleAvailable(_ handle: String) async throws -> Bool {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        return mockHandleAvailable
    }
}

private class MockAvatarUploader {
    var mockUploadUrl: String?
    var shouldFail = false
    
    func uploadAvatar(imageData: Data, userId: String) async throws -> String {
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        return mockUploadUrl ?? ""
    }
}

private class MockVibeTagsManager {
    var selectedTags: Set<String> = []
    
    func addTag(_ tag: String) -> Bool {
        if selectedTags.count >= 5 {
            return false
        }
        selectedTags.insert(tag)
        return true
    }
    
    func removeTag(_ tag: String) -> Bool {
        selectedTags.remove(tag) != nil
    }
    
    func validateTags(_ tags: [String]) -> Bool {
        tags.count <= 5
    }
} 