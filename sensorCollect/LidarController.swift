//
//  LidarController.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/10/25.
//

import RealityKit
import ARKit

final class LiDARController: ObservableObject {
    weak var arView: ARView?

    func runFreshSession() {
        guard let arView else { return }
        // Safety: pause before run to avoid “already-enabled session”
        arView.session.pause()

        let config = ARWorldTrackingConfiguration()
        config.sceneReconstruction = .mesh
        config.frameSemantics = .sceneDepth
        config.environmentTexturing = .automatic
        config.planeDetection = [.horizontal, .vertical]

        arView.debugOptions.insert(.showSceneUnderstanding)
        arView.environment.sceneUnderstanding.options = [.occlusion, .receivesLighting]

        arView.session.run(config, options: [.resetTracking, .removeExistingAnchors])
    }

    func pause() { arView?.session.pause() }
}
