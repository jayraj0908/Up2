import XCTest
@testable import Up2App

final class ProfileServiceTests: XCTestCase {
    var profileService: ProfileService!
    var mockSupabaseClient: MockSupabaseClient!
    
    override func setUp() {
        super.setUp()
        mockSupabaseClient = MockSupabaseClient()
        profileService = ProfileService(supabaseClient: mockSupabaseClient)
    }
    
    override func tearDown() {
        profileService = nil
        mockSupabaseClient = nil
        super.tearDown()
    }
    
    func testCreateProfile() async throws {
        // Prepare test data
        let testProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: nil,
            vibeTags: ["fun"],
            bio: "Test bio"
        )
        
        // Configure mock
        mockSupabaseClient.mockResponse = testProfile
        
        // Test successful creation
        let result = try await profileService.createProfile(testProfile)
        XCTAssertEqual(result, testProfile)
        XCTAssertEqual(mockSupabaseClient.lastPath, "profiles")
        XCTAssertEqual(mockSupabaseClient.lastMethod, "INSERT")
        
        // Test failure
        mockSupabaseClient.shouldFail = true
        do {
            _ = try await profileService.createProfile(testProfile)
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testUpdateProfile() async throws {
        let testProfile = ProfileData(
            id: "test-id",
            name: "Updated User",
            handle: "testuser",
            avatarUrl: nil,
            vibeTags: ["fun", "social"],
            bio: "Updated bio"
        )
        
        mockSupabaseClient.mockResponse = testProfile
        
        // Test successful update
        let result = try await profileService.updateProfile(testProfile)
        XCTAssertEqual(result, testProfile)
        XCTAssertEqual(mockSupabaseClient.lastPath, "profiles")
        XCTAssertEqual(mockSupabaseClient.lastMethod, "UPDATE")
        
        // Test failure
        mockSupabaseClient.shouldFail = true
        do {
            _ = try await profileService.updateProfile(testProfile)
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testFetchProfile() async throws {
        let testProfile = ProfileData(
            id: "test-id",
            name: "Test User",
            handle: "testuser",
            avatarUrl: nil,
            vibeTags: ["fun"],
            bio: "Test bio"
        )
        
        mockSupabaseClient.mockResponse = testProfile
        
        // Test successful fetch
        let result = try await profileService.fetchProfile(id: "test-id")
        XCTAssertEqual(result, testProfile)
        XCTAssertEqual(mockSupabaseClient.lastPath, "profiles")
        XCTAssertEqual(mockSupabaseClient.lastMethod, "SELECT")
        
        // Test not found
        mockSupabaseClient.mockResponse = nil
        do {
            _ = try await profileService.fetchProfile(id: "non-existent")
            XCTFail("Expected error but got success")
        } catch ProfileError.notFound {
            // Expected error
        } catch {
            XCTFail("Unexpected error type")
        }
    }
    
    func testDeleteProfile() async throws {
        // Test successful deletion
        mockSupabaseClient.mockResponse = true
        
        XCTAssertNoThrow(try await profileService.deleteProfile(id: "test-id"))
        XCTAssertEqual(mockSupabaseClient.lastPath, "profiles")
        XCTAssertEqual(mockSupabaseClient.lastMethod, "DELETE")
        
        // Test failure
        mockSupabaseClient.shouldFail = true
        do {
            try await profileService.deleteProfile(id: "test-id")
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testHandleAvailability() async throws {
        // Test available handle
        mockSupabaseClient.mockResponse = []
        let isAvailable = try await profileService.isHandleAvailable("newhandle")
        XCTAssertTrue(isAvailable)
        
        // Test taken handle
        mockSupabaseClient.mockResponse = [["handle": "takenhandle"]]
        let isTaken = try await profileService.isHandleAvailable("takenhandle")
        XCTAssertFalse(isTaken)
    }
}

// Mock Supabase Client for testing
private class MockSupabaseClient {
    var mockResponse: Any?
    var shouldFail = false
    var lastPath: String?
    var lastMethod: String?
    
    func query<T>(_ path: String, method: String) async throws -> T {
        lastPath = path
        lastMethod = method
        
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        
        guard let response = mockResponse as? T else {
            throw NSError(domain: "MockError", code: -2)
        }
        
        return response
    }
} 