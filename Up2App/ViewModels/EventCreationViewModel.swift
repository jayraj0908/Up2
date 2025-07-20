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
    
    // MARK: - Services
    private let hostService = EventHostService.shared
    
    // MARK: - Computed Properties
    var isFormValid: Bool {
        !eventTitle.isEmpty &&
        !eventType.isEmpty &&
        !venueName.isEmpty &&
        !eventDescription.isEmpty &&
        !selectedVibeTags.isEmpty &&
        coverImage != nil
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
            errorMessage = "Please fill in all required fields and add a cover photo."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create HostEvent from form data
            let event = HostEvent(
                id: UUID(),
                title: eventTitle,
                venueName: venueName,
                date: Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: eventTime), minute: Calendar.current.component(.minute, from: eventTime), second: 0, of: eventDate) ?? eventDate,
                rsvpCount: 0,
                price: Double(price) ?? 0.0,
                status: .upcoming,
                imageURL: nil // In real app, upload image and get URL
            )
            
            // Use the host service to create the event
            let createdEvent = try await hostService.createEvent(event)
            print("🎉 Event created successfully: \(createdEvent.title)")
            
            // Reset form
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