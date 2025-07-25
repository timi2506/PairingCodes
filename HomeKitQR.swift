import UIKit
import CoreImage.CIFilterBuiltins

enum HomeKitCategory: UInt8, CaseIterable, Identifiable, Codable {
    var id: UInt8 { rawValue }
    
    case other = 1
    case bridge = 2
    case fan = 3
    case garageDoorOpener = 4
    case lightbulb = 5
    case doorLock = 6
    case outlet = 7
    case switchDevice = 8
    case thermostat = 9
    case sensor = 10
    case securitySystem = 11
    case door = 12
    case window = 13
    case windowCovering = 14
    case programmableSwitch = 15
    case rangeExtender = 16
    case ipCamera = 17
    case videoDoorbell = 18
    case airPurifier = 19
    case heater = 20
    case airConditioner = 21
    case humidifier = 22
    case dehumidifier = 23
    case appleTV = 24
    case speaker = 25
    case airport = 26
    case sprinkler = 27
    case faucet = 28
    case showerHead = 29
    case television = 30
    case targetController = 31
    case router = 32
    case audioReceiver = 33
    case tvSetTopBox = 34
    case tvSoundbar = 35
    case speaker2 = 36
    case airPlaySpeaker = 37
    case streamingStick = 38
    case display = 39
    case streamer = 40
    case setTopBox = 41
    case audioSystem = 42
    case videoProjector = 43
    case videoStreamingBox = 44
    
    var description: String {
        switch self {
        case .other: return "Other"
        case .bridge: return "Bridge"
        case .fan: return "Fan"
        case .garageDoorOpener: return "Garage Door"
        case .lightbulb: return "Lightbulb"
        case .doorLock: return "Door Lock"
        case .outlet: return "Outlet"
        case .switchDevice: return "Switch"
        case .thermostat: return "Thermostat"
        case .sensor: return "Sensor"
        case .securitySystem: return "Security System"
        case .door: return "Door"
        case .window: return "Window"
        case .windowCovering: return "Window Covering"
        case .programmableSwitch: return "Programmable Switch"
        case .rangeExtender: return "Range Extender"
        case .ipCamera: return "IP Camera"
        case .videoDoorbell: return "Video Doorbell"
        case .airPurifier: return "Air Purifier"
        case .heater: return "Heater"
        case .airConditioner: return "Air Conditioner"
        case .humidifier: return "Humidifier"
        case .dehumidifier: return "Dehumidifier"
        case .appleTV: return "Apple TV"
        case .speaker: return "Speaker"
        case .speaker2: return "Speaker 2"
        case .airPlaySpeaker: return "AirPlay Speaker"
        case .airport: return "Airport"
        case .sprinkler: return "Sprinkler"
        case .faucet: return "Faucet"
        case .showerHead: return "Shower Head"
        case .television: return "Television"
        case .targetController: return "Target Controller"
        case .router: return "Router"
        case .audioReceiver: return "Audio Receiver"
        case .tvSetTopBox: return "TV Set-Top Box"
        case .tvSoundbar: return "TV Soundbar"
        case .streamingStick: return "Streaming Stick"
        case .display: return "Display"
        case .streamer: return "Streamer"
        case .setTopBox: return "Set-Top Box"
        case .audioSystem: return "Audio System"
        case .videoProjector: return "Video Projector"
        case .videoStreamingBox: return "Streaming Box"
        }
    }
    
    var symbol: String {
        switch self {
        case .lightbulb: return "lightbulb"
        case .fan: return "fanblades"
        case .garageDoorOpener: return "door.garage.closed"
        case .doorLock: return "lock"
        case .outlet: return "powerplug"
        case .switchDevice: return "switch.2"
        case .thermostat: return "thermometer"
        case .sensor: return "sensor.tag.radiowaves.forward"
        case .securitySystem: return "shield.lefthalf.filled"
        case .door: return "door.left.hand.open"
        case .window: return "window.horizontal"
        case .windowCovering: return "window.shade.open"
        case .ipCamera: return "video"
        case .videoDoorbell: return "bell.circle"
        case .airPurifier: return "wind"
        case .heater: return "flame"
        case .airConditioner: return "snowflake"
        case .humidifier: return "humidity"
        case .dehumidifier: return "drop"
        case .appleTV: return "appletv"
        case .tvSetTopBox, .streamingStick, .setTopBox, .videoStreamingBox: return "tv"
        case .speaker, .speaker2, .airPlaySpeaker: return "speaker.wave.2"
        case .airport: return "wifi.router"
        case .sprinkler: return "sprinkler.and.droplets"
        case .faucet: return "spigot"
        case .showerHead: return "shower"
        case .television: return "tv"
        case .router: return "network"
        case .audioReceiver, .audioSystem, .tvSoundbar: return "hifispeaker"
        case .display: return "display"
        case .streamer: return "dot.radiowaves.left.and.right"
        case .programmableSwitch: return "cpu"
        case .bridge: return "arrow.triangle.branch"
        case .rangeExtender: return "wifi"
        case .targetController: return "scope"
        case .other: return "questionmark.app"
        case .videoProjector: return "videoprojector"
        }
    }
}

func generateHomeKitQRCode(pairingCode: String, setupID: String, category: HomeKitCategory) -> UIImage? {
    let version: UInt8 = 0
    let reserved: UInt8 = 0
    let flags: UInt8 = 2 // 1 = IP, 2 = BLE, 4 = Wired (BLE is safest default)
    
    guard let pin = UInt32(pairingCode.replacingOccurrences(of: "-", with: "")) else { return nil }
    
    var payload = UInt64(version)
    payload |= UInt64(reserved) << 3
    payload |= UInt64(category.rawValue) << 4
    payload |= UInt64(flags) << 11
    payload |= UInt64(pin) << 13
    
    let setupPayload = base36Encode(payload) + setupID
    let pairingString = "X-HM://" + setupPayload
    
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(pairingString.utf8)
    
    if let outputImage = filter.outputImage {
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        if let cgimg = context.createCGImage(scaledImage, from: scaledImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }
    
    return nil
}

private func base36Encode(_ value: UInt64) -> String {
    let alphabet = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ")
    var result = ""
    var num = value
    repeat {
        let index = Int(num % 36)
        result = String(alphabet[index]) + result
        num /= 36
    } while num > 0
    return result
}


import SwiftUI

struct HomeKitCategoryPickerView: View {
    @Binding var selectedCategory: HomeKitCategory
    var title: String = "HomeKit Category"
    var titleSymbol: String?
    @Binding var searchText: String
    @State var searching: Bool = false
    var body: some View {
        Picker(selection: $selectedCategory) {
            if !(searchText.isEmpty || HomeKitCategory.allCases.contains(where: { $0.description.lowercased().contains(searchText.lowercased()) })) {
                ContentUnavailableView.search(text: searchText)
            }
            ForEach(HomeKitCategory.allCases.sorted(by: { $0.description < $1.description })) { category in
                if Bool(searchText.isEmpty ? true : category.description.lowercased().contains(searchText.lowercased())) {
                    Label(category.description, systemImage: category.symbol)
                        .tag(category)
                }
            }
            
        } label: {
            if let titleSymbol {
                Label(title, systemImage: titleSymbol)
            } else {
                Text(title)
            }
        }
    }
}

import SwiftUI
import AVFoundation

struct HomeKitQRScannerView: UIViewControllerRepresentable {
    var onScanned: (_ setupID: String?, _ pairingCode: String?, _ category: HomeKitCategory?) -> Void
    var dismiss: () -> Void
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let parent: HomeKitQRScannerView
        
        init(_ parent: HomeKitQRScannerView) {
            self.parent = parent
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput,
                            didOutput metadataObjects: [AVMetadataObject],
                            from connection: AVCaptureConnection) {
            guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  metadataObject.type == .qr,
                  let stringValue = metadataObject.stringValue,
                  stringValue.starts(with: "X-HM://") else {
                return
            }
            
            let payloadString = stringValue.replacingOccurrences(of: "X-HM://", with: "")
            let setupID = payloadString.count >= 4 ? String(payloadString.suffix(4)) : nil
            let encodedPayload = String(payloadString.dropLast(4))
            
            var pairingCode: String? = nil
            var category: HomeKitCategory? = nil
            
            if let payloadInt = UInt64(encodedPayload, radix: 36) {
                let pin = UInt32((payloadInt >> 13) & 0xFFFFFFFF)
                let categoryRaw = UInt8((payloadInt >> 4) & 0x7F)
                
                let pinString = String(format: "%08d", pin)
                pairingCode = "\(pinString.prefix(3))-\(pinString.dropFirst(3).prefix(2))-\(pinString.suffix(3))"
                
                category = HomeKitCategory(rawValue: categoryRaw)
            }
            
            parent.onScanned(setupID, pairingCode, category)
            parent.dismiss()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let controller = UIViewController()
        let session = AVCaptureSession()
        
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device),
              session.canAddInput(input) else {
            return controller
        }
        
        session.addInput(input)
        
        let output = AVCaptureMetadataOutput()
        if session.canAddOutput(output) {
            session.addOutput(output)
            output.setMetadataObjectsDelegate(context.coordinator, queue: .main)
            output.metadataObjectTypes = [.qr]
        }
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.frame = controller.view.bounds
        controller.view.layer.addSublayer(previewLayer)
        session.startRunning()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
