//
//  DeviceMotionTracker.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/12.
//

import Foundation
import CoreMotion

class DeviceMotionTracker {
    
    // MARK: - Enums, typealiases
    
    // fatal errors which may be thrown from initializer
    enum FatalError: LocalizedError {
        case motionNotSupported
        
        var errorDescription: String? {
            switch self {
            case .motionNotSupported:
                return "Self motion tracking is not supported on this device"
            }
        }
    }
    
    typealias MotionHandler = (CMDeviceMotion) -> Void
    typealias ErrorHandler = (Error) -> Void
    
    // MARK: - Properties

    var motionHandler: MotionHandler?
    var errorHandler: ErrorHandler?
    
    // MARK: - Private properties
    
    private let motionManager = CMMotionManager()
    
    // MARK: - Initializers
    
    init() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw FatalError.motionNotSupported
        }
        
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
