//
//  MotionToRosbridgeStreamerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/16.
//

import Foundation
import SwiftUI

struct MotionToRosbridgeStreamerView: View {
    @AppStorage("deviceMotionTopic") private var deviceMotionTopic = "/device_imu"
    @AppStorage("deviceMotionFrameId") private var deviceMotionFrameId = "device_imu"
    @AppStorage("headphoneMotionTopic") private var headphoneMotionTopic = "/headphone_imu"
    @AppStorage("headphoneMotionFrameId") private var headphoneMotionFrameId = "headphone_imu"
    
    @ObservedObject var model: MotionToRosbridgeStreamer
    
    var body: some View {
        VStack(alignment: .leading) {
            DeviceMotionTrackerView(model: model.deviceMotionTracker)
                .padding(.bottom)
            
            HeadphoneMotionTrackerView(model: model.headphoneMotionTracker)
                .padding(.bottom)
            
            WebSocketTaskControllerView(model: model.webSocketTaskController)
                .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text("ROS Settings")
                    .bold()
                //
                Text("Device Motion")
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    HTextTextField(text: ("Topic", .gray),
                                   textField: ($deviceMotionTopic, { model.deviceMotionTopic = deviceMotionTopic }))
                    HTextTextField(text: ("Frame ID", .gray),
                                   textField: ($deviceMotionFrameId, { model.deviceMotionFrameId = deviceMotionFrameId }))
                }
                .padding(.leading)
                //
                Text("Headphone Motion")
                    .foregroundColor(.gray)
                VStack(alignment: .leading) {
                    HTextTextField(text: ("Topic", .gray),
                                   textField: ($headphoneMotionTopic, { model.headphoneMotionTopic = headphoneMotionTopic }))
                    HTextTextField(text: ("Frame ID", .gray),
                                   textField: ($headphoneMotionFrameId, { model.headphoneMotionFrameId = headphoneMotionFrameId }))
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
        }
    }
}
