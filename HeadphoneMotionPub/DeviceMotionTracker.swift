//
//  DeviceMotionTracker.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/12.
//

import Foundation
import CoreMotion

class DeviceMotionTracker {
    
    // MARK: - Typealiases
    
    typealias MotionHandler = (CMDeviceMotion) -> Void
    typealias ErrorHandler = (Error) -> Void
    
    // MARK: - Properties

    var motionHandler: MotionHandler?
    var errorHandler: ErrorHandler?
    
    // MARK: - Private properties
    
    private let motionManager = CMMotionManager()
    
    // MARK: - Initializers
    
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
