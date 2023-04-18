//
//  DeviceMotionTrackerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/15.
//

import Foundation
import SwiftUI

struct DeviceMotionTrackerView: View {
    @AppStorage("deviceMotionUpdateInterval") private var updateInterval: TimeInterval = 0.05
    
    @ObservedObject var model: DeviceMotionTracker
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Device Motion")
                .bold()
            switch (model.state, model.motion) {
            case (.normal, .none):
                EmptyView()
            case (.normal, .some(let motion)):
                MotionView(motion: motion, color: .gray)
            case (.fatalError(let error), _):
                HImageText(image: ("exclamationmark.triangle.fill", .red), text: (error.localizedDescription, .gray))
            }
            HTextDoubleField(
                text: ("Update Interval", .gray),
                textField: ($updateInterval, { model.updateInterval = updateInterval }))
        }
        .onAppear() {
            model.updateInterval = updateInterval
        }
    }
}
