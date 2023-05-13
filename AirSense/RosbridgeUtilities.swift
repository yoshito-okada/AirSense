//
//  RosbridgeUtilities.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/04/11.
//

import CoreMotion
import Foundation
import simd

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
    let seq: Int = 0
    let stamp: RosTime
    let frame_id: String
    
    init(stamp: RosTime = RosTime(), frame_id: String = "") {
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
    
    init(_ other: simd_quatf) {
        self.x = Double(other.imag.x)
        self.y = Double(other.imag.y)
        self.z = Double(other.imag.z)
        self.w = Double(other.real)
    }
    
    init(matrix: simd_float3x3) {
        self.init(simd_quatf(matrix))
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
    
    init(_ other: simd_float3) {
        self.x = Double(other.x)
        self.y = Double(other.y)
        self.z = Double(other.z)
    }
}

// sensor_msgs/Imu
struct RosImu: Encodable {
    let header: RosHeader
    let orientation: RosQuaternion
    let orientation_covariance: [Double]
    let angular_velocity: RosVector3
    let angular_velocity_covariance: [Double]
    let linear_acceleration: RosVector3
    let linear_acceleration_covariance: [Double]
    
    init(header: RosHeader = RosHeader(),
         orientation: RosQuaternion = RosQuaternion(),
         orientation_covariance: [Double]? = .none,
         angular_velocity: RosVector3 = RosVector3(),
         angular_velocity_covariance: [Double]? = .none,
         linear_acceleration: RosVector3 = RosVector3(),
         linear_acceleration_covariance: [Double]? = .none) {
        self.header = header
        self.orientation = orientation
        self.orientation_covariance = orientation_covariance ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        self.angular_velocity = angular_velocity
        self.angular_velocity_covariance = angular_velocity_covariance ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
        self.linear_acceleration = linear_acceleration
        self.linear_acceleration_covariance = linear_acceleration_covariance ?? [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
    }
    
    init(motion: CMDeviceMotion, frameId: String) {
        self.init(header: RosHeader(stamp: RosTime(timeInterval: motion.timestamp),
                                    frame_id: frameId),
                  orientation: RosQuaternion(quaternion: motion.attitude.quaternion),
                  orientation_covariance: .none,
                  angular_velocity: RosVector3(rotationRate: motion.rotationRate),
                  angular_velocity_covariance: .none,
                  linear_acceleration: RosVector3(x: motion.gravity.x + motion.userAcceleration.x,
                                                  y: motion.gravity.y + motion.userAcceleration.y,
                                                  z: motion.gravity.z + motion.userAcceleration.z),
                  linear_acceleration_covariance: .none)
    }
}

// geometry_msgs/Transform
struct RosTransform: Encodable {
    let translation: RosVector3
    let rotation: RosQuaternion
    
    init(translation: RosVector3 = RosVector3(), rotation: RosQuaternion = RosQuaternion()) {
        self.translation = translation
        self.rotation = rotation
    }
    
    init(_ matrix: simd_float4x4) {
        self.translation = RosVector3(simd_make_float3(matrix.columns.3))
        self.rotation = RosQuaternion(
            matrix: simd_float3x3(columns: (simd_make_float3(matrix.columns.0),
                                            simd_make_float3(matrix.columns.1),
                                            simd_make_float3(matrix.columns.2))))
    }
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
