import SwiftUI

struct VibeTagsSelectionView: View {
    @Binding var selectedTags: [VibeTag]
    let maxSelections: Int
    let showCategories: Bool
    
    @State private var validationMessage: String?
    
    init(selectedTags: Binding<[VibeTag]>, maxSelections: Int = 5, showCategories: Bool = true) {
        self._selectedTags = selectedTags
        self.maxSelections = maxSelections
        self.showCategories = showCategories
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.lg) {
            // Header
            VStack(alignment: .leading, spacing: Up2Spacing.sm) {
                Text("Choose Your Vibe")
                    .font(Up2Typography.heading3)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Text("Select up to \(maxSelections) tags that describe your mood and interests")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                
                // Selection counter
                HStack {
                    Text("\(selectedTags.count) / \(maxSelections) selected")
                        .font(Up2Typography.caption)
                        .foregroundColor(selectedTags.count == maxSelections ? Up2Colors.warning : Up2Colors.textSecondary)
                    
                    Spacer()
                    
                    if selectedTags.count > 0 {
                        Button("Clear All") {
                            selectedTags.removeAll()
                            validationMessage = nil
                        }
                        .font(Up2Typography.caption)
                        .foregroundColor(Up2Colors.error)
                    }
                }
            }
            
            // Validation message
            if let message = validationMessage {
                Text(message)
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                    .padding(.horizontal, Up2Spacing.md)
                    .padding(.vertical, Up2Spacing.sm)
                    .background(Up2Colors.error.opacity(0.1))
                    .cornerRadius(Up2Spacing.sm)
            }
            
            // Tags by category or all together
            if showCategories {
                categorizedTagsView
            } else {
                allTagsView
            }
            
            Spacer()
        }
        .onChange(of: selectedTags) { tags in
            validateSelection(tags)
        }
    }
    
    @ViewBuilder
    private var categorizedTagsView: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Up2Spacing.xl) {
                ForEach(VibeTagCategory.allCases, id: \.self) { category in
                    VStack(alignment: .leading, spacing: Up2Spacing.md) {
                        Text(category.displayName)
                            .font(Up2Typography.heading4)
                            .foregroundColor(Up2Colors.textPrimary)
                        
                        TagGridView(
                            tags: VibeTag.allCases.filter { $0.category == category },
                            selectedTags: $selectedTags,
                            maxSelections: maxSelections
                        )
                    }
                }
            }
            .padding(.vertical, Up2Spacing.sm)
        }
    }
    
    @ViewBuilder
    private var allTagsView: some View {
        ScrollView {
            TagGridView(
                tags: VibeTag.allCases,
                selectedTags: $selectedTags,
                maxSelections: maxSelections
            )
            .padding(.vertical, Up2Spacing.sm)
        }
    }
    
    private func validateSelection(_ tags: [VibeTag]) {
        if tags.count > maxSelections {
            validationMessage = "You can only select up to \(maxSelections) tags"
        } else {
            validationMessage = nil
        }
    }
}

// MARK: - Tag Grid View

struct TagGridView: View {
    let tags: [VibeTag]
    @Binding var selectedTags: [VibeTag]
    let maxSelections: Int
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: Up2Spacing.sm)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: Up2Spacing.sm) {
            ForEach(tags, id: \.self) { tag in
                Up2Tag(
                    tag.displayName,
                    style: isSelected(tag) ? .filled : .outlined,
                    size: .medium,
                    state: canSelectTag(tag) ? .normal : .disabled,
                    action: canSelectTag(tag) ? {
                        toggleTagSelection(tag)
                    } : nil
                )
            }
        }
    }
    
    private func isSelected(_ tag: VibeTag) -> Bool {
        selectedTags.contains(tag)
    }
    
    private func canSelectTag(_ tag: VibeTag) -> Bool {
        return isSelected(tag) || selectedTags.count < maxSelections
    }
    
    private func toggleTagSelection(_ tag: VibeTag) {
        if let index = selectedTags.firstIndex(of: tag) {
            // Deselect tag
            selectedTags.remove(at: index)
        } else if selectedTags.count < maxSelections {
            // Select tag
            selectedTags.append(tag)
        }
    }
}

// MARK: - Compact Vibe Tags View (for displaying selected tags)

struct CompactVibeTagsView: View {
    let tags: [VibeTag]
    let maxDisplayed: Int
    
    var body: some View {
        HStack {
            ForEach(Array(tags.prefix(maxDisplayed).enumerated()), id: \.element) { index, tag in
                Up2Tag(
                    tag.displayName,
                    style: .subtle,
                    size: .small
                )
                
                if index < min(tags.count, maxDisplayed) - 1 {
                    // Add spacing between tags
                }
            }
            
            if tags.count > maxDisplayed {
                Up2Tag(
                    "+\(tags.count - maxDisplayed)",
                    style: .subtle,
                    size: .small
                    )
            }
        }
    }
}

// Note: VibeTagCategory displayName is already defined in ProfileModels.swift

// MARK: - Enhanced Vibe Tags View for Profile Display

struct ProfileVibeTagsView: View {
    let tags: [VibeTag]
    let isEditable: Bool
    let onEdit: (() -> Void)?
    
    init(tags: [VibeTag], isEditable: Bool = false, onEdit: (() -> Void)? = nil) {
        self.tags = tags
        self.isEditable = isEditable
        self.onEdit = onEdit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.md) {
            HStack {
                Text("Vibe Tags")
                    .font(Up2Typography.heading4)
                    .foregroundColor(Up2Colors.textPrimary)
                
                Spacer()
                
                if isEditable, let onEdit = onEdit {
                    Button("Edit") {
                        onEdit()
                    }
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.primary)
                }
            }
            
            if tags.isEmpty {
                Text("No vibe tags selected")
                    .font(Up2Typography.bodyMedium)
                    .foregroundColor(Up2Colors.textSecondary)
                    .italic()
            } else {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 80), spacing: Up2Spacing.xs)
                ], spacing: Up2Spacing.xs) {
                    ForEach(tags, id: \.self) { tag in
                        Up2Tag(
                            tag.displayName,
                            style: .filled,
                            size: .small
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Searchable Vibe Tags View

struct SearchableVibeTagsView: View {
    @Binding var selectedTags: [VibeTag]
    let maxSelections: Int
    
    @State private var searchText = ""
    @State private var selectedCategory: VibeTagCategory?
    
    var filteredTags: [VibeTag] {
        var tags = VibeTag.allCases
        
        if let category = selectedCategory {
            tags = tags.filter { $0.category == category }
        }
        
        if !searchText.isEmpty {
            tags = tags.filter { $0.displayName.localizedCaseInsensitiveContains(searchText) }
        }
        
        return tags
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Up2Spacing.lg) {
            // Search Bar
            VibeTagsSearchBar(text: $searchText)
            
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Up2Spacing.sm) {
                    Up2Tag(
                        "All",
                        style: selectedCategory == nil ? .filled : .outlined,
                        size: .small,
                        action: {
                            selectedCategory = nil
                        }
                    )
                    
                    ForEach(VibeTagCategory.allCases, id: \.self) { category in
                        Up2Tag(
                            category.displayName,
                            style: selectedCategory == category ? .filled : .outlined,
                            size: .small,
                            action: {
                                selectedCategory = category
                            }
                        )
                    }
                }
                .padding(.horizontal, Up2Spacing.xs)
            }
            
            // Selection Info
            HStack {
                Text("\(selectedTags.count) / \(maxSelections) selected")
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.textSecondary)
                
                Spacer()
                
                if !selectedTags.isEmpty {
                    Button("Clear") {
                        selectedTags.removeAll()
                    }
                    .font(Up2Typography.caption)
                    .foregroundColor(Up2Colors.error)
                }
            }
            
            // Tags Grid
            ScrollView {
                TagGridView(
                    tags: filteredTags,
                    selectedTags: $selectedTags,
                    maxSelections: maxSelections
                )
            }
        }
    }
}

// MARK: - Vibe Tags Search Bar

struct VibeTagsSearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(Up2Colors.textSecondary)
            
            TextField("Search tags...", text: $text)
                .font(Up2Typography.bodyMedium)
                .foregroundColor(Up2Colors.textPrimary)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Up2Colors.textSecondary)
                }
                    }
                }
        .padding(Up2Spacing.md)
        .background(Up2Colors.surface)
        .cornerRadius(Up2Spacing.sm)
        .overlay(
            RoundedRectangle(cornerRadius: Up2Spacing.sm)
                .stroke(Up2Colors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        VibeTagsSelectionView(
            selectedTags: .constant([]),
            maxSelections: 5,
            showCategories: true
        )
        }
    .padding()
} 