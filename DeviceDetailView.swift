import SwiftUI

struct DeviceDetailView: View {
    var item: HomeKitPairingCode
    var body: some View {
        Form {
            ContentUnavailableView(item.name ?? "Untitled Device", systemImage: item.category.symbol, description: Text(item.category.description))
            Section("Setup ID")  {
                Text(item.setupID)
                    .textSelection(.enabled)
            }
            Section("Pairing Code") {
                Text(item.pairingCode)
                    .textSelection(.enabled)
            }
            if let image = item.qrCode() {
                Section("QR Code") {
                    HStack {
                        Spacer()
                        Image(uiImage: image)
                            .interpolation(.none)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 250, height: 250)
                        Spacer()
                    }
                    
                }
            }
        }
        .navigationTitle(item.name ?? "Untitled Device")
        .navigationBarTitleDisplayMode(.inline)
    }
}
