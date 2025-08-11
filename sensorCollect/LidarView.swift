//
//  LidarView.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//

import SwiftUI
import RealityKit
import ARKit

struct LiDARView: UIViewRepresentable {
    @ObservedObject var controller: LiDARController

    func makeUIView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        controller.arView = view
        return view
    }

    func updateUIView(_ uiView: ARView, context: Context) {}

    static func dismantleUIView(_ uiView: ARView, coordinator: ()) {
        uiView.session.pause()
    }
}

struct LiDARTabView: View {
    @EnvironmentObject var camera: CameraManager
    @StateObject private var lidar = LiDARController()

    var body: some View {
        LiDARView(controller: lidar)
            .onAppear {
                // 1) Release AVCapture’s camera FIRST
                camera.suspendForARKit()
                // 2) Then start AR exactly once per appearance
                lidar.runFreshSession()
            }
            .onDisappear {
                // 3) Stop AR
                lidar.pause()
                // 4) Give camera back to AVCapture (tiny delay helps AR fully release)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    camera.resumeAfterARKit()
                }
            }
    }
}
