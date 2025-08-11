//
//  IMUview.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//

//import SwiftUI
//import Combine
//
//struct IMUView: View {
//    @EnvironmentObject var sender: DataSender
//    @StateObject private var motion = MotionManager()
//
//    @State private var streaming = false
//    @State private var rateHz: Double = 50
//
//    // timer we can retune when rate changes
//    @State private var timer = Timer.publish(
//        every: 1.0 / 50.0, on: .main, in: .common
//    ).autoconnect()
//
//    var body: some View {
//        VStack(spacing: 14) {
//            // connection status
//            HStack {
//                Circle().fill(sender.isReady ? .green : .orange)
//                    .frame(width: 10, height: 10)
//                Text(sender.status).font(.footnote).foregroundColor(.secondary)
//            }
//
//            // live readout
//            Group {
//                Text("Accelerometer").font(.headline)
//                Text(String(format: "x: %.3f  y: %.3f  z: %.3f",
//                            motion.acc.x, motion.acc.y, motion.acc.z))
//
//                Divider().padding(.vertical, 4)
//
//                Text("Gyroscope").font(.headline)
//                Text(String(format: "x: %.3f  y: %.3f  z: %.3f",
//                            motion.gyro.x, motion.gyro.y, motion.gyro.z))
//            }
//
//            Toggle("Stream to PC", isOn: $streaming)
//                .disabled(!sender.isReady)
//
//            HStack {
//                Text("Rate: \(Int(rateHz)) Hz")
//                Slider(value: $rateHz, in: 5...120, step: 5)
//            }
//
//            Button("Send one sample") { sendOneSample() }
//                .buttonStyle(.borderedProminent)
//                .disabled(!sender.isReady)
//
//            Spacer()
//        }
//        // ⬇️ attach modifiers to the VStack, not free-floating
//        .onChange(of: rateHz) { new in
//            timer.upstream.connect().cancel()
//            timer = Timer.publish(
//                every: 1.0 / max(new, 1), on: .main, in: .common
//            ).autoconnect()
//        }
//        .onReceive(timer) { _ in
//            guard streaming, sender.isReady else { return }
//            sendOneSample()
//        }
//        .padding()
//    }
//
//    private func sendOneSample() {
//        let t = Date().timeIntervalSince1970
//        let json = String(
//            format: #"{"t":%.6f,"acc":[%.6f,%.6f,%.6f],"gyro":[%.6f,%.6f,%.6f]}"#,
//            t,
//            motion.acc.x, motion.acc.y, motion.acc.z,
//            motion.gyro.x, motion.gyro.y, motion.gyro.z
//        )
//        sender.send(json + "\n") // newline = easy line-delimited parsing
//    }
//}

import SwiftUI

struct IMUView: View {
    @EnvironmentObject var motion: MotionManager
    @EnvironmentObject var sender: DataSender

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Circle().fill(sender.isReady ? .green : .orange).frame(width: 10, height: 10)
                Text(sender.status).font(.footnote).foregroundColor(.secondary)
            }

            Text("Accelerometer").font(.headline)
            Text(String(format: "x: %.3f  y: %.3f  z: %.3f",
                        motion.acc.x, motion.acc.y, motion.acc.z))

            Divider().padding(.vertical, 4)

            Text("Gyroscope").font(.headline)
            Text(String(format: "x: %.3f  y: %.3f  z: %.3f",
                        motion.gyro.x, motion.gyro.y, motion.gyro.z))

            Spacer()
        }
        .padding()
    }
}

