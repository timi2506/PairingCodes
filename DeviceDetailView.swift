import SwiftUI
import UniformTypeIdentifiers

struct DeviceDetailView: View {
    var item: HomeKitPairingCode
    var body: some View {
        Form {
            ContentUnavailableView(item.name ?? "Untitled Device", systemImage: item.category.symbol, description: Text(item.category.description))
            Section("Setup ID")  {
                HStack {
                    Text(item.setupID)
                    Spacer()
                }
                .contentShape(.rect)
                .contextMenu {
                    Button("Copy to Clipboard", systemImage: "document.on.document") {
                        UIPasteboard.general.string = item.setupID
                    }
                }
            }
            Section("Pairing Code") {
                HStack {
                    Text(item.pairingCode)
                    Spacer()
                }
                .contentShape(.rect)
                .contextMenu {
                    Button("Copy to Clipboard", systemImage: "document.on.document") {
                        UIPasteboard.general.string = item.pairingCode
                    }
                }
            }
            if let image = item.qrCode(), let imageURL = image.pngData()?.tempWritten(.png, fileName: "\(item.name ?? "Device") QR Code") {
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
                    .contextMenu {
                        ShareLink("Share", item: imageURL)
                    }
                    Text("This QR Code might not work as expected and should be used with caution, it is not guaranteed to work")
                        .font(.caption)
                        .foregroundStyle(.gray)
                }
                if UIApplication.shared.canOpenURL(URL(string: "com.apple.home://launch")!) {
                    Button("Launch Apple Home", systemImage: "homekit") {
                        UIApplication.shared.open(URL(string: "com.apple.home://launch")!)
                    }
                }
            }
        }
        .navigationTitle(item.name ?? "Untitled Device")
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension Data {
    func tempWritten(_ type: UTType = .data, fileName: String = "temporaryFile") -> URL? {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName, conformingTo: type)
        return (try? self.write(to: url)) == nil ? nil : url
    }
}
