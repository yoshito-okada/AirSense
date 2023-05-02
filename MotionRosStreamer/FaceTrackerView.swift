//
//  FaceTrackerView.swift
//  MotionRosStreamer
//
//  Created by Yoshito Okada on 2023/05/01.
//

import Foundation
import SwiftUI

struct FaceTrackerView: View {
    @ObservedObject var model: FaceTracker
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Face Pose")
                .bold()
                .foregroundColor(.primary)
            switch (model.state, model.transform) {
            case (.normal, .none):
                EmptyView()
            case (.normal, .some(let pose)):
                PoseView(pose: pose, color: .secondary)
            case (.fatalError(let error), _):
                HImageText(image: ("exclamationmark.triangle.fill", .red), text: (error.localizedDescription, .secondary))
            }
        }
    }
}
