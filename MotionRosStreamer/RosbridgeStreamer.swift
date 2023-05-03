//
//  RosbridgeStreamer.swift
//  MotionRosStreamer
//
//  Created by Yoshito Okada on 2023/04/16.
//

import Combine
import CoreMotion
import Foundation
import simd

class RosbridgeStreamer: ObservableObject {
    
    // MARK: - Private properties
    
    private var cancellables: [AnyCancellable] = []
    
    // MARK: - Properties
    
    let phoneTracker: PhoneTracker = PhoneTracker()
    let headphoneTracker: HeadphoneTracker = HeadphoneTracker()
    let faceTracker: FaceTracker = FaceTracker()
    let webSocketController: WebSocketController = WebSocketController()
    
    var phoneMotionTopic: String = "" {
        didSet {
            sendTopicAdvertiseRequest(topic: phoneMotionTopic, type: "sensor_msgs/Imu")
        }
    }
    var phoneMotionFrameId: String = ""
    var headphoneMotionTopic: String = "" {
        didSet {
            sendTopicAdvertiseRequest(topic: headphoneMotionTopic, type: "sensor_msgs/Imu")
        }
    }
    var headphoneMotionFrameId: String = ""
    var excludeGravity = false
    var faceTransformTopic: String = "" {
        didSet {
            sendTopicAdvertiseRequest(topic: faceTransformTopic, type: "geometry_msgs/Transform")
        }
    }
    
    // MARK: - Initializers
    
    init() {
        // on WebSocket connected to rosbridge server, send topic advertise requests
        webSocketController.$state.sink { [weak weakSelf = self] state in
            guard let self = weakSelf, case .hasTask(taskState: .connected(_)) = state else { return }
            self.sendTopicAdvertiseRequest(topic: self.phoneMotionTopic, type: "sensor_msgs/Imu")
            self.sendTopicAdvertiseRequest(topic: self.headphoneMotionTopic, type: "sensor_msgs/Imu")
            self.sendTopicAdvertiseRequest(topic: self.faceTransformTopic, type: "geometry_msgs/Transform")
        }.store(in: &cancellables)
        // on device motion updated, send a motion publish request
        phoneTracker.$motion.sink { [weak weakSelf = self] maybeMotion in
            guard let self = weakSelf, let motion = maybeMotion else { return }
            self.sendMotionPublishRequest(topic: self.phoneMotionTopic,
                                          frameId: self.phoneMotionFrameId,
                                          motion: motion)
        }.store(in: &cancellables)
        // on headphone motion updated, send a motion publish request
        headphoneTracker.$motion.sink { [weak weakSelf = self] maybeMotion in
            guard let self = weakSelf, let motion = maybeMotion else { return }
            self.sendMotionPublishRequest(topic: self.headphoneMotionTopic,
                                          frameId: self.headphoneMotionFrameId,
                                          motion: motion)
        }.store(in: &cancellables)
        // on face transform updated, send a transform publish request
        faceTracker.$transform.sink { [weak weakSelf = self] maybeTransform in
            guard let self = weakSelf, let transform = maybeTransform else { return }
            self.sendTransformPublishRequest(topic: self.faceTransformTopic,
                                             transform: transform)
        }.store(in: &cancellables)
    }
    
    // MARK: - Private methods
    
    private func sendTopicAdvertiseRequest(topic: String, type: String) {
        let advertiseRequest = RosbridgeAdvertiseRequest(topic: topic, type: type)
        if let encodedRequest = encodeForWebSocket(object: advertiseRequest) {
            webSocketController.send(encodedRequest)
        }
    }
    
    private func sendMotionPublishRequest(topic: String, frameId: String, motion: CMDeviceMotion) {
        let acceleration = (excludeGravity
                            ? motion.userAcceleration
                            : CMAcceleration(x: motion.userAcceleration.x + motion.gravity.x,
                                             y: motion.userAcceleration.y + motion.gravity.y,
                                             z: motion.userAcceleration.z + motion.gravity.z))
        let publishRequest = RosbridgePublishRequest<RosImu>(
            topic: topic,
            msg: RosImu(
                header: RosHeader(
                    stamp: RosTime(timeInterval: motion.timestamp),
                    frame_id: frameId),
                orientation: RosQuaternion(quaternion: motion.attitude.quaternion),
                angular_velocity: RosVector3(rotationRate: motion.rotationRate),
                linear_acceleration: RosVector3(acceleration: acceleration)))
        if let encodedRequest = encodeForWebSocket(object: publishRequest) {
            webSocketController.send(encodedRequest)
        }
    }
    
    private func sendTransformPublishRequest(topic: String, transform: simd_float4x4) {
        let publishRequest = RosbridgePublishRequest<RosTransform>(
            topic: topic,
            msg: RosTransform(transform))
        if let encodedRequest = encodeForWebSocket(object: publishRequest) {
            webSocketController.send(encodedRequest)
        }
    }
}
