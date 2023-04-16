//
//  MotionToRosbridgeStreamerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/16.
//

import Foundation
import SwiftUI

struct MotionToRosbridgeStreamerView: View {
    @ObservedObject var model: MotionToRosbridgeStreamer
    
    // TODO: textfields to change topic names and frame ids
    @AppStorage("deviceMotionTopic") var deviceMotionTopic = "/device_imu"
    @AppStorage("deviceMotionFrameId") var deviceMotionFrameId = "device_imu"
    @AppStorage("headphoneMotionTopic") var headphoneMotionTopic = "/headphone_imu"
    @AppStorage("headphoneMotionFrameId") var headphoneMotionFrameId = "headphone_imu"
    
    var body: some View {
        VStack(alignment: .leading) {
            DeviceMotionTrackerView(model: model.deviceMotionTracker)
                .padding(.bottom)
            
            HeadphoneMotionTrackerView(model: model.headphoneMotionTracker)
                .padding(.bottom)
            
            WebSocketTaskControllerView(model: model.webSocketTaskController)
                .padding(.bottom)
            
            Text("ROS Settings")
                .bold()
            //
            Text("Device Motion")
                .foregroundColor(.gray)
            HStack {
                Text("Topic")
                    .foregroundColor(.gray)
                TextField("Device Motion Topic", text: $deviceMotionTopic)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.leading)
            HStack {
                Text("Frame ID")
                    .foregroundColor(.gray)
                TextField("Device Motion Frame ID", text: $deviceMotionFrameId)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.leading)
            //
            Text("Headphone Motion")
                .foregroundColor(.gray)
            HStack {
                Text("Topic")
                    .foregroundColor(.gray)
                TextField("Headphone Motion Topic", text: $headphoneMotionTopic)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.leading)
            HStack {
                Text("Frame ID")
                    .foregroundColor(.gray)
                TextField("Headphone Motion Frame ID", text: $headphoneMotionFrameId)
                    .textFieldStyle(.roundedBorder)
            }
            .padding(.leading)
        }
    }
}
