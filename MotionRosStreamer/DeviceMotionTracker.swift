//
//  DeviceMotionTracker.swift
//  MotionRosStreamer
//
//  Created by Yoshito Okada on 2023/04/12.
//

import CoreMotion
import Foundation

// a wrapper of CMMotionManager
//   - automatically start motion tracking on init, and stop on deinit
//   - publish state and tracked motion
class DeviceMotionTracker: ObservableObject {
    
    // MARK: - State definitions
    
    enum FatalError: LocalizedError {
        case motionNotSupported
        
        var errorDescription: String? {
            switch self {
            case .motionNotSupported:
                return "Self motion tracking is not supported on this device"
            }
        }
    }
    
    enum State {
        case normal
        case fatalError(error: Error)
    }
    
    // MARK: - Properties

    @Published private(set) var state: State = .normal
    @Published private(set) var motion: CMDeviceMotion?
    var updateInterval: TimeInterval {
        get {
            return motionManager.deviceMotionUpdateInterval
        }
        set {
            motionManager.deviceMotionUpdateInterval = newValue
        }
    }
    
    // MARK: - Private properties
    
    private let motionManager = CMMotionManager()
    
    // MARK: - Initializers
    
    init() {
        switch motionManager.isDeviceMotionAvailable {
        case true:
            state = .normal
            // start motion tracking only if no fatal error detected
            motionManager.startDeviceMotionUpdates(using: .xArbitraryCorrectedZVertical, to: .main) {
                [weak weakSelf = self] (maybeMotion, maybeError) in
                weakSelf?.motion = maybeMotion
                // TODO: handle error
            }
        case false:
            state = .fatalError(error: FatalError.motionNotSupported)
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}
