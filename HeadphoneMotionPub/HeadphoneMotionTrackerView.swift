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
            
            VStack(alignment: .leading) {
                Text("Headphone Status")
                    .bold()
                switch model.state {
                case .normal(.connected):
                    HImageText(image: ("headphones", .green), text: ("Connected", .gray))
                case .normal(.disconnected):
                    HImageText(image: ("headphones", .red), text: ("Disonnected", .gray))
                case .fatalError(let error):
                    HImageText(image: ("exclamationmark.triangle.fill", .red), text: (error.localizedDescription, .gray))
                }
            }
            .padding(.bottom)
            
            VStack(alignment: .leading) {
                Text("Headphone Motion")
                    .bold()
                if let motion = model.motion {
                    MotionView(motion: motion, color: .gray)
                }
            }
            
        }
    }
}
