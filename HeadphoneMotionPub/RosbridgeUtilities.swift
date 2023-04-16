//
//  RosbridgeUtilities.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/11.
//

import Foundation
import CoreMotion

// MARK: - Objects corresponding to ROS messages

// Time
struct RosTime: Encodable {
    let sec: Int
    let usec: Int
    
    init(sec: Int = 0, usec: Int = 0) {
        self.sec = sec
        self.usec = usec
    }
    
    init(timeInterval: TimeInterval) {
        self.sec = Int(timeInterval)
        self.usec = Int(timeInterval - Double(self.sec)) * 1_000_000_000
    }
}

// std_msgs/Header
struct RosHeader: Encodable {
    let seq: Int
    let stamp: RosTime
    let frame_id: String
    
    init(seq: Int = 0, stamp: RosTime = RosTime(), frame_id: String = "") {
        self.seq = 0
        self.stamp = stamp
        self.frame_id = frame_id
    }
}

// geometry_msgs/Quaternion
struct RosQuaternion: Encodable {
    let x: Double
    let y: Double
    let z: Double
    let w: Double
    
    init(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0, w: Double = 1.0) {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
    }
    
    init(quaternion: CMQuaternion) {
        self.x = quaternion.x
        self.y = quaternion.y
        self.z = quaternion.z
        self.w = quaternion.w
    }
}

// geometry_msgs/Vector3
struct RosVector3: Encodable {
    let x: Double
    let y: Double
    let z: Double
    
    init(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    init(rotationRate: CMRotationRate) {
        self.x = rotationRate.x
        self.y = rotationRate.y
        self.z = rotationRate.z
    }
    
    init(acceleration: CMAcceleration) {
        self.x = acceleration.x
        self.y = acceleration.y
        self.z = acceleration.z
    }
}

// sensor_msgs/Imu
struct RosImu: Encodable {
    let header: RosHeader
    let orientation: RosQuaternion
    let orientation_covariance: [Double] = [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    let angular_velocity: RosVector3
    let angular_velocity_covariance: [Double] = [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    let linear_acceleration: RosVector3
    let linear_acceleration_covariance: [Double] = [-1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
}

// MARK: - Objects corresponding to rosbridge requests

struct RosbridgeAdvertiseRequest: Encodable {
    let op: String = "advertise"
    let topic: String
    let type: String
}

struct RosbridgeUnadvertiseRequest: Encodable {
    let op: String = "unadvertise"
    let topic: String
}

struct RosbridgePublishRequest<Msg: Encodable>: Encodable {
    let op: String = "publish"
    let topic: String
    let msg: Msg
}

// MARK: - Encoding utility

func encodeForWebSocket(object: Encodable) -> URLSessionWebSocketTask.Message? {
    let encoder = JSONEncoder()
    // the .withoutEscapingSlashes option must be specified.
    // or "xxx_msgs/yyy" in the object becomes "xxx_msgs\/yyy" in the output data.
    encoder.outputFormatting = [.withoutEscapingSlashes]
    do {
        return .data(try encoder.encode(object))
    } catch {
        print("Encode failed (\(error))")
        return nil
    }
}
