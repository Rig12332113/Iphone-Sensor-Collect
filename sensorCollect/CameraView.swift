//
//  CameraView.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//

import SwiftUI
import AVFoundation

struct CameraView: View {
    @ObservedObject var cameraManager: CameraManager

    var body: some View {
        GeometryReader { geometry in
            CameraPreviewView(session: cameraManager.session)
                .frame(width: geometry.size.width, height: geometry.size.height)
                .onAppear {
                    cameraManager.startSession()
                }
//                .onDisappear {
//                    cameraManager.stopSession()
//                }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct CameraPreviewView: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {
        // Resize handled automatically
    }
}
