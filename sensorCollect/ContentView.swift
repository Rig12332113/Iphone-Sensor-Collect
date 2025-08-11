import SwiftUI
import CoreMotion

class MotionManager: ObservableObject {
    private var motion = CMMotionManager()
    private var queue = OperationQueue()

    @Published var acc: CMAcceleration = CMAcceleration(x: 0, y: 0, z: 0)
    @Published var gyro: CMRotationRate = CMRotationRate(x: 0, y: 0, z: 0)

    init() {
        startUpdates()
    }

    func startUpdates() {
        if motion.isAccelerometerAvailable {
            motion.accelerometerUpdateInterval = 0.02
            motion.startAccelerometerUpdates(to: queue) { data, _ in
                guard let data = data else { return }
                DispatchQueue.main.async {
                    self.acc = data.acceleration
                }
            }
        }

        if motion.isGyroAvailable {
            motion.gyroUpdateInterval = 0.02
            motion.startGyroUpdates(to: queue) { data, _ in
                guard let data = data else { return }
                DispatchQueue.main.async {
                    self.gyro = data.rotationRate
                }
            }
        }
    }

    func stopUpdates() {
        motion.stopAccelerometerUpdates()
        motion.stopGyroUpdates()
    }
}

struct ContentView: View {
    @EnvironmentObject var camera: CameraManager

    var body: some View {
        TabView {
            CameraView(cameraManager: camera) // pass shared instance
                .tabItem { Label("Camera", systemImage: "camera") }

            IMUView()
                .tabItem { Label("IMU", systemImage: "gyroscope") }

            LiDARTabView()
                .tabItem { Label("LiDAR", systemImage: "cube") }

            ConnectionView()
                .tabItem { Label("Connect", systemImage: "antenna.radiowaves.left.and.right") }
        }
    }
}
