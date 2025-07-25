import SwiftUI

struct ContentView: View {
    @State var addCode = false
    @State var importExport = false
    @StateObject var manager = CodesManager.shared
    @State var categoryFilters: [HomeKitCategory] = []
    @State var searchText = ""
    
    @State var codeToEdit: HomeKitPairingCode?
    var body: some View {
        NavigationStack {
            VStack {
                let filteredCodes = manager.codes.filter { code in
                    let matchesCategory = categoryFilters.isEmpty || categoryFilters.contains(code.category)
                    let matchesSearch = searchText.isEmpty || (code.name?.lowercased().contains(searchText.lowercased()) ?? false)
                    return matchesCategory && matchesSearch
                }
                
                if manager.codes.isEmpty {
                    ContentUnavailableView("No Codes added yet", systemImage: "plus.app", description: Text("Add a Code by tapping the + Icon in the Top Right Corner"))
                } else {
                    List {
                        Section {
                            if filteredCodes.isEmpty {
                                ContentUnavailableView("No Results containing \"\(searchText)\" or the Selected Filters found", systemImage: "magnifyingglass", description: Text("Try removing Filters or changing your Search Term"))
                            }
                            ForEach(filteredCodes.sorted(by: { String($0.name ?? "Untitled") < String($1.name ?? "Untitled") })) { code in
                                NavigationLink(destination: {
                                    DeviceDetailView(item: code)
                                }) {
                                    HStack {
                                        Image(systemName: code.category.symbol)
                                            .scaledToFit()
                                            .frame(width: 50)
                                        VStack(alignment: .leading) {
                                            Text(code.name ?? "Untitled Device")
                                            Text(code.category.description)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.vertical, 5)
                                }
                                .swipeActions {
                                    Button("Delete", systemImage: "trash") {
                                        manager.codes.removeAll(where: { $0.id == code.id })
                                    }
                                    .tint(.red)
                                    Button("Edit", systemImage: "pencil") {
                                        codeToEdit = code
                                    }
                                    .tint(.accentColor)
                                }
                            }
                        } header: {
                            headerView
                        }
                        .listSectionSeparator(.hidden)
                    }
                }
            }
            .navigationTitle("Pairing Codes")
            .searchable(text: $searchText, prompt: Text("Search Name or Category"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Import/Export", systemImage: "cloud") {
                        importExport.toggle()
                    }
                    .labelStyle(.iconOnly)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add Code", systemImage: "plus") {
                        addCode.toggle()
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $addCode) {
                AddPairingCodeView()
            }
            .sheet(item: $codeToEdit) { editCode in
                EditPairingCodeView(newCodeObject: editCode)
            }
            .sheet(isPresented: $importExport) {
                ImportExportView()
            }
        }
    }
    var headerView: some View { 
        ScrollView(.horizontal) {
            HStack(spacing: 2.5) {
                if !categoryFilters.isEmpty {
                    Button("Clear All", systemImage: "xmark") {
                        categoryFilters = []
                    }
                    .labelStyle(.iconOnly)
                    .buttonStyle(.bordered)
                    .buttonBorderShape(.circle)
                    .bold()
                    .tint(.gray)
                }
                ForEach(HomeKitCategory.allCases.sorted(by: { $0.description < $1.description }), id: \.self) { category in 
                    if searchText.isEmpty ? true : category.description.lowercased().contains(searchText.lowercased()) {
                        Toggle(isOn: Binding(get: {
                            categoryFilters.contains(category)
                        }, set: { bool in
                            if bool {
                                categoryFilters.append(category)
                            } else {
                                categoryFilters.removeAll(where: { $0 == category })
                            }
                        })) {
                            HStack {
                                Image(systemName: category.symbol)
                                    .symbolVariant(categoryFilters.contains(category) ? .fill : .none)
                                Text(category.description)
                            }
                        }
                        .toggleStyle(.button)
                        .buttonBorderShape(.capsule)
                    }
                }
            }
            .animation(.default, value: categoryFilters)
        }
        .scrollIndicators(.never)
        .padding(.horizontal, -25)
    }
}

struct AddPairingCodeView: View {
    @Environment(\.dismiss) var dismiss
    @State var newCodeObject: HomeKitPairingCode = .init(pairingCode: "", setupID: "", category: .other)
    @State var scanCode = false
    @State var categorySearchText = ""
    @StateObject var manager = CodesManager.shared
    @AppStorage("com.apple.SwiftUI.IgnoreSolariumLinkedOnCheck") var forceGlass = false
    @State var debug = false
    @State var restart = false
    var body: some View {
        NavigationStack {
            Form {
                TextField("Device Name", text: Binding(get: { newCodeObject.name ?? "" }, set: { newCodeObject.name = $0.isEmpty ? nil : $0}))
                TextField("Setup ID", text: $newCodeObject.setupID)
                TextField("Pairing Code", text: Binding(get: {
                    newCodeObject.pairingCode == "000-00-000" ? "" : newCodeObject.pairingCode
                }, set: {
                    newCodeObject.pairingCode = $0
                }))
                .keyboardType(.decimalPad)
                HomeKitCategoryPickerView(selectedCategory: $newCodeObject.category, title: "Category", searchText: $categorySearchText)
                    .pickerStyle(.navigationLink)
                    .foregroundStyle(.tint)
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Button(action: {
                            scanCode = true
                        }) {
                            HStack {
                                Label("Scan", systemImage: "qrcode.viewfinder")
                                Spacer()
                            }
                        }
                        Text("The Scanning Feature is very experimental, has proven unreliable for now and is not recommended")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
                    .contentShape(.rect)
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 5)
                            .onEnded({ _ in
                                debug.toggle()
                            })
                    )
                    .swipeActions {
                        if debug {
                            Button("Toggle Force Glass", systemImage: "drop.fill") {
                                forceGlass.toggle()
                                restart = true
                            }
                            .symbolVariant(forceGlass ? .slash : .none)
                            .tint(forceGlass ? .red : .green)
                        }
                    }
                    .alert("Restart Required", isPresented: $restart, actions: {
                        Button("OK") {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                                restart = true
                            }
                        }
                    }, message: {
                        Text("Restart this App to see the Effects apply")
                    })
                }
            }
            .navigationTitle("Add Pairing Code")
            .navigationBarTitleDisplayMode(.inline)
            .onChange(of: categorySearchText) { 
                if !categorySearchText.isEmpty && !HomeKitCategory.allCases.contains(where: { $0.description == newCodeObject.category.description }){
                    if !HomeKitCategory.allCases.contains(where: { $0.description.lowercased().contains(categorySearchText) }) {
                        newCodeObject.category = HomeKitCategory.allCases.first(where: { $0.description.lowercased().contains(categorySearchText) }) ?? HomeKitCategory.allCases.first!
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    manager.codes.append(newCodeObject)
                    dismiss()
                }) {
                    HStack {
                        Spacer()
                        Text("Done")
                            .bold()
                        Spacer()
                    }
                    .padding(10)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.automatic)
                .disabled(newCodeObject.pairingCode == "000-00-000" ? true : !newCodeObject.isValid)
                .padding()
            }
            .fullScreenCover(isPresented: $scanCode) {
                NavigationStack {
                    HomeKitQRScannerView { setupID, pairingCode, category in
                        if let setupID {
                            newCodeObject.setupID = setupID
                        }
                        if let pairingCode {
                            newCodeObject.pairingCode = pairingCode
                        }
                        if let category {
                            newCodeObject.category = category
                        }
                        scanCode = false
                    } dismiss: { 
                        scanCode = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                scanCode = false
                            }) {
                                Image(systemName: "xmark")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.gray)
                                    .bold()
                                    .padding(7.5)
                                    .background(.ultraThinMaterial)
                                    .clipShape(.circle)
                                    .padding()
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .navigationTitle("Scan HomeKit Pairing Code")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationBackground(.ultraThinMaterial)
            }
        }
    }
}  

struct EditPairingCodeView: View {
    @Environment(\.dismiss) var dismiss
    @State var newCodeObject: HomeKitPairingCode = .init(pairingCode: "", setupID: "", category: .other)
    @State var scanCode = false
    @State var categorySearchText = ""
    @StateObject var manager = CodesManager.shared
    var body: some View {
        NavigationStack {
            Form {
                TextField("Device Name", text: Binding(get: { newCodeObject.name ?? "" }, set: { newCodeObject.name = $0.isEmpty ? nil : $0}))
                TextField("Setup ID", text: $newCodeObject.setupID)
                TextField("Pairing Code", text: Binding(get: {
                    newCodeObject.pairingCode == "000-00-000" ? "" : newCodeObject.pairingCode
                }, set: {
                    newCodeObject.pairingCode = $0
                }))
                .keyboardType(.decimalPad)
                HomeKitCategoryPickerView(selectedCategory: $newCodeObject.category, title: "Category", searchText: $categorySearchText)
                    .pickerStyle(.navigationLink)
                    .foregroundStyle(.tint)
                Button("Scan", systemImage: "qrcode.viewfinder") {
                    scanCode = true
                }
            }
            .navigationTitle("Add Pairing Code")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $categorySearchText, prompt: "Search Category")
            .onChange(of: categorySearchText) { 
                if !categorySearchText.isEmpty && !HomeKitCategory.allCases.contains(where: { $0.description == newCodeObject.category.description }){
                    if !HomeKitCategory.allCases.contains(where: { $0.description.lowercased().contains(categorySearchText) }) {
                        newCodeObject.category = HomeKitCategory.allCases.first(where: { $0.description.lowercased().contains(categorySearchText) }) ?? HomeKitCategory.allCases.first!
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    replace()
                    dismiss()
                }) {
                    HStack {
                        Spacer()
                        Text("Done")
                            .bold()
                        Spacer()
                    }
                    .padding(10)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.automatic)
                .disabled(newCodeObject.pairingCode == "000-00-000" ? true : !newCodeObject.isValid)
                .padding()
            }
            .fullScreenCover(isPresented: $scanCode) {
                NavigationStack {
                    HomeKitQRScannerView { setupID, pairingCode, category in
                        if let setupID {
                            newCodeObject.setupID = setupID
                        }
                        if let pairingCode {
                            newCodeObject.pairingCode = pairingCode
                        }
                        if let category {
                            newCodeObject.category = category
                        }
                        scanCode = false
                    } dismiss: { 
                        scanCode = false
                    }
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button(action: {
                                scanCode = false
                            }) {
                                Image(systemName: "xmark")
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.gray)
                                    .bold()
                                    .padding(7.5)
                                    .background(.ultraThinMaterial)
                                    .clipShape(.circle)
                                    .padding()
                            }
                        }
                    }
                    .ignoresSafeArea()
                    .navigationTitle("Scan HomeKit Pairing Code")
                    .navigationBarTitleDisplayMode(.inline)
                }
                .presentationBackground(.ultraThinMaterial)
            }
        }
    }
    func replace() {
        let index = manager.codes.firstIndex(where: { $0.id == newCodeObject.id })!
        manager.codes[index] = newCodeObject
    }
}

struct HomeKitPairingCode: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String? = nil
    var pairingCode: String {
        didSet {
            pairingCode = Self.validatedPairingCode(pairingCode)
        }
    }
    
    var setupID: String {
        didSet {
            setupID = Self.validatedSetupID(setupID)
        }
    }
    
    var category: HomeKitCategory
    
    init(pairingCode: String, setupID: String, category: HomeKitCategory) {
        self.pairingCode = Self.validatedPairingCode(pairingCode)
        self.setupID = Self.validatedSetupID(setupID)
        self.category = category
    }
    
    /// Checks if the pairing code is valid according to HomeKit rules
    var isValid: Bool {
        let digitsOnly = pairingCode.filter(\.isNumber)
        let setupIDValid = setupID.count == 4 && setupID.allSatisfy { $0.isLetter || $0.isNumber }
        let pairingCodeValid = digitsOnly.count == 8 && UInt32(digitsOnly) != nil
        return pairingCodeValid && setupIDValid
    }
    
    /// Generate QR code image
    func qrCode() -> UIImage? {
        guard isValid else { return nil }
        return generateHomeKitQRCode(pairingCode: pairingCode, setupID: setupID, category: category)
    }
    
    // MARK: - Validation Helpers
    
    private static func validatedPairingCode(_ input: String) -> String {
        let digits = input.filter(\.isNumber)
        let limited = String(digits.prefix(8))
        return formatPairingCode(limited)
    }
    
    private static func validatedSetupID(_ input: String) -> String {
        let alphanumerics = input.uppercased().filter { $0.isNumber || $0.isLetter }
        return String(alphanumerics.prefix(4))
    }
    
    private static func formatPairingCode(_ raw: String) -> String {
        let padded = raw.padding(toLength: 8, withPad: "0", startingAt: 0)
        let part1 = padded.prefix(3)
        let part2 = padded.dropFirst(3).prefix(2)
        let part3 = padded.dropFirst(5)
        return "\(part1)-\(part2)-\(part3)"
    }
}

class CodesManager: ObservableObject {
    init() {
        if let existingData = try? Data(contentsOf: Self.databaseURL), let decoded = try? JSONDecoder().decode([HomeKitPairingCode].self, from: existingData) {
            self.codes = decoded
        } else {
            self.codes = []
        }
    }
    static var storageDirectory: URL {
        let baseURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL.documentsDirectory
        let constructedURL = baseURL.appendingPathComponent("HomeKitPairingCodes")
        if !FileManager.default.fileExists(atPath: constructedURL.path()) {
            try? FileManager.default.createDirectory(at: constructedURL, withIntermediateDirectories: true)
        }
        return constructedURL
    }
    static var databaseURL: URL {
        storageDirectory.appendingPathComponent("database", conformingTo: .json)
    }
    static let shared = CodesManager()
    @Published var codes: [HomeKitPairingCode] {
        didSet {
            if let encoded = try? JSONEncoder().encode(codes) {
                try? encoded.write(to: Self.databaseURL)
            }
        }
    }
}
