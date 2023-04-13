//
//  ContentView.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/03/30.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    //
    @State private var deviceSupportIconName: String = "questionmark.circle.fill"
    @State private var deviceSupportIconColor: Color = .gray
    @State private var deviceSupportText: String = "Unknown"
    //
    @State private var appPermissionIconName: String = "questionmark.circle.fill"
    @State private var appPermissionIconColor: Color = .gray
    @State private var appPermissionText: String = "Unknown"
    //
    @State private var headphoneStatusIconName: String = "headphones"
    @State private var headphoneStatusIconColor: Color = .red
    @State private var headphoneStatusText: String = "Disconnected"
    //
    @State private var eulerAnglesText: String = "N/A"
    @State private var angularVelocitiesText: String = "N/A"
    @State private var linearAccelerationsText: String = "N/A"
    //
    @State private var webSocketStatusIconName: String = "globe"
    @State private var webSocketStatusIconColor: Color = .red
    @State private var webSocketStatusText: String = "Disconnected"
    @AppStorage("webSocketUrlText") private var webSocketUrlText: String = "ws://192.168.0.1:9090"
    @AppStorage("rosTopicName") private var rosTopicName: String = "/imu"
    @AppStorage("rosFrameId") private var rosFrameId: String = "imu"
    //
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = false
    
    //
    private let headphoneMotionTracker: HeadphoneMotionTracker = HeadphoneMotionTracker()
    private let webSocketController: WebSocketTaskController = WebSocketTaskController()
    
    var body: some View {
        VStack(alignment: .leading) {
            
            // iOS device's support for headphone motion tracking
            Group {
                Text("Device Tracking Support")
                    .bold()
                HStack {
                    Image(systemName: deviceSupportIconName)
                        .foregroundColor(deviceSupportIconColor)
                    Text(deviceSupportText)
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            
            // app permission for headphone motion tracking
            Group {
                Text("App Tracking Permission")
                    .bold()
                HStack {
                    Image(systemName: appPermissionIconName)
                        .foregroundColor(appPermissionIconColor)
                    Text(appPermissionText)
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            
            // headphone status
            Group {
                Text("Headphone Status")
                    .bold()
                HStack {
                    Image(systemName: headphoneStatusIconName)
                        .foregroundColor(headphoneStatusIconColor)
                    Text(headphoneStatusText)
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            
            // headphone motion tracked
            Group {
                Text("Headphone Motion")
                    .bold()
                VStack(alignment: .leading) {
                    Text("Euler Angles: \(eulerAnglesText)")
                        .foregroundColor(.gray)
                    Text("Angular Velocities: \(angularVelocitiesText)")
                        .foregroundColor(.gray)
                    Text("Linear Accelerations: \(linearAccelerationsText)")
                        .foregroundColor(.gray)
                }
                .padding(.bottom)
            }
            
            // ROS publication status
            Group {
                Text("ROS Publication Status").bold()
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: webSocketStatusIconName)
                            .foregroundColor(webSocketStatusIconColor)
                        Text(webSocketStatusText)
                            .foregroundColor(.gray)
                    }
                    HStack {
                        Text("rosbridge URL:")
                            .foregroundColor(.gray)
                        TextField("rosbridge URL", text: $webSocketUrlText)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                updateWebSocketUrl(with: webSocketUrlText)
                            }
                    }
                    HStack {
                        Text("Topic Name:")
                            .foregroundColor(.gray)
                        TextField("Topic Name", text: $rosTopicName)
                            .textFieldStyle(.roundedBorder)
                            .onSubmit {
                                advertiseRosTopic(topicName: rosTopicName)
                            }
                    }
                    HStack {
                        Text("Frame ID:")
                            .foregroundColor(.gray)
                        TextField("Frame ID", text: $rosFrameId)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.bottom)
            }
            
            Spacer()
            
            Group {
                Toggle("Keep Screen On", isOn: $keepScreenOn)
                    .foregroundColor(.gray)
                    .tint(.gray)
                    .onChange(of: keepScreenOn) { _ in
                        UIApplication.shared.isIdleTimerDisabled = keepScreenOn
                    }
            }
        }
        .padding()
        .onAppear {
            if headphoneMotionTracker.isMotionAvailable {
                deviceSupportIconName = "checkmark.circle.fill"
                deviceSupportIconColor = .green
                deviceSupportText = "Supported"
            } else {
                deviceSupportIconName = "xmark.circle.fill"
                deviceSupportIconColor = .red
                deviceSupportText = "Not Supported"
            }
            
            switch headphoneMotionTracker.authorizationStatus {
            case .authorized:
                appPermissionIconName = "checkmark.circle.fill"
                appPermissionIconColor = .green
                appPermissionText = "Sufficient"
            case .denied:
                appPermissionIconName = "xmark.circle.fill"
                appPermissionIconColor = .red
                appPermissionText = "Insufficient (Denied)"
            case .notDetermined:
                appPermissionIconName = "xmark.circle.fill"
                appPermissionIconColor = .red
                appPermissionText = "Insufficient (Not Determined)"
            case .restricted:
                appPermissionIconName = "xmark.circle.fill"
                appPermissionIconColor = .red
                appPermissionText = "Insufficient (Restricted)"
            default:
                appPermissionIconName = "questionmark.circle.fill"
                appPermissionIconColor = .gray
                appPermissionText = "Unknown"
            }
            
            headphoneMotionTracker.stateHandler = { (newState, reason) in
                switch newState {
                case .connected:
                    headphoneStatusIconColor = .green
                    headphoneStatusText = "Connected"
                case .disconnected:
                    headphoneStatusIconColor = .red
                    headphoneStatusText = "Disconnected"
                }
            }
            
            headphoneMotionTracker.motionHandler = { (motion) in
                eulerAnglesText = String(format: "(%+.2f, %+.2f, %+.2f)",
                                         motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw)
                angularVelocitiesText = String(format: "(%+.2f, %+.2f, %+.2f)",
                                               motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z)
                linearAccelerationsText = String(format: "(%+.2f, %+.2f, %+.2f)",
                                                 motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z)
                publishRosMessage(topicName: rosTopicName, frameId: rosFrameId, motion: motion)
            }
            
            webSocketController.stateHandler = { (url, newState, reason) in
                switch newState {
                case .idle:
                    webSocketStatusIconColor = .gray
                    webSocketStatusText = "Idle"
                case .connected:
                    webSocketStatusIconColor = .green
                    webSocketStatusText = "Connected to \(url)"
                    advertiseRosTopic(topicName: rosTopicName)
                case .disconnected:
                    webSocketStatusIconColor = .red
                    webSocketStatusText = "Disconnected from \(url)"
                case .connectionAttempting:
                    webSocketStatusIconColor = .yellow
                    webSocketStatusText = "Connecting to \(url)"
                }
            }
            
            // start a WebSocket connection to the initial URL
            updateWebSocketUrl(with: webSocketUrlText)
        }
    }
    
    private func updateWebSocketUrl(with string: String) {
        if let url = WebSocketURL(string: string) {
            webSocketController.url = url
        }
    }
    
    private func advertiseRosTopic(topicName: String) {
        // TODO: unadvertise the old topic before advertising the new topic
        let advertiseRequest = RosBridgeAdvertiseRequest(topic: topicName, type: "sensor_msgs/Imu")
        if let encodedRequest = encodeForWebSocket(object: advertiseRequest) {
            webSocketController.send(encodedRequest)
        }
    }
    
    private func publishRosMessage(topicName: String, frameId: String, motion: CMDeviceMotion) {
        let publishRequest = RosBridgePublishRequest<RosImu>(
            topic: topicName,
            msg: RosImu(
                header: RosHeader(
                    stamp: RosTime(timeInterval: motion.timestamp),
                    frame_id: frameId),
                orientation: RosQuaternion(quaternion: motion.attitude.quaternion),
                angular_velocity: RosVector3(rotationRate: motion.rotationRate),
                linear_acceleration: RosVector3(acceleration: motion.userAcceleration)))
        if let encodedRequest = encodeForWebSocket(object: publishRequest) {
            webSocketController.send(encodedRequest)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
