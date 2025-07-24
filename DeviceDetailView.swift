import SwiftUI

struct DeviceDetailView: View {
    var item: HomeKitPairingCode
    var body: some View {
        Form {
            ContentUnavailableView(item.name ?? "Untitled Device", systemImage: item.category.symbol, description: Text(item.category.description))
        }
        .navigationTitle(item.name ?? "Untitled Device")
        .navigationBarTitleDisplayMode(.inline)
    }
}
