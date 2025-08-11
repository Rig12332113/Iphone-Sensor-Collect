//
//  CameraManager.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//


import AVFoundation
import UIKit

final class CameraManager: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    // Public
    let session = AVCaptureSession()
    var targetFPS: Double = 12            // adjustable at runtime
    var jpegQuality: CGFloat = 0.5        // 0.2–0.9 typical
    var onJPEG: ((Data) -> Void)?         // set this to stream frames elsewhere

    // Internals
    private let videoOutput = AVCaptureVideoDataOutput()
    private let context = CIContext()
    private var lastSentTime: CFTimeInterval = 0
    private var savedOnJPEG: ((Data) -> Void)?

    override init() {
        super.init()
        configure()
    }

    private func configure() {
        session.beginConfiguration()

        // Keep it light; raise to .hd1280x720 if you need more detail
        if session.canSetSessionPreset(.vga640x480) {
            session.sessionPreset = .vga640x480
        }

        guard
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: device),
            session.canAddInput(input)
        else {
            print("❌ Camera input failed")
            session.commitConfiguration()
            return
        }
        session.addInput(input)

        // Video frames out
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ]
        let q = DispatchQueue(label: "camera.frame.queue")
        videoOutput.setSampleBufferDelegate(self, queue: q)
        if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }

        // Orientation
        if let conn = videoOutput.connection(with: .video), conn.isVideoOrientationSupported {
            conn.videoOrientation = .portrait
        }

        session.commitConfiguration()
    }

    // MARK: - Explicit control
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if !self.session.isRunning { self.session.startRunning() }
        }
    }

    func stopSession() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self else { return }
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    // Call when switching to LiDAR
    func suspendForARKit() {
        savedOnJPEG = onJPEG
        onJPEG = nil
        stopSession()
    }

    // Call when leaving LiDAR
    func resumeAfterARKit() {
        startSession()
        onJPEG = savedOnJPEG
        savedOnJPEG = nil
    }

    // MARK: - Delegate (capture frames -> JPEG -> callback)
    func captureOutput(_ output: AVCaptureOutput,
                       didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection)
    {
        guard let onJPEG = onJPEG,
              let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        // simple FPS throttle
        let now = CACurrentMediaTime()
        let minDT = 1.0 / max(targetFPS, 1)
        if now - lastSentTime < minDT { return }
        lastSentTime = now

        let ci = CIImage(cvImageBuffer: pb)
        guard let cg = context.createCGImage(ci, from: ci.extent) else { return }
        let ui = UIImage(cgImage: cg)
        guard let jpg = ui.jpegData(compressionQuality: jpegQuality) else { return }

        onJPEG(jpg)
    }
}
