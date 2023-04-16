//
//  MotionToRosbridgeStreamer.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/16.
//

import Combine
import CoreMotion
import Foundation

class MotionToRosbridgeStreamer: ObservableObject {
    
    // MARK: - Private properties
    
    private var cancellables: [AnyCancellable] = []
    
    // MARK: - Properties
    
    let headphoneMotionTracker: HeadphoneMotionTracker = HeadphoneMotionTracker()
    let deviceMotionTracker: DeviceMotionTracker = DeviceMotionTracker()
    let webSocketTaskController: WebSocketTaskController = WebSocketTaskController()
    
    var deviceMotionTopic: String = "" {
        didSet {
            sendTopicAdvertiseRequest(topic: deviceMotionTopic)
        }
    }
    var deviceMotionFrameId: String = ""
    var headphoneMotionTopic: String = "" {
        didSet {
            sendTopicAdvertiseRequest(topic: headphoneMotionTopic)
        }
    }
    var headphoneMotionFrameId: String = ""
    
    // MARK: - Initializers
    
    init() {
        // on WebSocket connected to rosbridge server, send topic advertise requests
        webSocketTaskController.$state.sink { [weak weakSelf = self] state in
            guard let self = weakSelf else { return }
            switch state {
            case .hasTask(taskState: .connected(_)):
                self.sendTopicAdvertiseRequest(topic: self.deviceMotionTopic)
                self.sendTopicAdvertiseRequest(topic: self.headphoneMotionTopic)
            default:
                break
            }
        }.store(in: &cancellables)
        // on device motion updated, send a motion publish request
        deviceMotionTracker.$motion.sink { [weak weakSelf = self] maybeMotion in
            guard let self = weakSelf, let motion = maybeMotion else { return }
            self.sendMotionPublishRequest(topic: self.deviceMotionTopic,
                                          frameId: self.deviceMotionFrameId,
                                          motion: motion)
        }.store(in: &cancellables)
        // on headphone motion updated, send a motion publish request
        headphoneMotionTracker.$motion.sink { [weak weakSelf = self] maybeMotion in
            guard let self = weakSelf, let motion = maybeMotion else { return }
            self.sendMotionPublishRequest(topic: self.headphoneMotionTopic,
                                          frameId: self.headphoneMotionFrameId,
                                          motion: motion)
        }.store(in: &cancellables)
    }
    
    // MARK: - Private methods
    
    private func sendTopicAdvertiseRequest(topic: String) {
        let advertiseRequest = RosbridgeAdvertiseRequest(topic: topic, type: "sensor_msgs/Imu")
        if let encodedRequest = encodeForWebSocket(object: advertiseRequest) {
            webSocketTaskController.send(encodedRequest)
        }
    }
    
    private func sendMotionPublishRequest(topic: String, frameId: String, motion: CMDeviceMotion) {
        let publishRequest = RosbridgePublishRequest<RosImu>(
            topic: topic,
            msg: RosImu(
                header: RosHeader(
                    stamp: RosTime(timeInterval: motion.timestamp),
                    frame_id: frameId),
                orientation: RosQuaternion(quaternion: motion.attitude.quaternion),
                angular_velocity: RosVector3(rotationRate: motion.rotationRate),
                linear_acceleration: RosVector3(acceleration: motion.userAcceleration)))
        if let encodedRequest = encodeForWebSocket(object: publishRequest) {
            webSocketTaskController.send(encodedRequest)
        }
    }
}
