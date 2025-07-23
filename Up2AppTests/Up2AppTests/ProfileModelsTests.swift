import XCTest
@testable import Up2App

final class ProfileModelsTests: XCTestCase {
    func testProfileDataValidation() {
        // Test valid profile
        let validProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: "https://example.com/avatar.jpg",
            vibeTags: ["fun", "social"],
            bio: "Test bio"
        )
        XCTAssertTrue(validProfile.isValid)
        
        // Test invalid name
        var invalidProfile = validProfile
        invalidProfile.name = ""
        XCTAssertFalse(invalidProfile.isValid)
        XCTAssertTrue(invalidProfile.validationErrors.contains("Name is required"))
        
        // Test invalid handle
        invalidProfile = validProfile
        invalidProfile.handle = "test@user"
        XCTAssertFalse(invalidProfile.isValid)
        XCTAssertTrue(invalidProfile.validationErrors.contains("Handle can only contain letters, numbers, and underscores"))
        
        // Test vibe tags limit
        invalidProfile = validProfile
        invalidProfile.vibeTags = ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6"]
        XCTAssertFalse(invalidProfile.isValid)
        XCTAssertTrue(invalidProfile.validationErrors.contains("Maximum 5 vibe tags allowed"))
    }
    
    func testProfileDataEquatable() {
        let profile1 = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: "https://example.com/avatar.jpg",
            vibeTags: ["fun", "social"],
            bio: "Test bio"
        )
        
        let profile2 = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: "https://example.com/avatar.jpg",
            vibeTags: ["fun", "social"],
            bio: "Test bio"
        )
        
        XCTAssertEqual(profile1, profile2)
        
        var profile3 = profile1
        profile3.handle = "different"
        XCTAssertNotEqual(profile1, profile3)
    }
    
    func testProfileDataCodable() {
        let originalProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: "https://example.com/avatar.jpg",
            vibeTags: ["fun", "social"],
            bio: "Test bio"
        )
        
        // Encode
        let encoder = JSONEncoder()
        XCTAssertNoThrow(try encoder.encode(originalProfile))
        
        guard let encodedData = try? encoder.encode(originalProfile) else {
            XCTFail("Failed to encode ProfileData")
            return
        }
        
        // Decode
        let decoder = JSONDecoder()
        XCTAssertNoThrow(try decoder.decode(ProfileData.self, from: encodedData))
        
        guard let decodedProfile = try? decoder.decode(ProfileData.self, from: encodedData) else {
            XCTFail("Failed to decode ProfileData")
            return
        }
        
        XCTAssertEqual(originalProfile, decodedProfile)
    }
} 