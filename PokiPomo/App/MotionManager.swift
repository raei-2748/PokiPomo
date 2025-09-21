//
//  MotionManager.swift
//  PokiPomo
//
//  Created by Codex on 29/10/2025.
//

import CoreMotion
import Foundation

@MainActor
final class MotionManager: ObservableObject {
    @Published private(set) var horizontalTilt: Double = 0

    private let motionManager = CMMotionManager()
    private let updateQueue = OperationQueue()
    private var filteredValue: Double = 0
    private let filterStrength: Double = 0.12

    func start() {
        guard motionManager.isDeviceMotionAvailable else { return }

        motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
        updateQueue.name = "com.pokipomo.motion"

        motionManager.startDeviceMotionUpdates(to: updateQueue) { [weak self] motion, _ in
            guard let motion, let self else { return }
            let gravityX = max(min(motion.gravity.x, 1), -1)
            let newValue = gravityX
            let filtered = self.filteredValue * (1 - self.filterStrength) + newValue * self.filterStrength

            Task { @MainActor in
                self.filteredValue = filtered
                self.horizontalTilt = filtered
            }
        }
    }

    func stop() {
        motionManager.stopDeviceMotionUpdates()
    }
}
