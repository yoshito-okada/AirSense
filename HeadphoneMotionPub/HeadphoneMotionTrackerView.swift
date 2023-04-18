//
//  HeadphoneMotionTrackerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/15.
//

import Foundation
import SwiftUI

struct HeadphoneMotionTrackerView: View {
    @ObservedObject var model: HeadphoneMotionTracker
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Headphone Motion")
                .bold()
            switch (model.state, model.motion) {
            case (.normal(.disconnected), _):
                HImageText(image: ("headphones", .red), text: ("Disconnected", .gray))
            case (.normal(.connected), .none):
                HImageText(image: ("headphones", .green), text: ("Connected", .gray))
            case (.normal(.connected), .some(let motion)):
                MotionView(motion: motion, color: .gray)
            case (.fatalError(let error), _):
                HImageText(image: ("exclamationmark.triangle.fill", .red), text: (error.localizedDescription, .gray))
            }
        }
    }
}
