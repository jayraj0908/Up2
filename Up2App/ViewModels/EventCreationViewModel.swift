import SwiftUI
import PhotosUI

@MainActor
class EventCreationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var eventTitle = ""
    @Published var eventType = ""
    @Published var eventDate = Date()
    @Published var eventTime = Date()
    @Published var venueName = ""
    @Published var venueAddress = ""
    @Published var coordinates: (Double, Double) = (0.0, 0.0)
    @Published var price = ""
    @Published var currency = "USD"
    @Published var eventDescription = ""
    @Published var selectedVibeTags: Set<VibeTag> = []
    @Published var coverImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isEventCreated = false
    
    // MARK: - Services
    private let eventService = EventService.shared
    private let authService = SupabaseAuthService.shared
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !eventTitle.isEmpty &&
        !venueName.isEmpty &&
        !eventDescription.isEmpty &&
        !selectedVibeTags.isEmpty
    }
    
    var formattedPrice: String {
        if price.isEmpty { return "Free" }
        return "\(currency) \(price)"
    }
    
    var formattedDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: eventDate)
    }
    
    // MARK: - Methods
    func createEvent() async {
        guard isFormValid else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        guard let currentUser = authService.currentUser else {
            errorMessage = "You must be logged in to create an event."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Combine date and time
            let combinedDateTime = Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: eventTime), minute: Calendar.current.component(.minute, from: eventTime), second: 0, of: eventDate) ?? eventDate
            
            // Set end time to 3 hours after start time (default)
            let endTime = Calendar.current.date(byAdding: .hour, value: 3, to: combinedDateTime) ?? combinedDateTime
            
            // Create event request
            let eventRequest = EventCreationRequest(
                hostId: UUID(uuidString: authService.currentUser?.id ?? "") ?? UUID(),
                title: eventTitle,
                description: eventDescription,
                imageUrl: nil, // TODO: Upload image and get URL
                tags: selectedVibeTags.map { $0.rawValue },
                location: venueName,
                startTime: combinedDateTime,
                endTime: endTime,
                isPublic: true,
                capacity: nil,
                price: price.isEmpty ? nil : Double(price)
            )
            
            // Create event using EventService
            let createdEvent = try await eventService.createEvent(eventRequest)
            print("🎉 Event created successfully: \(createdEvent.title)")
            
            // Mark as created and reset form
            isEventCreated = true
            resetForm()
            
        } catch {
            errorMessage = "Failed to create event: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func resetForm() {
        eventTitle = ""
        eventType = ""
        eventDate = Date()
        eventTime = Date()
        venueName = ""
        venueAddress = ""
        coordinates = (0.0, 0.0)
        price = ""
        currency = "USD"
        eventDescription = ""
        selectedVibeTags.removeAll()
        coverImage = nil
        errorMessage = nil
        isEventCreated = false
    }
    
    func loadImage(from item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                coverImage = image
            }
        } catch {
            errorMessage = "Failed to load image: \(error.localizedDescription)"
        }
    }
    
    func toggleVibeTag(_ tag: VibeTag) {
        if selectedVibeTags.contains(tag) {
            selectedVibeTags.remove(tag)
        } else {
            selectedVibeTags.insert(tag)
        }
    }
    
    func setLocation(name: String, address: String, lat: Double, lng: Double) {
        venueName = name
        venueAddress = address
        coordinates = (lat, lng)
    }
}

// MARK: - Event Creation Data Model
struct EventCreationData {
    let title: String
    let type: String
    let date: Date
    let time: Date
    let venueName: String
    let venueAddress: String
    let coordinates: (Double, Double)
    let price: Double?
    let currency: String
    let description: String
    let vibeTags: [VibeTag]
    let coverImage: UIImage?
    
    var isFree: Bool {
        price == nil || price == 0
    }
    
    var formattedPrice: String {
        guard let price = price, price > 0 else { return "Free" }
        return "\(currency) \(String(format: "%.2f", price))"
    }
} 