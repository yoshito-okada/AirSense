//
//  FaceTracker.swift
//  MotionRosStreamer
//
//  Created by Yoshito Okada on 2023/04/30.
//

import ARKit
import Foundation

// a wrapper of CMMotionManager
//   - automatically start motion tracking on init, and stop on deinit
//   - publish state and tracked motion
class FaceTracker: NSObject, ARSessionDelegate, ObservableObject {
    
    // MARK: - State definitions
    
    enum FatalError: LocalizedError {
        case notSupported
        
        var errorDescription: String? {
            switch self {
            case .notSupported:
                return "Face tracking is not supported on this device"
            }
        }
    }
    
    enum State {
        case normal
        case fatalError(error: Error)
    }
    
    // MARK: - Properties

    @Published private(set) var state: State = .normal
    @Published private(set) var transform: simd_float4x4?

    // MARK: - Private properties
    
    private let session = ARSession()
    
    // MARK: - Initializers
    
    override init() {
        super.init()
        switch ARFaceTrackingConfiguration.isSupported {
        case true:
            state = .normal
            // attach self as a delegate before start tracking face
            session.delegateQueue = .main
            session.delegate = self
            // select a video format with the highest resolution & lowest fps
            // for the best tracking precision and computational load
            let videoFormat = ARFaceTrackingConfiguration.supportedVideoFormats
                .max{ (formatA, formatB) -> Bool in
                    let resolutionA = formatA.imageResolution.width * formatA.imageResolution.height
                    let resolutionB = formatB.imageResolution.width * formatB.imageResolution.height
                    return (resolutionA != resolutionB
                            ? resolutionA < resolutionB
                            : formatA.framesPerSecond > formatB.framesPerSecond)
                }!
            // make tracking configuration
            let configuration = ARFaceTrackingConfiguration()
            configuration.worldAlignment = .camera
            configuration.videoFormat = videoFormat
            // start face tracking
            session.run(configuration)
        case false:
            state = .fatalError(error: FatalError.notSupported)
        }
    }
    
    deinit {
        session.pause()
    }
    
    // MARK: - ARSessionDelegate
    
    func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
        guard let faceAnchor = anchors.first(where: { $0 is ARFaceAnchor }) as? ARFaceAnchor else { return }
        //
        //   |     |              the face object frame
        //   |   --+--> .........   - represented by faceAnchor.transform
        //   |     |                - the y axis is toward the top of head
        //   |     v                - the z axis is toward the front of face
        //   |
        // --+-----------> xy ... the reference frame
        //   |                      - screen is on the xy plane
        //   |     ^                - the z axis is toward the real user
        //   |     |
        //   |   <-+-- .......... user's actual face
        //   |     |
        //   v z
        //
        // faceAnchor.transform refers the face object in the AR world behind the device screen.
        // if worldAlignment is .camera, the reference frame is the device.
        // following operation yields the transformation to user's actual face
        // which locates the mirrored position accross the device screen.
        var mirrored = faceAnchor.transform
        mirrored[0, 0] = -mirrored[0, 0] // x component of x axis of the actual face frame
                                         // with respect to the reference frame is flipped
        mirrored[0, 1] = -mirrored[0, 1] // y of x axis
        mirrored[1, 2] = -mirrored[1, 2] // z of y axis
        mirrored[2, 2] = -mirrored[2, 2] // z of z axis
        mirrored[3, 2] = -mirrored[3, 2] // z of translation
        // update the transformation
        transform = mirrored
    }
}
