//
//  RosbridgeUtilities.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/04/11.
//

import CoreMotion
import Foundation
import simd

// MARK: - Objects corresponding to ROS1 messages

// Time
struct Ros1Time: Encodable {
    let sec: Int
    let usec: Int
    
    init(sec: Int = 0, usec: Int = 0) {
        self.sec = sec
        self.usec = usec
    }
    
    init(timeInterval: TimeInterval) {
        self.sec = Int(timeInterval)
        self.usec = Int(timeInterval - Double(self.sec)) * 1_000_000
    }
}

// std_msgs/Header
struct Ros1Header: Encodable {
    let seq: Int = 0
    let stamp: Ros1Time
    let frame_id: String
    
    init(stamp: Ros1Time = Ros1Time(), frame_id: String = "") {
        self.stamp = stamp
        self.frame_id = frame_id
    }
}

// geometry_msgs/Quaternion
struct Ros1Quaternion: Encodable {
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
struct Ros1Vector3: Encodable {
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
struct Ros1Imu: Encodable {
    let header: Ros1Header
    let orientation: Ros1Quaternion
    let orientation_covariance: [Double]
    let angular_velocity: Ros1Vector3
    let angular_velocity_covariance: [Double]
    let linear_acceleration: Ros1Vector3
    let linear_acceleration_covariance: [Double]
    
    init(header: Ros1Header = Ros1Header(),
         orientation: Ros1Quaternion = Ros1Quaternion(),
         orientation_covariance: [Double]? = .none,
         angular_velocity: Ros1Vector3 = Ros1Vector3(),
         angular_velocity_covariance: [Double]? = .none,
         linear_acceleration: Ros1Vector3 = Ros1Vector3(),
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
        self.init(header: Ros1Header(stamp: Ros1Time(timeInterval: motion.timestamp),
                                    frame_id: frameId),
                  orientation: Ros1Quaternion(quaternion: motion.attitude.quaternion),
                  orientation_covariance: .none,
                  angular_velocity: Ros1Vector3(rotationRate: motion.rotationRate),
                  angular_velocity_covariance: .none,
                  linear_acceleration: Ros1Vector3(x: motion.gravity.x + motion.userAcceleration.x,
                                                  y: motion.gravity.y + motion.userAcceleration.y,
                                                  z: motion.gravity.z + motion.userAcceleration.z),
                  linear_acceleration_covariance: .none)
    }
}

// geometry_msgs/Transform
struct Ros1Transform: Encodable {
    let translation: Ros1Vector3
    let rotation: Ros1Quaternion
    
    init(translation: Ros1Vector3 = Ros1Vector3(), rotation: Ros1Quaternion = Ros1Quaternion()) {
        self.translation = translation
        self.rotation = rotation
    }
    
    init(_ matrix: simd_float4x4) {
        self.translation = Ros1Vector3(simd_make_float3(matrix.columns.3))
        self.rotation = Ros1Quaternion(
            matrix: simd_float3x3(columns: (simd_make_float3(matrix.columns.0),
                                            simd_make_float3(matrix.columns.1),
                                            simd_make_float3(matrix.columns.2))))
    }
}

// MARK: - Objects corresponding to ROS2 messages

// Time
struct Ros2Time: Encodable {
    let sec: Int
    let nanosec: Int
    
    init(sec: Int = 0, nanosec: Int = 0) {
        self.sec = sec
        self.nanosec = nanosec
    }
    
    init(timeInterval: TimeInterval) {
        self.sec = Int(timeInterval)
        self.nanosec = Int(timeInterval - Double(self.sec)) * 1_000_000_000
    }
}

// std_msgs/Header
struct Ros2Header: Encodable {
    let stamp: Ros2Time
    let frame_id: String
    
    init(stamp: Ros2Time = Ros2Time(), frame_id: String = "") {
        self.stamp = stamp
        self.frame_id = frame_id
    }
}

// geometry_msgs/Quaternion
typealias Ros2Quaternion = Ros1Quaternion

// geometry_msgs/Vector3
typealias Ros2Vector3 = Ros1Vector3

// sensor_msgs/Imu
struct Ros2Imu: Encodable {
    let header: Ros2Header
    let orientation: Ros2Quaternion
    let orientation_covariance: [Double]
    let angular_velocity: Ros2Vector3
    let angular_velocity_covariance: [Double]
    let linear_acceleration: Ros2Vector3
    let linear_acceleration_covariance: [Double]
    
    init(header: Ros2Header = Ros2Header(),
         orientation: Ros2Quaternion = Ros2Quaternion(),
         orientation_covariance: [Double]? = .none,
         angular_velocity: Ros2Vector3 = Ros2Vector3(),
         angular_velocity_covariance: [Double]? = .none,
         linear_acceleration: Ros2Vector3 = Ros2Vector3(),
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
        self.init(header: Ros2Header(stamp: Ros2Time(timeInterval: motion.timestamp),
                                     frame_id: frameId),
                  orientation: Ros2Quaternion(quaternion: motion.attitude.quaternion),
                  orientation_covariance: .none,
                  angular_velocity: Ros2Vector3(rotationRate: motion.rotationRate),
                  angular_velocity_covariance: .none,
                  linear_acceleration: Ros2Vector3(x: motion.gravity.x + motion.userAcceleration.x,
                                                   y: motion.gravity.y + motion.userAcceleration.y,
                                                   z: motion.gravity.z + motion.userAcceleration.z),
                  linear_acceleration_covariance: .none)
    }
}

// geometry_msgs/Transform
typealias Ros2Transform = Ros1Transform

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
