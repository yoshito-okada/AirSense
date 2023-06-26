//
//  HeadphoneTracker.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/03/30.
//

import CoreMotion

// a wrapper of CMHeadphoneMotionManager
//   - automatically start headphone motion tracking on init, and stop on deinit
//   - publish connection state and tracked motion
class HeadphoneTracker: NSObject, CMHeadphoneMotionManagerDelegate, ObservableObject {
    
    // MARK: - State definitions
    
    enum FatalError: LocalizedError {
        case notSupported
        case permissionDenied
        case permissionNotDetermined
        case permissionRestricted
        case permissionUnknown
        
        var errorDescription: String? {
            switch self {
            case .notSupported:
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
            state = .fatalError(error: FatalError.notSupported)
        case (true, .denied):
            state = .fatalError(error: FatalError.permissionDenied)
        case (true, .notDetermined):
            state = .fatalError(error: FatalError.permissionNotDetermined)
            startTracking()
        case (true, .restricted):
            state = .fatalError(error: FatalError.permissionRestricted)
        case (true, .authorized):
            state = .normal(state: .disconnected)
            startTracking()
        @unknown default:
            state = .fatalError(error: FatalError.permissionUnknown)
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
    
    // MARK: - Private methods
    
    private func startTracking() {
        motionManager.delegate = self
        motionManager.startDeviceMotionUpdates(to: .main) {
            [weak weakSelf = self] (maybeMotion, maybeError) in
            weakSelf?.motion = maybeMotion
        }
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

