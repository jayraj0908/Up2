import XCTest
@testable import Up2App

final class AvatarUploadTests: XCTestCase {
    var avatarUploader: AvatarUploader!
    var mockStorageClient: MockStorageClient!
    
    override func setUp() {
        super.setUp()
        mockStorageClient = MockStorageClient()
        avatarUploader = AvatarUploader(storageClient: mockStorageClient)
    }
    
    override func tearDown() {
        avatarUploader = nil
        mockStorageClient = nil
        super.tearDown()
    }
    
    func testImageCompression() {
        // Create a test image
        let size = CGSize(width: 1024, height: 1024)
        UIGraphicsBeginImageContext(size)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.red.cgColor)
        context?.fill(CGRect(origin: .zero, size: size))
        let testImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = testImage else {
            XCTFail("Failed to create test image")
            return
        }
        
        // Test compression
        let compressedData = avatarUploader.compressImage(image)
        XCTAssertNotNil(compressedData)
        XCTAssertLessThan(compressedData?.count ?? 0, 1024 * 1024) // Should be less than 1MB
    }
    
    func testUploadAvatar() async throws {
        // Prepare test data
        let testImageData = "test-image-data".data(using: .utf8)!
        let expectedUrl = "https://storage.example.com/avatars/test-user-id.jpg"
        
        // Configure mock
        mockStorageClient.mockUploadResponse = expectedUrl
        
        // Test successful upload
        let result = try await avatarUploader.uploadAvatar(
            imageData: testImageData,
            userId: "test-user-id"
        )
        XCTAssertEqual(result, expectedUrl)
        XCTAssertEqual(mockStorageClient.lastBucket, "avatars")
        XCTAssertEqual(mockStorageClient.lastPath, "test-user-id.jpg")
        
        // Test upload failure
        mockStorageClient.shouldFail = true
        do {
            _ = try await avatarUploader.uploadAvatar(
                imageData: testImageData,
                userId: "test-user-id"
            )
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testDeleteAvatar() async throws {
        // Test successful deletion
        mockStorageClient.mockDeleteResponse = true
        
        XCTAssertNoThrow(try await avatarUploader.deleteAvatar(userId: "test-user-id"))
        XCTAssertEqual(mockStorageClient.lastBucket, "avatars")
        XCTAssertEqual(mockStorageClient.lastPath, "test-user-id.jpg")
        
        // Test deletion failure
        mockStorageClient.shouldFail = true
        do {
            try await avatarUploader.deleteAvatar(userId: "test-user-id")
            XCTFail("Expected error but got success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    func testValidateImage() {
        // Create valid image data
        let validSize = CGSize(width: 512, height: 512)
        UIGraphicsBeginImageContext(validSize)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.blue.cgColor)
        context?.fill(CGRect(origin: .zero, size: validSize))
        let validImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        guard let image = validImage else {
            XCTFail("Failed to create test image")
            return
        }
        
        // Test valid image
        XCTAssertTrue(avatarUploader.validateImage(image))
        
        // Test invalid size
        let invalidSize = CGSize(width: 10, height: 10)
        UIGraphicsBeginImageContext(invalidSize)
        let invalidImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        XCTAssertFalse(avatarUploader.validateImage(invalidImage!))
    }
}

// Mock Storage Client for testing
private class MockStorageClient {
    var mockUploadResponse: String?
    var mockDeleteResponse: Bool?
    var shouldFail = false
    var lastBucket: String?
    var lastPath: String?
    
    func upload(bucket: String, path: String, data: Data) async throws -> String {
        lastBucket = bucket
        lastPath = path
        
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
        
        return mockUploadResponse ?? ""
    }
    
    func delete(bucket: String, path: String) async throws {
        lastBucket = bucket
        lastPath = path
        
        if shouldFail {
            throw NSError(domain: "MockError", code: -1)
        }
    }
} 