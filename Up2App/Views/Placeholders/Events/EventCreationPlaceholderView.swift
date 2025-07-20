import SwiftUI
import PhotosUI

struct EventCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = EventCreationViewModel()
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingLocationPicker = false
    @State private var showingDatePicker = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Event Image Section
                    eventImageSection
                    
                    // Basic Details Section
                    basicDetailsSection
                    
                    // Date & Time Section
                    dateTimeSection
                    
                    // Location Section
                    locationSection
                    
                    // Pricing Section
                    pricingSection
                    
                    // Description Section
                    descriptionSection
                    
                    // Vibe Tags Section
                    vibeTagsSection
                    
                    // Create Button
                    createButton
                }
                .padding()
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationTitle("Create Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
            }
            .onChange(of: selectedPhotos) { _, items in
                Task {
                    if let item = items.first {
                        await viewModel.loadImage(from: item)
                    }
                }
            }
        }
    }
    
    // MARK: - Event Image Section
    private var eventImageSection: some View {
        VStack(spacing: 12) {
            Text("Event Cover")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                if let coverImage = viewModel.coverImage {
                    Image(uiImage: coverImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Up2Colors.border, lineWidth: 1)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Up2Colors.surface)
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title)
                                    .foregroundColor(Up2Colors.textSecondary)
                                Text("Add Cover Photo")
                                    .font(Up2Typography.bodyMedium)
                                    .foregroundColor(Up2Colors.textSecondary)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Up2Colors.border, lineWidth: 1)
                        )
                }
            }
        }
    }
    
    // MARK: - Basic Details Section
    private var basicDetailsSection: some View {
        VStack(spacing: 16) {
            Text("Event Details")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Up2TextField(
                text: $viewModel.eventTitle,
                placeholder: "Event Title"
            )
            
            Up2TextField(
                text: $viewModel.eventType,
                placeholder: "Event Type (e.g., Party, Concert, Meetup)"
            )
        }
    }
    
    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(spacing: 16) {
            Text("Date & Time")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Date")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Image(systemName: "calendar")
                                .foregroundColor(Up2Colors.textSecondary)
                            Text(viewModel.eventDate, style: .date)
                                .foregroundColor(Up2Colors.textPrimary)
                            Spacer()
                        }
                        .padding()
                        .background(Up2Colors.surface)
                        .cornerRadius(8)
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Time")
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.textSecondary)
                    
                    Button(action: { showingDatePicker = true }) {
                        HStack {
                            Image(systemName: "clock")
                                .foregroundColor(Up2Colors.textSecondary)
                            Text(viewModel.eventTime, style: .time)
                                .foregroundColor(Up2Colors.textPrimary)
                            Spacer()
                        }
                        .padding()
                        .background(Up2Colors.surface)
                        .cornerRadius(8)
                    }
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(
                date: $viewModel.eventDate,
                time: $viewModel.eventTime
            )
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(spacing: 16) {
            Text("Location")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Button(action: { showingLocationPicker = true }) {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(Up2Colors.textSecondary)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.venueName.isEmpty ? "Select Venue" : viewModel.venueName)
                            .foregroundColor(viewModel.venueName.isEmpty ? Up2Colors.textSecondary : Up2Colors.textPrimary)
                        if !viewModel.venueAddress.isEmpty {
                            Text(viewModel.venueAddress)
                                .font(Up2Typography.caption)
                                .foregroundColor(Up2Colors.textSecondary)
                        }
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(Up2Colors.textSecondary)
                }
                .padding()
                .background(Up2Colors.surface)
                .cornerRadius(8)
            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(
                venueName: $viewModel.venueName,
                venueAddress: $viewModel.venueAddress,
                coordinates: $viewModel.coordinates
            )
        }
    }
    
    // MARK: - Pricing Section
    private var pricingSection: some View {
        VStack(spacing: 16) {
            Text("Pricing")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack {
                Up2TextField(
                    text: $viewModel.price,
                    placeholder: "Price"
                )
                
                Picker("Currency", selection: $viewModel.currency) {
                    Text("$").tag("USD")
                    Text("€").tag("EUR")
                    Text("£").tag("GBP")
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 120)
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(spacing: 16) {
            Text("Description")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            TextEditor(text: $viewModel.eventDescription)
                .frame(minHeight: 100)
                .padding(8)
                .background(Up2Colors.surface)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Up2Colors.border, lineWidth: 1)
                )
        }
    }
    
    // MARK: - Vibe Tags Section
    private var vibeTagsSection: some View {
        VStack(spacing: 16) {
            Text("Vibe Tags")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                ForEach(VibeTag.allCases, id: \.self) { tag in
                    Button(action: {
                        if viewModel.selectedVibeTags.contains(tag) {
                            viewModel.selectedVibeTags.remove(tag)
                        } else {
                            viewModel.selectedVibeTags.insert(tag)
                        }
                    }) {
                        Text(tag.rawValue)
                            .font(Up2Typography.caption)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                viewModel.selectedVibeTags.contains(tag) ?
                                Color(red: 0.0, green: 0.48, blue: 1.0) :
                                Up2Colors.surface
                            )
                            .foregroundColor(
                                viewModel.selectedVibeTags.contains(tag) ?
                                .white :
                                Up2Colors.textPrimary
                            )
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Up2Colors.border, lineWidth: 1)
                            )
                    }
                }
            }
        }
    }
    
    // MARK: - Create Button
    private var createButton: some View {
        Button(action: {
            Task {
                await viewModel.createEvent()
                dismiss()
            }
        }) {
            Text("Create Event")
                .font(Up2Typography.buttonLarge)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.0, green: 0.48, blue: 1.0), Color(red: 0.0, green: 0.32, blue: 0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(12)
        }
        .disabled(!viewModel.isFormValid)
        .opacity(viewModel.isFormValid ? 1.0 : 0.6)
        .padding(.top, 20)
    }
}

// MARK: - Date Picker View
struct DatePickerView: View {
    @Binding var date: Date
    @Binding var time: Date
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                DatePicker("Date", selection: $date, displayedComponents: .date)
                    .datePickerStyle(WheelDatePickerStyle())
                
                DatePicker("Time", selection: $time, displayedComponents: .hourAndMinute)
                    .datePickerStyle(WheelDatePickerStyle())
                
                Spacer()
            }
            .padding()
            .navigationTitle("Select Date & Time")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Location Picker View
struct LocationPickerView: View {
    @Binding var venueName: String
    @Binding var venueAddress: String
    @Binding var coordinates: (Double, Double)
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                Up2TextField(
                    text: $searchText,
                    placeholder: "Search for venue..."
                )
                .padding()
                
                // Sample venues (in real app, this would be API search)
                List {
                    ForEach(sampleVenues, id: \.name) { venue in
                        Button(action: {
                            venueName = venue.name
                            venueAddress = venue.address
                            coordinates = venue.coordinates
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(venue.name)
                                    .font(Up2Typography.bodyMedium)
                                    .foregroundColor(Up2Colors.textPrimary)
                                Text(venue.address)
                                    .font(Up2Typography.caption)
                                    .foregroundColor(Up2Colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Select Venue")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private let sampleVenues = [
        Venue(name: "Club XYZ", address: "123 Main St, Downtown", coordinates: (40.7128, -74.0060)),
        Venue(name: "The Grand Hall", address: "456 Oak Ave, Midtown", coordinates: (40.7589, -73.9851)),
        Venue(name: "Skyline Lounge", address: "789 Park Blvd, Uptown", coordinates: (40.7505, -73.9934)),
        Venue(name: "Underground", address: "321 Elm St, Downtown", coordinates: (40.7142, -74.0064))
    ]
}

struct Venue {
    let name: String
    let address: String
    let coordinates: (Double, Double)
}

#Preview {
    EventCreationView()
} 