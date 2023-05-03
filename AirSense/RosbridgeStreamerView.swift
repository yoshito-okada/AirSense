//
//  RosbridgeStreamerView.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/04/16.
//

import Foundation
import SwiftUI

struct RosbridgeStreamerView: View {
    @AppStorage("phoneMotionTopic") private var phoneMotionTopic = "/phone_imu"
    @AppStorage("phoneMotionFrameId") private var phoneMotionFrameId = "phone_imu"
    @AppStorage("headphoneMotionTopic") private var headphoneMotionTopic = "/headphone_imu"
    @AppStorage("headphoneMotionFrameId") private var headphoneMotionFrameId = "headphone_imu"
    @AppStorage("excludeGravity") private var excludeGravity = false
    @AppStorage("faceTransformTopic") private var faceTransformTopic = "/face_transform"
    
    @ObservedObject var model: RosbridgeStreamer
    
    var body: some View {
        VStack(alignment: .leading) {
            PhoneTrackerView(model: model.phoneTracker, excludeGravity: excludeGravity)
                .padding(.bottom)
            
            HeadphoneTrackerView(model: model.headphoneTracker, excludeGravity: excludeGravity)
                .padding(.bottom)
            
            FaceTrackerView(model: model.faceTracker)
                .padding(.bottom)
            
            WebSocketControllerView(model: model.webSocketController)
                .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text("ROS Settings")
                    .bold()
                    .foregroundColor(.primary)
                //
                Text("Phone Motion")
                    .foregroundColor(.secondary)
                VStack(alignment: .leading) {
                    HTextTextField(text: ("Topic ", .secondary),
                                   textField: ($phoneMotionTopic, .primary, Color(UIColor.systemGray6),
                                               { model.phoneMotionTopic = phoneMotionTopic }))
                    HTextTextField(text: ("Frame ID ", .secondary),
                                   textField: ($phoneMotionFrameId, .primary, Color(UIColor.systemGray6),
                                               { model.phoneMotionFrameId = phoneMotionFrameId }))
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
            model.phoneMotionTopic = phoneMotionTopic
            model.phoneMotionFrameId = phoneMotionFrameId
            model.headphoneMotionTopic = headphoneMotionTopic
            model.headphoneMotionFrameId = headphoneMotionFrameId
            model.excludeGravity = excludeGravity
            model.faceTransformTopic = faceTransformTopic
        }
    }
}
