//
//  HeadphoneMotionTracker.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/03/30.
//

import CoreMotion

// a wrapper of CMHeadphoneMotionManager
//   - automatically start motion tracking on init, and stop on deinit
//   - publish connection state and tracked motion
class HeadphoneMotionTracker: NSObject, CMHeadphoneMotionManagerDelegate, ObservableObject {
    
    // MARK: - State definitions
    
    enum FatalError: LocalizedError {
        case motionNotSupported
        case permissionDenied
        case permissionNotDetermined
        case permissionRestricted
        case permissionUnknown
        
        var errorDescription: String? {
            switch self {
            case .motionNotSupported:
                return "Headphone motion tracking is not supported on this device"
            case .permissionDenied:
                return "Permission to track headphone motion has been denied"
            case .permissionNotDetermined:
                return "Permission to track headphone motion is not determined"
            case .permissionRestricted:
                return "Permission to track headphone motion is restricted"
            case .permissionUnknown:
                return "Permission to track headphone motion is unknown"
            }
        }
    }
    
    enum NormalState {
        case disconnected
        case connected
    }
    
    enum State {
        case normal(state: NormalState)
        case fatalError(error: Error)
    }

    // MARK: - Properties
    
    @Published private(set) var state: State = .normal(state: .disconnected)
    @Published private(set) var motion: CMDeviceMotion? = nil
    
    // MARK: - Private properties

    private let motionManager: CMHeadphoneMotionManager = CMHeadphoneMotionManager()
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        
        switch (motionManager.isDeviceMotionAvailable, CMHeadphoneMotionManager.authorizationStatus()) {
        case (false, _):
            state = .fatalError(error: FatalError.motionNotSupported)
        case (_, .denied):
            state = .fatalError(error: FatalError.permissionDenied)
        case (_, .notDetermined):
            state = .fatalError(error: FatalError.permissionRestricted)
        case (_, .restricted):
            state = .fatalError(error: FatalError.permissionRestricted)
        case (true, .authorized):
            state = .normal(state: .disconnected)
            // start motion tracking only if no fatal error detected
            motionManager.delegate = self
            motionManager.startDeviceMotionUpdates(to: .main) {
                [weak weakSelf = self] (maybeMotion, maybeError) in
                weakSelf?.motion = maybeMotion
            }
        @unknown default:
            state = .fatalError(error: FatalError.permissionUnknown)
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: - CMHeadphoneMotionManagerDelegate
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        state = .normal(state: .connected)
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        state = .normal(state: .disconnected)
        motion = nil
    }
}

