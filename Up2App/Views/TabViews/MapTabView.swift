import SwiftUI
import MapKit

// MARK: - Map Tab View
struct MapTabView: View {
    
    // MARK: - Environment
    @EnvironmentObject var navigationCoordinator: NavigationCoordinator
    @EnvironmentObject var appStateManager: AppStateManager
    
    // MARK: - State
    @State private var position: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
    ))
    @State private var selectedEvent: MapEvent?
    @State private var mapStyle: MapKit.MapStyle = .standard
    @State private var showingMapStyle = false
    @State private var showingLocationAlert = false
    
    // MARK: - Mock Data
    private let mockEvents: [MapEvent] = [
        MapEvent(id: "1", title: "Rooftop Party", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)),
        MapEvent(id: "2", title: "Art Gallery Opening", coordinate: CLLocationCoordinate2D(latitude: 37.7649, longitude: -122.4094)),
        MapEvent(id: "3", title: "Food Truck Rally", coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4094)),
        MapEvent(id: "4", title: "Tech Meetup", coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4294))
    ]
    
    // MARK: - Map View
    private var mapView: some View {
        Map(position: $position) {
            ForEach(mockEvents) { event in
                Annotation(event.title, coordinate: event.coordinate) {
                    CustomEventMapPin(event: event, isSelected: selectedEvent?.id == event.id)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedEvent = event
                            }
                        }
                }
            }
        }
        .mapStyle(.hybrid(elevation: .realistic))
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                // Background - Consistent with host onboarding theme
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.black,
                        Color(red: 0.1, green: 0.0, blue: 0.3),
                        Color(red: 0.3, green: 0.0, blue: 0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Real Map View
                mapView
                    .ignoresSafeArea()
                
                // Top Controls Overlay
                VStack {
                    topControls
                    Spacer()
                }
                
                // Event Details Sheet
                if let selectedEvent = selectedEvent {
                    VStack {
                        Spacer()
                        eventDetailsSheet(for: selectedEvent)
                    }
                    .transition(.move(edge: .bottom))
                }
            }
            .navigationBarHidden(true)
            .alert("Location Access", isPresented: $showingLocationAlert) {
                Button("OK") { }
            } message: {
                Text("Location access will be implemented in the next update.")
            }
        }
        .onAppear {
            requestLocationPermissionIfNeeded()
        }
    }
    
    // MARK: - Top Controls
    private var topControls: some View {
        VStack(spacing: 16) {
            // Branded header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image("Logo")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 28, height: 28)
                        
                        Text("Discover Events")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    
                    Text("Find amazing events near you")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                // Interactive controls
                HStack(spacing: 12) {
                    // Filter button
                    Button(action: { showingMapStyle = true }) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                    
                    // Location button
                    Button(action: centerOnUserLocation) {
                        Image(systemName: "location.fill")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .clipShape(Circle())
                            .shadow(color: Color.blue.opacity(0.5), radius: 8, x: 0, y: 4)
                    }
                    
                    // Search button
                    Button(action: { 
                        navigationCoordinator.navigate(to: .eventSearch(query: nil))
                    }) {
                        Image(systemName: "magnifyingglass")
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                    }
                }
            }
            
            // Event count indicator
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                    
                    Text("\(mockEvents.count) events nearby")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                }
                
                Spacer()
                
                // Map legend
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                        Text("Tonight")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 8, height: 8)
                        Text("This Week")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 16)
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    // MARK: - Event Details Sheet
    private func eventDetailsSheet(for event: MapEvent) -> some View {
        VStack(spacing: 16) {
            // Handle bar
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.secondary.opacity(0.5))
                .frame(width: 36, height: 4)
            
            // Event info
            HStack(spacing: 16) {
                // Event icon
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(
                        colors: [.blue.opacity(0.7), .purple.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: "calendar")
                            .font(.title2)
                            .foregroundColor(.white)
                    )
                
                // Event details
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Text("Tap to see full details")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("View event page and buy tickets")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                
                Spacer()
                
                // Close button
                Button(action: { selectedEvent = nil }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons
            HStack(spacing: 12) {
                Button("View Event Details") {
                    // Navigate to the same EventDetailView as home feed
                    navigationCoordinator.navigate(to: .eventDetail(eventId: event.id))
                    selectedEvent = nil
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Button("Directions") {
                    openInMaps(event: event)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color(.systemGray5))
                .foregroundColor(.primary)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 32)
        .background(
            Color(.systemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(radius: 10)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    private func centerOnUserLocation() {
        // This would integrate with Core Location in a real implementation
        showingLocationAlert = true
    }
    
    private func requestLocationPermissionIfNeeded() {
        // Mock location permission request
        // In a real implementation, this would use CLLocationManager
    }
    
    private func openInMaps(event: MapEvent) {
        let placemark = MKPlacemark(coordinate: event.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = event.title
        mapItem.openInMaps(launchOptions: [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving])
    }
}

// MARK: - Custom Map Pin
struct CustomEventMapPin: View {
    let event: MapEvent
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Main pin
            ZStack {
                // Background circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: isSelected ? [Color.blue, Color.purple] : [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isSelected ? 50 : 40, height: isSelected ? 50 : 40)
                    .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Event icon
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: isSelected ? 20 : 16, weight: .semibold))
                    .foregroundColor(.white)
            }
            .scaleEffect(isSelected ? 1.2 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
            
            // Pin tail
            if isSelected {
                Triangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 20, height: 12)
                    .offset(y: -2)
            }
        }
    }
}

// MARK: - Triangle Shape
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

// MARK: - Supporting Types

struct MapEvent: Identifiable, Hashable, Equatable {
    let id: String
    let title: String
    let coordinate: CLLocationCoordinate2D
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: MapEvent, rhs: MapEvent) -> Bool {
        return lhs.id == rhs.id
    }
}



// MARK: - Supporting Views

struct EventMapPin: View {
    let event: MapEvent
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(isSelected ? Color.red : Color.blue)
                    .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                    .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                Image(systemName: "calendar")
                    .font(.system(size: isSelected ? 16 : 12))
                    .foregroundColor(.white)
            }
            
            if isSelected {
                Text(event.title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.systemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 2)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
}

struct MapStyleSelector: View {
    @Binding var selectedStyle: MapKit.MapStyle
    @Environment(\.presentationMode) var presentationMode
    
    private let mapStyles: [(MapKit.MapStyle, String, String, String)] = [
        (.standard, "Standard", "map", "standard"),
        (.imagery, "Satellite", "globe.asia.australia", "satellite"), 
        (.hybrid, "Hybrid", "map.fill", "hybrid")
    ]
    
    var body: some View {
        NavigationView {
            styleList
        }
    }
    
    private var styleList: some View {
        List {
            ForEach(mapStyles, id: \.3) { style, title, icon, id in
                styleRow(style: style, title: title, icon: icon)
            }
        }
        .navigationTitle("Map Style")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
    }
    
    private func styleRow(style: MapKit.MapStyle, title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            Text(title)
                .font(.body)
            
            Spacer()
            
            if isStyleSelected(style) {
                Image(systemName: "checkmark")
                    .foregroundColor(.blue)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            selectedStyle = style
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    private func isStyleSelected(_ style: MapKit.MapStyle) -> Bool {
        // Since MapStyle doesn't conform to Equatable, we compare by string representation
        return String(describing: selectedStyle) == String(describing: style)
    }
}

// MapKit.MapStyle is used directly 