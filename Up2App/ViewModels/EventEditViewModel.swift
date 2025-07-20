import SwiftUI
import PhotosUI

@MainActor
class EventEditViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var eventTitle: String = ""
    @Published var eventType: String = ""
    @Published var eventDate: Date = Date()
    @Published var eventTime: Date = Date()
    @Published var venueName: String = ""
    @Published var venueAddress: String = ""
    @Published var coordinates: (Double, Double) = (0.0, 0.0)
    @Published var price: String = ""
    @Published var currency: String = "USD"
    @Published var eventDescription: String = ""
    @Published var selectedVibeTags: Set<VibeTag> = []
    @Published var coverImage: UIImage?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private var originalEvent: HostEvent?
    private let hostService = EventHostService.shared
    
    // MARK: - Initialization
    init() {
        // Initialize with default values
    }
    
    func initializeWithEvent(_ event: HostEvent) {
        self.originalEvent = event
        
        // Initialize with existing event data
        self.eventTitle = event.title
        self.eventType = "" // Not available in HostEvent model
        self.eventDate = event.date
        self.eventTime = event.date
        self.venueName = event.venueName
        self.venueAddress = "" // Not available in HostEvent model
        self.coordinates = (0.0, 0.0) // Not available in HostEvent model
        self.price = event.price == 0 ? "" : String(format: "%.0f", event.price)
        self.currency = "USD"
        self.eventDescription = "" // Not available in HostEvent model
        self.selectedVibeTags = [] // Not available in HostEvent model
        
        // Load cover image if available
        if let imageURL = event.imageURL {
            loadCoverImage(from: imageURL)
        }
    }
    
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
    func updateEvent() async {
        guard let originalEvent = originalEvent else {
            errorMessage = "No event to update"
            return
        }
        
        guard isFormValid else {
            errorMessage = "Please fill in all required fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            // Create updated HostEvent from form data
            let updatedEvent = HostEvent(
                id: originalEvent.id,
                title: eventTitle,
                venueName: venueName,
                date: Calendar.current.date(bySettingHour: Calendar.current.component(.hour, from: eventTime), minute: Calendar.current.component(.minute, from: eventTime), second: 0, of: eventDate) ?? eventDate,
                rsvpCount: originalEvent.rsvpCount, // Preserve existing RSVP count
                price: Double(price) ?? 0.0,
                status: originalEvent.status, // Preserve existing status
                imageURL: originalEvent.imageURL // Preserve existing image URL for now
            )
            
            // Use the host service to update the event
            let updatedEventResult = try await hostService.updateEvent(updatedEvent)
            print("🎉 Event updated successfully: \(updatedEventResult.title)")
            
        } catch {
            errorMessage = "Failed to update event: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    func deleteEvent() async {
        guard let originalEvent = originalEvent else {
            errorMessage = "No event to delete"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            try await hostService.deleteEvent(originalEvent.id)
            print("🗑️ Event deleted successfully: \(originalEvent.title)")
        } catch {
            errorMessage = "Failed to delete event: \(error.localizedDescription)"
        }
        
        isLoading = false
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
        } else if selectedVibeTags.count < 5 {
            selectedVibeTags.insert(tag)
        }
    }
    
    private func loadCoverImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    coverImage = image
                }
            } catch {
                print("Failed to load cover image: \(error)")
            }
        }
    }
} 