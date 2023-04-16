//
//  ViewUtilities.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/15.
//

import CoreMotion
import Foundation
import SwiftUI

struct HImageTextView: View {
    let image: (systemName: String, color: Color)
    let text: (string: String, color: Color)
    
    var body: some View {
        HStack {
            Image(systemName: image.systemName)
                .foregroundColor(image.color)
            Text(text.string)
                .foregroundColor(text.color)
        }
    }
}

struct HTextTextFieldView: View {
    let text: (string: String, color: Color)
    let textField: (text: Binding<String>, onSubmit: () -> Void)
    
    var body: some View {
        HStack {
            Text(text.string)
                .foregroundColor(text.color)
            TextField(text.string, text: textField.text)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    textField.onSubmit()
                }
        }
    }
}

struct MotionView: View {
    let motion: CMDeviceMotion
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(String(format: "Eular Angles: (%+.2f, %+.2f, %+.2f)",
                        motion.attitude.roll, motion.attitude.pitch, motion.attitude.yaw))
            .foregroundColor(color)
            Text(String(format: "Angular Velocities: (%+.2f, %+.2f, %+.2f)",
                        motion.rotationRate.x, motion.rotationRate.y, motion.rotationRate.z))
            .foregroundColor(color)
            Text(String(format: "Linear Accelerations: (%+.2f, %+.2f, %+.2f)",
                        motion.userAcceleration.x, motion.userAcceleration.y, motion.userAcceleration.z))
            .foregroundColor(color)
        }
    }
}

struct PreferenceView: View {
    @AppStorage("keepScreenOn") private var keepScreenOn: Bool = false
    
    var body: some View {
        Toggle("Keep Screen On", isOn: $keepScreenOn)
            .foregroundColor(.gray)
            .onAppear() {
                // reflect the **initial** preference in the system
                UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            }
            .onChange(of: keepScreenOn) { _ in
                // reflect the **changed** preference in the system
                UIApplication.shared.isIdleTimerDisabled = keepScreenOn
            }
    }
}
