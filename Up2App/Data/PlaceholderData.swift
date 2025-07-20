import Foundation
import CoreLocation

// MARK: - Mock Event Data for Epic C
struct MockEventData {
    
    // MARK: - Sample Events
    static let sampleEvents: [Event] = [
        Event(
            id: UUID(),
            hostId: UUID(),
            title: "Glow Night Party",
            description: "A night of neon lights, electronic beats, and unforgettable vibes. Join us for the ultimate glow-in-the-dark experience with top DJs and immersive lighting.",
            vibe: "Electronic",
            date: Date().addingTimeInterval(86400), // Tomorrow
            endDate: Date().addingTimeInterval(86400 + 14400), // 4 hours later
            location: EventLocation(
                name: "Neon Club",
                address: "123 Downtown Ave",
                city: "Los Angeles",
                state: "CA",
                country: "USA",
                zipCode: "90012",
                latitude: 34.0522,
                longitude: -118.2437
            ),
            capacity: 200,
            price: 25.0,
            isPrivate: false,
            mediaRefs: ["glow_party_1.jpg", "glow_party_2.jpg"],
            createdAt: Date(),
            updatedAt: Date()
        ),
        Event(
            id: UUID(),
            hostId: UUID(),
            title: "Rooftop Beats & Chill",
            description: "Chill beats and city views from the best rooftop in town. Craft cocktails, good music, and even better company.",
            vibe: "Chill",
            date: Date().addingTimeInterval(172800), // Day after tomorrow
            endDate: Date().addingTimeInterval(172800 + 10800), // 3 hours later
            location: EventLocation(
                name: "Skyline Bar",
                address: "456 Hollywood Blvd",
                city: "Hollywood",
                state: "CA",
                country: "USA",
                zipCode: "90028",
                latitude: 34.0736,
                longitude: -118.2400
            ),
            capacity: 150,
            price: 0.0, // Free
            isPrivate: false,
            mediaRefs: ["rooftop_1.jpg"],
            createdAt: Date(),
            updatedAt: Date()
        ),
        Event(
            id: UUID(),
            hostId: UUID(),
            title: "Silent Disco Warehouse",
            description: "Dance to your own beat with wireless headphones. Three different channels of music, so everyone finds their vibe.",
            vibe: "Dance",
            date: Date().addingTimeInterval(259200), // 3 days from now
            endDate: Date().addingTimeInterval(259200 + 18000), // 5 hours later
            location: EventLocation(
                name: "Warehouse 21",
                address: "789 Arts District St",
                city: "Los Angeles",
                state: "CA",
                country: "USA",
                zipCode: "90013",
                latitude: 34.0625,
                longitude: -118.2381
            ),
            capacity: 300,
            price: 35.0,
            isPrivate: false,
            mediaRefs: ["silent_disco_1.jpg", "silent_disco_2.jpg"],
            createdAt: Date(),
            updatedAt: Date()
        ),
        Event(
            id: UUID(),
            hostId: UUID(),
            title: "Jazz Night at The Blue Note",
            description: "Smooth jazz and soulful vibes in an intimate setting. Live performances from local jazz artists.",
            vibe: "Jazz",
            date: Date().addingTimeInterval(432000), // 5 days from now
            endDate: Date().addingTimeInterval(432000 + 14400), // 4 hours later
            location: EventLocation(
                name: "The Blue Note",
                address: "321 Beverly Hills Dr",
                city: "Beverly Hills",
                state: "CA",
                country: "USA",
                zipCode: "90210",
                latitude: 34.1016,
                longitude: -118.3267
            ),
            capacity: 80,
            price: 45.0,
            isPrivate: false,
            mediaRefs: ["jazz_night_1.jpg"],
            createdAt: Date(),
            updatedAt: Date()
        ),
        Event(
            id: UUID(),
            hostId: UUID(),
            title: "Beach Bonfire & Acoustic",
            description: "Acoustic music by the ocean. Bring your own blanket and enjoy the sunset with live acoustic performances.",
            vibe: "Acoustic",
            date: Date().addingTimeInterval(518400), // 6 days from now
            endDate: Date().addingTimeInterval(518400 + 10800), // 3 hours later
            location: EventLocation(
                name: "Venice Beach",
                address: "Ocean Front Walk",
                city: "Venice",
                state: "CA",
                country: "USA",
                zipCode: "90291",
                latitude: 34.0195,
                longitude: -118.4912
            ),
            capacity: 100,
            price: 0.0, // Free
            isPrivate: false,
            mediaRefs: ["beach_bonfire_1.jpg"],
            createdAt: Date(),
            updatedAt: Date()
        ),
        Event(
            id: UUID(),
            hostId: UUID(),
            title: "Hip Hop Block Party",
            description: "The biggest hip hop block party of the summer. Live performances, food trucks, and street art.",
            vibe: "Hip Hop",
            date: Date().addingTimeInterval(604800), // 7 days from now
            endDate: Date().addingTimeInterval(604800 + 21600), // 6 hours later
            location: EventLocation(
                name: "Melrose Block",
                address: "567 Melrose Avenue",
                city: "West Hollywood",
                state: "CA",
                country: "USA",
                zipCode: "90069",
                latitude: 34.0928,
                longitude: -118.3287
            ),
            capacity: 500,
            price: 20.0,
            isPrivate: false,
            mediaRefs: ["block_party_1.jpg", "block_party_2.jpg"],
            createdAt: Date(),
            updatedAt: Date()
        )
    ]
    
    // MARK: - Sample Hosts
    static let sampleHosts: [EventHost] = [
        EventHost(
            id: UUID(),
            name: "Alex Rivera",
            handle: "@alexrivera",
            avatarUrl: "https://example.com/avatars/alex.jpg",
            vibeTags: ["Electronic", "Dance", "Chill"],
            isVerified: true
        ),
        EventHost(
            id: UUID(),
            name: "Morgan Lee",
            handle: "@morganlee",
            avatarUrl: "https://example.com/avatars/morgan.jpg",
            vibeTags: ["Chill", "Acoustic", "Jazz"],
            isVerified: false
        ),
        EventHost(
            id: UUID(),
            name: "Taylor Kim",
            handle: "@taylorkim",
            avatarUrl: "https://example.com/avatars/taylor.jpg",
            vibeTags: ["Dance", "Hip Hop", "Electronic"],
            isVerified: true
        ),
        EventHost(
            id: UUID(),
            name: "Jordan Smith",
            handle: "@jordansmith",
            avatarUrl: "https://example.com/avatars/jordan.jpg",
            vibeTags: ["Jazz", "Acoustic", "Chill"],
            isVerified: false
        ),
        EventHost(
            id: UUID(),
            name: "Casey Johnson",
            handle: "@caseyjohnson",
            avatarUrl: "https://example.com/avatars/casey.jpg",
            vibeTags: ["Hip Hop", "Dance", "Electronic"],
            isVerified: true
        ),
        EventHost(
            id: UUID(),
            name: "Riley Chen",
            handle: "@rileychen",
            avatarUrl: "https://example.com/avatars/riley.jpg",
            vibeTags: ["Acoustic", "Chill", "Jazz"],
            isVerified: false
        )
    ]
    
    // MARK: - Sample Attendees
    static let sampleAttendees: [EventAttendee] = [
        EventAttendee(
            id: UUID(),
            userId: UUID(),
            name: "Sarah Wilson",
            handle: "@sarahwilson",
            avatarUrl: "https://example.com/avatars/sarah.jpg",
            status: .going,
            joinedAt: Date()
        ),
        EventAttendee(
            id: UUID(),
            userId: UUID(),
            name: "Mike Davis",
            handle: "@mikedavis",
            avatarUrl: "https://example.com/avatars/mike.jpg",
            status: .maybe,
            joinedAt: Date()
        ),
        EventAttendee(
            id: UUID(),
            userId: UUID(),
            name: "Emma Thompson",
            handle: "@emmathompson",
            avatarUrl: "https://example.com/avatars/emma.jpg",
            status: .going,
            joinedAt: Date()
        )
    ]
    
    // MARK: - Generate Mock Feed Items
    static func generateMockFeedItems() -> [EventFeedItem] {
        var feedItems: [EventFeedItem] = []
        
        for (index, event) in sampleEvents.enumerated() {
            let host = sampleHosts[index % sampleHosts.count]
            let attendeeCount = Int.random(in: 15...150)
            let friendsAttending = Array(sampleAttendees.prefix(Int.random(in: 0...3)))
            let isBookmarked = Bool.random()
            let distance = Double.random(in: 500...15000) // 0.5km to 15km
            
            let feedItem = EventFeedItem(
                id: event.id,
                event: event,
                host: host,
                score: Double.random(in: 0.3...0.95), // AI score
                attendeeCount: attendeeCount,
                friendsAttending: friendsAttending,
                isBookmarked: isBookmarked,
                distanceFromUser: distance
            )
            
            feedItems.append(feedItem)
        }
        
        // Sort by AI score for relevance
        return feedItems.sorted { $0.score > $1.score }
    }
    
    // MARK: - Generate Mock Trending Events
    static func generateMockTrendingEvents() -> [EventFeedItem] {
        let allItems = generateMockFeedItems()
        // Return top 5 by attendee count (trending)
        return Array(allItems.sorted { $0.attendeeCount > $1.attendeeCount }.prefix(5))
    }
    
    // MARK: - Generate Mock Private Events
    static func generateMockPrivateEvents() -> [EventFeedItem] {
        let privateEvents = sampleEvents.map { event in
            Event(
                id: event.id,
                hostId: event.hostId,
                title: event.title,
                description: event.description,
                vibe: event.vibe,
                date: event.date,
                endDate: event.endDate,
                location: event.location,
                capacity: event.capacity,
                price: event.price,
                isPrivate: true, // Make private
                mediaRefs: event.mediaRefs,
                createdAt: event.createdAt,
                updatedAt: event.updatedAt
            )
        }
        
        var privateFeedItems: [EventFeedItem] = []
        
        for (index, event) in privateEvents.enumerated() {
            let host = sampleHosts[index % sampleHosts.count]
            let attendeeCount = Int.random(in: 5...50) // Smaller for private events
            let friendsAttending = Array(sampleAttendees.prefix(Int.random(in: 1...5)))
            let isBookmarked = Bool.random()
            let distance = Double.random(in: 1000...20000)
            
            let feedItem = EventFeedItem(
                id: event.id,
                event: event,
                host: host,
                score: Double.random(in: 0.4...0.9),
                attendeeCount: attendeeCount,
                friendsAttending: friendsAttending,
                isBookmarked: isBookmarked,
                distanceFromUser: distance
            )
            
            privateFeedItems.append(feedItem)
        }
        
        return privateFeedItems.sorted { $0.score > $1.score }
    }
}

// MARK: - Legacy Placeholder Data (for backward compatibility)
struct SampleEvent: Identifiable {
    let id: UUID = UUID()
    let title: String
    let venue: String
    let time: String
    let description: String
}

struct SampleUser: Identifiable {
    let id: UUID = UUID()
    let name: String
    let vibe: String
    let bio: String
}

struct PlaceholderData {
    static let events: [SampleEvent] = [
        SampleEvent(title: "Glow Night Party", venue: "Neon Club", time: "Fri 10:00 PM", description: "A night of neon lights and dance music."),
        SampleEvent(title: "Rooftop Beats", venue: "Skyline Bar", time: "Sat 8:00 PM", description: "Chill beats and city views."),
        SampleEvent(title: "Silent Disco", venue: "Warehouse 21", time: "Thu 9:30 PM", description: "Dance to your own beat with wireless headphones.")
    ]
    static let users: [SampleUser] = [
        SampleUser(name: "Alex Rivera", vibe: "Chill", bio: "Loves rooftop parties and good vibes."),
        SampleUser(name: "Morgan Lee", vibe: "Adventurous", bio: "Always looking for the next big event."),
        SampleUser(name: "Taylor Kim", vibe: "Social", bio: "Here to meet new friends and dance all night!")
    ]
} 