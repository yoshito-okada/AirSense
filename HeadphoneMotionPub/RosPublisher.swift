//
//  RosPublisher.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/03/30.
//

import Foundation
import Network
import CoreMotion

class RosPublisher: NSObject, URLSessionWebSocketDelegate {
    private var webSocketTask: URLSessionWebSocketTask?
    private var sequenceNumber: Int = 0
    
    var onSessionEstablished: (() -> Void)?
    var onMotionPublished: ((CMDeviceMotion) -> Void)?
    var onMotionPublishFailed: ((Error) -> Void)?
    var onSessionDisconnected: ((URLSessionWebSocketTask.CloseCode) -> Void)?

    func restartSession(url: URL) {
        webSocketTask?.cancel()
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: .main)
        webSocketTask = session.webSocketTask(with: url)
        sequenceNumber = 0
        webSocketTask?.resume()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        onSessionEstablished?()
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        onSessionDisconnected?(closeCode)
    }

    func publishMotion(topicName: String, stamp: Date, frameId: String, motion: CMDeviceMotion) {
        let timeInterval = stamp.timeIntervalSince1970
        let timeSec = Int(timeInterval)
        let timeNsec = Int((timeInterval - Double(timeSec)) * 1_000_000_000)
        
        let headerMessage: [String: Any] = [
            "seq": sequenceNumber,
            "stamp": [
                "sec": timeSec,
                "nsec": timeNsec
            ],
            "frame_id": frameId
        ]

        let imuMessage: [String: Any] = [
            "header": headerMessage,
            "orientation": [
                "x": motion.attitude.quaternion.x,
                "y": motion.attitude.quaternion.y,
                "z": motion.attitude.quaternion.z,
                "w": motion.attitude.quaternion.w
            ],
            "orientation_covariance": [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            "angular_velocity": [
                "x": motion.rotationRate.x,
                "y": motion.rotationRate.y,
                "z": motion.rotationRate.z
            ],
            "angular_velocity_covariance": [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
            "linear_acceleration": [
                "x": motion.userAcceleration.x,
                "y": motion.userAcceleration.y,
                "z": motion.userAcceleration.z
            ],
            "linear_acceleration_covariance": [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        ]

        let rosMessage: [String: Any] = [
            "op": "publish",
            "topic": topicName,
            "msg": imuMessage
        ]

        guard let json = try? JSONSerialization.data(withJSONObject: rosMessage, options: []) else {
            return
        }

        webSocketTask?.send(.data(json)) { maybeError in
            if let error = maybeError {
                self.onMotionPublishFailed?(error)
            } else {
                self.onMotionPublished?(motion)
            }
        }

        sequenceNumber += 1
    }
}

