import XCTest
@testable import Up2App

final class VibeTagsTests: XCTestCase {
    var vibeTagsManager: VibeTagsManager!
    
    override func setUp() {
        super.setUp()
        vibeTagsManager = VibeTagsManager()
    }
    
    override func tearDown() {
        vibeTagsManager = nil
        super.tearDown()
    }
    
    func testVibeTagsValidation() {
        // Test valid tags
        let validTags = ["fun", "social", "active"]
        XCTAssertTrue(vibeTagsManager.validateTags(validTags))
        
        // Test empty tags
        let emptyTags: [String] = []
        XCTAssertTrue(vibeTagsManager.validateTags(emptyTags))
        
        // Test too many tags
        let tooManyTags = ["tag1", "tag2", "tag3", "tag4", "tag5", "tag6"]
        XCTAssertFalse(vibeTagsManager.validateTags(tooManyTags))
        
        // Test invalid tag
        let invalidTags = ["fun", "invalid_tag"]
        XCTAssertFalse(vibeTagsManager.validateTags(invalidTags))
    }
    
    func testVibeTagsSelection() {
        // Test adding valid tags
        XCTAssertTrue(vibeTagsManager.addTag("fun"))
        XCTAssertTrue(vibeTagsManager.addTag("social"))
        XCTAssertEqual(vibeTagsManager.selectedTags.count, 2)
        
        // Test adding duplicate tag
        XCTAssertFalse(vibeTagsManager.addTag("fun"))
        XCTAssertEqual(vibeTagsManager.selectedTags.count, 2)
        
        // Test removing tag
        XCTAssertTrue(vibeTagsManager.removeTag("fun"))
        XCTAssertEqual(vibeTagsManager.selectedTags.count, 1)
        
        // Test removing non-existent tag
        XCTAssertFalse(vibeTagsManager.removeTag("nonexistent"))
        XCTAssertEqual(vibeTagsManager.selectedTags.count, 1)
    }
    
    func testMaxTagsLimit() {
        // Add maximum allowed tags
        XCTAssertTrue(vibeTagsManager.addTag("tag1"))
        XCTAssertTrue(vibeTagsManager.addTag("tag2"))
        XCTAssertTrue(vibeTagsManager.addTag("tag3"))
        XCTAssertTrue(vibeTagsManager.addTag("tag4"))
        XCTAssertTrue(vibeTagsManager.addTag("tag5"))
        
        // Try to add one more tag
        XCTAssertFalse(vibeTagsManager.addTag("tag6"))
        XCTAssertEqual(vibeTagsManager.selectedTags.count, 5)
    }
    
    func testTagCategories() {
        // Test mood tags
        let moodTags = vibeTagsManager.getMoodTags()
        XCTAssertTrue(moodTags.contains("happy"))
        XCTAssertTrue(moodTags.contains("chill"))
        
        // Test interest tags
        let interestTags = vibeTagsManager.getInterestTags()
        XCTAssertTrue(interestTags.contains("music"))
        XCTAssertTrue(interestTags.contains("sports"))
        
        // Test activity tags
        let activityTags = vibeTagsManager.getActivityTags()
        XCTAssertTrue(activityTags.contains("outdoor"))
        XCTAssertTrue(activityTags.contains("social"))
    }
    
    func testTagSearch() {
        // Test exact match
        let exactResults = vibeTagsManager.searchTags("fun")
        XCTAssertEqual(exactResults.count, 1)
        XCTAssertEqual(exactResults.first, "fun")
        
        // Test partial match
        let partialResults = vibeTagsManager.searchTags("mu")
        XCTAssertTrue(partialResults.contains("music"))
        
        // Test case insensitive
        let caseResults = vibeTagsManager.searchTags("SOCIAL")
        XCTAssertTrue(caseResults.contains("social"))
        
        // Test no match
        let noResults = vibeTagsManager.searchTags("xyz")
        XCTAssertTrue(noResults.isEmpty)
    }
    
    func testTagSuggestions() {
        // Test suggestions based on selected tags
        vibeTagsManager.addTag("music")
        let suggestions = vibeTagsManager.getSuggestedTags()
        
        // Should suggest related tags
        XCTAssertTrue(suggestions.contains("social"))
        XCTAssertTrue(suggestions.contains("fun"))
        
        // Should not suggest already selected tags
        XCTAssertFalse(suggestions.contains("music"))
    }
} 