//
//  DeviceMotionTracker.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/12.
//

import Foundation
import CoreMotion

typealias DeviceMotionTrackerMotionHandler = (CMDeviceMotion) -> Void
typealias DeviceMotionTrackerErrorHandler = (Error) -> Void

class DeviceMotionTracker {
    var motionHandler: DeviceMotionTrackerMotionHandler?
    var errorHandler: DeviceMotionTrackerErrorHandler?
    
    private let motionManager = CMMotionManager()
    
    init() {
        motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) {
            [weak self] (maybeMotion, maybeError) in
            if let motion = maybeMotion {
                self?.motionHandler?(motion)
            }
            if let error = maybeError {
                self?.errorHandler?(error)
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
