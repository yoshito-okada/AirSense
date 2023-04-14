//
//  HeadphoneMotionTracker.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/03/30.
//

import CoreMotion

// a wrapper of CMHeadphoneMotionManager
//   - automatically start motion tracking on init, and stop on deinit
//   - can change handlers whenever the user wants
class HeadphoneMotionTracker {
    
    // MARK: - Enums, typealiases, classes
    
    // fatal errors which may be thrown from initializer
    enum FatalError: LocalizedError {
        case motionNotSupported
        case permissionDenied
        case permissionNotDetermined
        case permissionRestricted
        
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
            }
        }
    }
    
    // general lifecycle of a headphone
    enum State: CustomStringConvertible{
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
    typealias StateHandler = (/* newState: */State, /* reason: */String) -> Void
    typealias MotionHandler = (CMDeviceMotion) -> Void
    typealias ErrorHandler = (Error) -> Void

    // a delegate that notifies headphone states
    class Delegate: NSObject, CMHeadphoneMotionManagerDelegate {
        private(set) var state: State = .disconnected
        var stateHandler: StateHandler? {
            didSet {
                stateHandler?(state, "StateHandler changed")
            }
        }
        
        // MARK: - CMHeadphoneMotionManagerDelegate
        
        func headphoneMotionManagerDidConnect(_ manager: CMHeadphoneMotionManager) {
            updateState(newState: .connected, reason: "Headphone connected")
        }
        
        func headphoneMotionManagerDidDisconnect(_ manager: CMHeadphoneMotionManager) {
            updateState(newState: .disconnected, reason: "Headphone disconnected")
        }
        
        //
        
        private func updateState(newState: State, reason: String) {
            print("[Headphone] \(state) -> \(newState): \(reason)")
            state = newState
            stateHandler?(newState, reason)
        }
    }

    // MARK: - Properties
    
    var stateHandler: StateHandler? {
        get {
            return delegate.stateHandler
        }
        set {
            delegate.stateHandler = newValue
        }
    }
    var motionHandler: MotionHandler?
    var errorHandler: ErrorHandler?
    var state: State {
        return delegate.state
    }
    
    // MARK: - Private properties

    private let delegate: Delegate = Delegate()
    private let motionManager: CMHeadphoneMotionManager = CMHeadphoneMotionManager()
    
    // MARK: - Initializers
    
    init() throws {
        guard motionManager.isDeviceMotionAvailable else {
            throw FatalError.motionNotSupported
        }
        switch CMHeadphoneMotionManager.authorizationStatus() {
        case .denied:
            throw FatalError.permissionDenied
        case .notDetermined:
            throw FatalError.permissionNotDetermined
        case .restricted:
            throw FatalError.permissionRestricted
        default:
            break
        }
        
        motionManager.delegate = delegate
        
        motionManager.startDeviceMotionUpdates(to: .main){
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

