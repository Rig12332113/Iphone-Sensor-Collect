//
//  ConnectionView.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//

//import SwiftUI
//import Combine
//
//struct ConnectionView: View {
//    @EnvironmentObject var sender: DataSender
//    @EnvironmentObject var motion: MotionManager
//
//    @State private var ip = UserDefaults.standard.string(forKey: "lastIP") ?? ""
//    @State private var message = "Hello from iPhone"
//
//    @State private var streaming = false
//    @State private var rateHz: Double = 50
//    @State private var timer = Timer.publish(every: 1.0/50.0, on: .main, in: .common).autoconnect()
//
//    var body: some View {
//        VStack(spacing: 14) {
//
//            // Connect row
//            HStack {
//                TextField("Server IP (e.g. 192.168.1.112)", text: $ip)
//                    .textInputAutocapitalization(.never)
//                    .autocorrectionDisabled()
//                    .keyboardType(.numbersAndPunctuation)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//
//                Button("Connect") {
//                    let cleaned = ip.trimmingCharacters(in: .whitespacesAndNewlines)
//                    guard !cleaned.isEmpty else { return }
//                    UserDefaults.standard.set(cleaned, forKey: "lastIP")
//                    sender.connect(to: cleaned)
//                }
//                .buttonStyle(.borderedProminent)
//            }
//
//            // Status
//            HStack {
//                Circle().fill(sender.isReady ? .green : .orange).frame(width: 10, height: 10)
//                Text(sender.status).font(.footnote).foregroundColor(.secondary)
//            }
//            
//            // Optional: arbitrary text send (kept from before)
//            HStack {
//                TextField("Message", text: $message)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                Button("Send") { sender.send(message) }
//                    .disabled(!sender.isReady)
//                    .buttonStyle(.borderedProminent)
//            }
//
//            Button("Disconnect") { sender.disconnect() }
//                .disabled(!sender.isReady)
//                .buttonStyle(.borderedProminent)
//
//            // New: Streaming controls moved here
//            Toggle("Stream IMU to PC", isOn: $streaming)
//                .disabled(!sender.isReady)
//
//            HStack {
//                Text("Rate: \(Int(rateHz)) Hz")
//                Slider(value: $rateHz, in: 5...120, step: 5)
//            }
//
//            // Manual send (one sample)
//            Button("Send one sample") {
//                sendOneSample()
//            }
//            .buttonStyle(.borderedProminent)
//            .disabled(!sender.isReady)
//
//            Spacer()
//        }
//        .padding()
//        .onChange(of: rateHz) { new in
//            timer.upstream.connect().cancel()
//            timer = Timer.publish(every: 1.0 / max(new, 1), on: .main, in: .common).autoconnect()
//        }
//        .onReceive(timer) { _ in
//            guard streaming, sender.isReady else { return }
//            sendOneSample()
//        }
//    }
//
//    private func sendOneSample() {
//        let t = Date().timeIntervalSince1970
//        let json = String(
//            format: #"{"t":%.6f,"acc":[%.4f,%.4f,%.4f],"gyro":[%.4f,%.4f,%.4f]}"#,
//            t,
//            motion.acc.x, motion.acc.y, motion.acc.z,
//            motion.gyro.x, motion.gyro.y, motion.gyro.z
//        )
//        sender.send(json + "\n")
//    }
//}

import SwiftUI
import Combine

struct ConnectionView: View {
    @EnvironmentObject var sender: DataSender
    @EnvironmentObject var motion: MotionManager
    @EnvironmentObject var camera: CameraManager

    @State private var ip = UserDefaults.standard.string(forKey: "lastIP") ?? ""
    @State private var message = "Hello from iPhone"

    // IMU controls you already moved here…
    @State private var streamingIMU = false
    @State private var rateHz: Double = 50
    @State private var timer = Timer.publish(every: 1.0/50.0, on: .main, in: .common).autoconnect()

    // NEW: camera streaming
    @State private var streamingCamera = false
    private let frameSender = FrameSender()

    var body: some View {
        VStack(spacing: 14) {
            // Connect row (same as before)
            HStack {
                TextField("Server IP (e.g. 192.168.1.112)", text: $ip)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.numbersAndPunctuation)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button("Connect") {
                    let cleaned = ip.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !cleaned.isEmpty else { return }
                    UserDefaults.standard.set(cleaned, forKey: "lastIP")
                    sender.connect(to: cleaned)             // IMU/text port 8888
                }
                .buttonStyle(.borderedProminent)
            }

            // Status
            HStack {
                Circle().fill(sender.isReady ? .green : .orange).frame(width: 10, height: 10)
                Text(sender.status).font(.footnote).foregroundColor(.secondary)
            }

            // ---- IMU controls (already working) ----
            Toggle("Stream IMU to PC", isOn: $streamingIMU)
                .disabled(!sender.isReady)
            HStack {
                Text("Rate: \(Int(rateHz)) Hz")
                Slider(value: $rateHz, in: 5...60, step: 5)
            }
            Button("Send one IMU sample") { sendOneIMUSample() }
                .buttonStyle(.borderedProminent)
                .disabled(!sender.isReady)

            Divider().padding(.vertical, 8)

            // ---- NEW: Camera streaming controls ----
            Toggle("Stream Camera to PC", isOn: $streamingCamera)
                .onChange(of: streamingCamera) { on in
                    if on {
                        let cleaned = ip.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !cleaned.isEmpty else { streamingCamera = false; return }
                        frameSender.connect(to: cleaned, port: 9999)     // video port
                        // Hook camera frames to sender
                        camera.onJPEG = { jpg in
                            frameSender.sendJPEG(jpg)
                        }
                    } else {
                        camera.onJPEG = nil
                        frameSender.disconnect()
                    }
                }

            HStack {
                Text("Cam FPS: \(Int(camera.targetFPS))")
                Slider(value: Binding(
                    get: { camera.targetFPS },
                    set: { camera.targetFPS = $0 }
                ), in: 5...30, step: 1)
            }

            HStack {
                Text("JPEG: \(Int(camera.jpegQuality * 100))%")
                Slider(value: Binding(
                    get: { Double(camera.jpegQuality) },
                    set: { camera.jpegQuality = CGFloat($0) }
                ), in: 0.2...0.9, step: 0.05)
            }

            Spacer()
        }
        .padding()
        // IMU timer
        .onChange(of: rateHz) { new in
            timer.upstream.connect().cancel()
            timer = Timer.publish(every: 1.0 / max(new, 1), on: .main, in: .common).autoconnect()
        }
        .onReceive(timer) { _ in
            guard streamingIMU, sender.isReady else { return }
            sendOneIMUSample()
        }
    }

    private func sendOneIMUSample() {
        let t = Date().timeIntervalSince1970
        let json = String(
            format: #"{"t":%.6f,"acc":[%.6f,%.6f,%.6f],"gyro":[%.6f,%.6f,%.6f]}"#,
            t,
            motion.acc.x, motion.acc.y, motion.acc.z,
            motion.gyro.x, motion.gyro.y, motion.gyro.z
        )
        sender.send(json + "\n")
    }
}
