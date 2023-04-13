//
//  HeadphoneTracker.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/03/30.
//

import CoreMotion

// general lifecycle of a headphone
enum HeadphoneTrackerState: CustomStringConvertible{
    case disconnected
    case connected
    
    var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connected:
            return "Connected"
        }
    }
}

// type of callback for handling state, tracked motion, and tracking error
typealias HeadphoneTrackerStateHandler = (/* newState: */HeadphoneTrackerState, /* reason: */String) -> Void
typealias HeadphoneTrackerMotionHandler = (CMDeviceMotion) -> Void
typealias HeadphoneTrackerErrorHandler = (Error) -> Void

// a delegate that notifies headphone states
class HeadphoneTrackerDelegate: NSObject, CMHeadphoneMotionManagerDelegate {
    private(set) var state: HeadphoneTrackerState = .disconnected
    var stateHandler: HeadphoneTrackerStateHandler? {
        didSet {
            stateHandler?(state, "StateHandler changed")
        }
    }
    
    // -MARK: CMHeadphoneMotionManagerDelegate
    
    func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
        updateState(newState: .connected, reason: "Headphone connected")
    }
    
    func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
        updateState(newState: .disconnected, reason: "Headphone disconnected")
    }
    
    //
    
    private func updateState(newState: HeadphoneTrackerState, reason: String) {
        print("[Headphone] \(state) -> \(newState): \(reason)")
        state = newState
        stateHandler?(newState, reason)
    }
}

// a wrapper of CMHeadphoneMotionManager
//   - automatically start motion tracking on init, and stop on deinit
//   - can change handlers whenever the user wants
class HeadphoneTracker {
    var stateHandler: HeadphoneTrackerStateHandler? {
        get {
            return delegate.stateHandler
        }
        set {
            delegate.stateHandler = newValue
        }
    }
    var motionHandler: HeadphoneTrackerMotionHandler?
    var errorHandler: HeadphoneTrackerErrorHandler?
    var isMotionAvailable: Bool {
        return motionManager.isDeviceMotionAvailable
    }
    var authorizationStatus: CMAuthorizationStatus {
        return CMHeadphoneMotionManager.authorizationStatus()
    }
    var state: HeadphoneTrackerState {
        return delegate.state
    }
    
    private let delegate: HeadphoneTrackerDelegate = HeadphoneTrackerDelegate()
    private let motionManager: CMHeadphoneMotionManager = CMHeadphoneMotionManager()
    
    init() {
        motionManager.delegate = delegate
        
        motionManager.startDeviceMotionUpdates(to: .main){ [weak self] (maybeMotion, maybeError) in
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

