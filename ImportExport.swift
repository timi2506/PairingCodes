import SwiftUI

struct ImportExportView: View {
    @StateObject var manager = CodesManager.shared
    @State var importMethod: ImportMethod = .importAndAdd
    @State var showImporter = false
    @State var importError: Error?
    @State var export = false
    var body: some View {
        Form {
            Section {
                ContentUnavailableView("Import/Export", systemImage: "cloud", description: Text("Import and Export your Pairing Codes"))
            }
            Picker("Import Method", selection: $importMethod) {
                Text("Replace Existing")
                    .tag(ImportMethod.importAndReplace)
                    .foregroundStyle(.tint)
                Text("Add to Existing")
                    .tag(ImportMethod.importAndAdd)
                    .foregroundStyle(.tint)
            }
            .pickerStyle(.inline)
            Section {
                Button("Import", systemImage: "arrow.down.document") {
                    showImporter.toggle()
                }
                Group {
                    if ProcessInfo.processInfo.isiOSAppOnMac {
                        Button(action: {
                            export.toggle()
                        }) {
                            Label("Export", systemImage: "arrow.up.document")
                        }
                    } else {
                        ShareLink(item: CodesManager.databaseURL.attemptTempCopy("PairingCodes Export \(Date().formatted(date: .abbreviated, time: .omitted))"), preview: SharePreview("Pairing Codes Export", icon: Data())) {
                            Label("Export", systemImage: "arrow.up.document")
                        }
                    }
                }
                .disabled(manager.codes.isEmpty)
            } footer: {
                Text("Export your codes to securely back them up or share with another device.\n\nImporting allows you to quickly restore your codes, such as when setting up a new device.")
            }
        }
        .navigationTitle("Import/Export")
        .fileImporter(isPresented: $showImporter, allowedContentTypes: [.json]) { result in
            switch result {
            case .success(let url):
                importMethod.performImport(url, $importError)
            case .failure(let error):
                importError = error
            }
        }
        .fileExporter(
            isPresented: $export,
            item: ExportedJSONFile(url: CodesManager.databaseURL.attemptTempCopy("PairingCodes Export \(Date().formatted(date: .abbreviated, time: .omitted))")),
            contentTypes: [.json],
            defaultFilename: "PairingCodes Export"
        ) { result in
            do {
                print(try result.get())
            } catch {
                print(error.localizedDescription)
            }
        }

        .alert("Error Importing Codes", isPresented: Binding(get: { importError != nil }, set: { if !$0 { importError = nil } }), actions: {
            Button("OK") {
                importError = nil
            }
        }, message: {
            if let importError {
                Text(importError.localizedDescription)
            } else {
                Text("An Unknown Error occured")
            }
        })
    }
    enum ImportMethod: Hashable {
        case importAndAdd
        case importAndReplace
        func performImport(_ url: URL, _ errorBinding: Binding<Error?>) {
            do {
                let data = try Data(contentsOf: url)
                let decoded = try JSONDecoder().decode([HomeKitPairingCode].self, from: data)
                switch self {
                case .importAndAdd:
                    print("Importing and adding", url.absoluteString)
                    for item in decoded {
                        if CodesManager.shared.codes.contains(where: { $0.id == item.id }) {
                            let newItem = HomeKitPairingCode(pairingCode: item.pairingCode, setupID: item.setupID, category: item.category)
                            CodesManager.shared.codes.append(newItem)
                        } else {
                            CodesManager.shared.codes.append(item)
                        }
                    }
                case .importAndReplace:
                    print("Importing and replacing", url.absoluteString)
                    CodesManager.shared.codes = decoded
                }
            } catch {
                errorBinding.wrappedValue = error
            }
        }
    }
}

///*@START_MENU_TOKEN@*//*@PLACEHOLDER=There's code hidden behind me!@*/Text("This is Hidden Code")/*@END_MENU_TOKEN@*/
///*@START_MENU_TOKEN@*//*@PLACEHOLDER="Hi!"@*/Text("Hi")/*@END_MENU_TOKEN@*/

#Preview {
    ImportExportView()
}

extension URL {
    func attemptTempCopy(_ baseFileName: String? = nil) -> URL {
        let name = baseFileName ?? self.deletingPathExtension().lastPathComponent
        let ext = self.pathExtension.isEmpty ? "json" : self.pathExtension
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(name)
            .appendingPathExtension(ext)

        do {
            if FileManager.default.fileExists(atPath: tempURL.path) {
                try FileManager.default.removeItem(at: tempURL)
            }
            try FileManager.default.copyItem(at: self, to: tempURL)
            return tempURL
        } catch {
            print("Temp copy failed: \(error.localizedDescription)")
            return self
        }
    }
}

import UniformTypeIdentifiers
import SwiftUI

struct ExportedJSONFile: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .json) { file in
            SentTransferredFile(file.url)
        }
    }
}
