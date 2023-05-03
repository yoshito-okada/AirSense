//
//  PhoneTrackerView.swift
//  MotionRosStreamer
//
//  Created by Yoshito Okada on 2023/04/15.
//

import Foundation
import SwiftUI

struct PhoneTrackerView: View {
    @AppStorage("phoneMotionUpdateInterval") private var updateInterval: TimeInterval = 0.05
    
    @ObservedObject var model: PhoneTracker
    let excludeGravity: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Phone Motion")
                .bold()
                .foregroundColor(.primary)
            switch (model.state, model.motion) {
            case (.normal, .none):
                EmptyView()
            case (.normal, .some(let motion)):
                MotionView(motion: motion, excludeGravity: excludeGravity, color: .secondary)
            case (.fatalError(let error), _):
                HImageText(image: ("exclamationmark.triangle.fill", .red), text: (error.localizedDescription, .secondary))
            }
            HTextDoubleField(
                text: ("Update Interval ", .secondary),
                textField: ($updateInterval, .primary, Color(UIColor.systemGray6), { model.updateInterval = updateInterval }))
        }
        .onAppear() {
            model.updateInterval = updateInterval
        }
    }
}
