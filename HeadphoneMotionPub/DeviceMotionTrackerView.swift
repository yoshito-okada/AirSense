//
//  DeviceMotionTrackerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/15.
//

import Foundation
import SwiftUI

struct DeviceMotionTrackerView: View {
    @ObservedObject var model: DeviceMotionTracker
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Device Motion")
                .bold()
            if case .fatalError(let error) = model.state {
                HImageTextView(image: ("exclamationmark.triangle.fill", .red),
                               text: (error.localizedDescription, .gray))
            }
            if let motion = model.motion {
                MotionView(motion: motion, color: .gray)
            }
        }
    }
}
