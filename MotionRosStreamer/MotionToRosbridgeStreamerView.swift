//
//  MotionToRosbridgeStreamerView.swift
//  MotionRosStreamer
//
//  Created by Yoshito Okada on 2023/04/16.
//

import Foundation
import SwiftUI

struct MotionToRosbridgeStreamerView: View {
    @AppStorage("deviceMotionTopic") private var deviceMotionTopic = "/device_imu"
    @AppStorage("deviceMotionFrameId") private var deviceMotionFrameId = "device_imu"
    @AppStorage("headphoneMotionTopic") private var headphoneMotionTopic = "/headphone_imu"
    @AppStorage("headphoneMotionFrameId") private var headphoneMotionFrameId = "headphone_imu"
    @AppStorage("excludeGravity") private var excludeGravity = false
    @AppStorage("faceTransformTopic") private var faceTransformTopic = "/face_transform"
    
    @ObservedObject var model: MotionToRosbridgeStreamer
    
    var body: some View {
        VStack(alignment: .leading) {
            DeviceMotionTrackerView(model: model.deviceMotionTracker, excludeGravity: excludeGravity)
                .padding(.bottom)
            
            HeadphoneMotionTrackerView(model: model.headphoneMotionTracker, excludeGravity: excludeGravity)
                .padding(.bottom)
            
            FaceTrackerView(model: model.faceTracker)
                .padding(.bottom)
            
            WebSocketTaskControllerView(model: model.webSocketTaskController)
                .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text("ROS Settings")
                    .bold()
                    .foregroundColor(.primary)
                //
                Text("Device Motion")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    HTextTextField(text: ("Topic ", .secondary),
                                   textField: ($deviceMotionTopic, .primary, Color(UIColor.systemGray6),
                                               { model.deviceMotionTopic = deviceMotionTopic }))
                    HTextTextField(text: ("Frame ID ", .secondary),
                                   textField: ($deviceMotionFrameId, .primary, Color(UIColor.systemGray6),
                                               { model.deviceMotionFrameId = deviceMotionFrameId }))
                }
                .padding(.leading)
                //
                Text("Headphone Motion")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    HTextTextField(text: ("Topic ", .secondary),
                                   textField: ($headphoneMotionTopic, .primary, Color(UIColor.systemGray6),
                                               { model.headphoneMotionTopic = headphoneMotionTopic }))
                    HTextTextField(text: ("Frame ID ", .secondary),
                                   textField: ($headphoneMotionFrameId, .primary, Color(UIColor.systemGray6),
                                               { model.headphoneMotionFrameId = headphoneMotionFrameId }))
                }
                .padding(.leading)
                //
                Toggle("Exclude Gravity", isOn: $excludeGravity)
                    .foregroundColor(.secondary)
                    .tint(.accentColor)
                    .onChange(of: excludeGravity) { _ in
                        model.excludeGravity = excludeGravity
                    }
                //
                Text("Face Transform")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    HTextTextField(text: ("Topic ", .secondary),
                                   textField: ($faceTransformTopic, .primary, Color(UIColor.systemGray6),
                                               { model.faceTransformTopic = faceTransformTopic }))
                }
                .padding(.leading)
            }
        }
        .onAppear() {
            // reflect the initial configs in the model
            model.deviceMotionTopic = deviceMotionTopic
            model.deviceMotionFrameId = deviceMotionFrameId
            model.headphoneMotionTopic = headphoneMotionTopic
            model.headphoneMotionFrameId = headphoneMotionFrameId
            model.excludeGravity = excludeGravity
            model.faceTransformTopic = faceTransformTopic
        }
    }
}
