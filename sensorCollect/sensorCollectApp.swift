//
//  sensorCollectApp.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//

import SwiftUI

@main
struct sensorCollectApp: App {
    @StateObject private var sender = DataSender()       // shared TCP
    @StateObject private var motion = MotionManager()    // shared IMU
    @StateObject private var camera = CameraManager()    // shared Camera
    
    init() {
            // Customize tab bar appearance here
            UITabBar.appearance().barTintColor = .white
            UITabBar.appearance().backgroundColor = .white // for iOS 15+
            UITabBar.appearance().unselectedItemTintColor = .gray
            UITabBar.appearance().tintColor = .black // selected tab
        }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(sender)
                .environmentObject(motion)
                .environmentObject(camera)
        }
    }
}

