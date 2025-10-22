import SwiftUI

/// Displays the Headless Dropshipping Starter repository inside the app using a web view.
struct HeadlessDropshippingStarterView: View {
    @Environment(\.dismiss) private var dismiss

    private let repositoryURL = URL(string: "https://github.com/notrab/headless-dropshipping-starter")!

    var body: some View {
        NavigationView {
            Up2WebView(url: repositoryURL)
                .navigationTitle("Dropshipping Starter")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Close") {
                            dismiss()
                        }
                    }

                    ToolbarItem(placement: .primaryAction) {
                        Link(destination: repositoryURL) {
                            Image(systemName: "safari")
                        }
                        .accessibilityLabel("Open in Safari")
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

#Preview {
    HeadlessDropshippingStarterView()
}
