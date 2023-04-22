//
//  HeadphoneMotionTrackerView.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/15.
//

import Foundation
import SwiftUI

struct HeadphoneMotionTrackerView: View {
    @ObservedObject var model: HeadphoneMotionTracker
    let excludeGravity: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Headphone Motion")
                .bold()
                .foregroundColor(.primary)
            switch (model.state, model.motion) {
            case (.normal(.disconnected), _):
                HImageText(image: ("airpodspro", .red), text: ("Disconnected", .secondary))
            case (.normal(.connected), .none):
                HImageText(image: ("airpodspro", .green), text: ("Connected", .secondary))
            case (.normal(.connected), .some(let motion)):
                MotionView(motion: motion, excludeGravity: excludeGravity, color: .secondary)
            case (.fatalError(let error), _):
                HImageText(image: ("exclamationmark.triangle.fill", .red), text: (error.localizedDescription, .secondary))
            }
        }
    }
}
