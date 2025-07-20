import SwiftUI
import PhotosUI

struct EventEditView: View {
    let event: HostEvent
    @StateObject private var viewModel = EventEditViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var showingLocationPicker = false
    @State private var showingDatePicker = false
    @State private var showingDeleteConfirmation = false
    
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
                    
                    // Action Buttons
                    actionButtons
                }
                .padding()
            }
            .background(Up2Colors.background.ignoresSafeArea())
            .navigationTitle("Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(Up2Colors.textSecondary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Delete") {
                        showingDeleteConfirmation = true
                    }
                    .foregroundColor(.red)
                }
            }
            .onAppear {
                viewModel.initializeWithEvent(event)
            }
            .onChange(of: selectedPhotos) { _, items in
                Task {
                    if let item = items.first {
                        await viewModel.loadImage(from: item)
                    }
                }
            }
            .alert("Delete Event", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteEvent()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this event? This action cannot be undone.")
            }
        }
    }
    
    // MARK: - Event Image Section
    private var eventImageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Cover Image")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            if let coverImage = viewModel.coverImage {
                Image(uiImage: coverImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(12)
                    .overlay(
                        Button(action: {
                            viewModel.coverImage = nil
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .padding(8),
                        alignment: .topTrailing
                    )
            } else {
                PhotosPicker(selection: $selectedPhotos, maxSelectionCount: 1, matching: .images) {
                    VStack(spacing: 12) {
                        Image(systemName: "photo")
                            .font(.system(size: 40))
                            .foregroundColor(Up2Colors.textSecondary)
                        
                        Text("Add Cover Photo")
                            .font(Up2Typography.buttonMedium)
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .background(Up2Colors.surface)
                    .cornerRadius(12)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Basic Details")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            VStack(spacing: 12) {
                TextField("Event Title", text: $viewModel.eventTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Event Type (e.g., Party, Concert, Meetup)", text: $viewModel.eventType)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }
        }
    }
    
    // MARK: - Date & Time Section
    private var dateTimeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Date & Time")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            VStack(spacing: 12) {
                Button(action: { showingDatePicker = true }) {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(Up2Colors.textSecondary)
                        
                        Text(viewModel.formattedDateTime)
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                    .padding()
                    .background(Up2Colors.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Up2Colors.border, lineWidth: 1)
                    )
                }
            }
        }
        .sheet(isPresented: $showingDatePicker) {
            DatePickerView(date: $viewModel.eventDate, time: $viewModel.eventTime)
        }
    }
    
    // MARK: - Location Section
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Location")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            VStack(spacing: 12) {
                TextField("Venue Name", text: $viewModel.venueName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                TextField("Address", text: $viewModel.venueAddress)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: { showingLocationPicker = true }) {
                    HStack {
                        Image(systemName: "location")
                            .foregroundColor(Up2Colors.textSecondary)
                        
                        Text("Set Location on Map")
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(Up2Colors.textSecondary)
                    }
                    .padding()
                    .background(Up2Colors.surface)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Up2Colors.border, lineWidth: 1)
                    )
                }
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            VStack(spacing: 12) {
                HStack {
                    TextField("Price", text: $viewModel.price)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.decimalPad)
                    
                    Picker("Currency", selection: $viewModel.currency) {
                        Text("USD").tag("USD")
                        Text("EUR").tag("EUR")
                        Text("GBP").tag("GBP")
                    }
                    .pickerStyle(MenuPickerStyle())
                    .frame(width: 80)
                }
                
                if !viewModel.price.isEmpty {
                    Text("Price: \(viewModel.formattedPrice)")
                        .font(Up2Typography.bodyMedium)
                        .foregroundColor(Up2Colors.textSecondary)
                }
            }
        }
    }
    
    // MARK: - Description Section
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Description")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            TextEditor(text: $viewModel.eventDescription)
                .frame(minHeight: 120)
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
        VStack(alignment: .leading, spacing: 16) {
            Text("Vibe Tags")
                .font(Up2Typography.heading3)
                .foregroundColor(Up2Colors.textPrimary)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 8) {
                ForEach(VibeTag.allCases, id: \.self) { tag in
                    Button(action: {
                        viewModel.toggleVibeTag(tag)
                    }) {
                        Text(tag.rawValue)
                            .font(Up2Typography.buttonSmall)
                            .foregroundColor(viewModel.selectedVibeTags.contains(tag) ? .white : Up2Colors.textPrimary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedVibeTags.contains(tag) ?
                                Color(red: 0.0, green: 0.48, blue: 1.0) :
                                Up2Colors.surface
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
    
    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                Task {
                    await viewModel.updateEvent()
                    dismiss()
                }
            }) {
                Text("Update Event")
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
        }
        .padding(.top, 20)
    }
}

#Preview {
    EventEditView(event: HostEvent(
        id: UUID(),
        title: "Sample Event",
        venueName: "Sample Venue",
        date: Date(),
        rsvpCount: 0,
        price: 25.0,
        status: .upcoming,
        imageURL: nil
    ))
} 