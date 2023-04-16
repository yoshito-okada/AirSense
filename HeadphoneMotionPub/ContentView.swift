//
//  ContentView.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/03/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model: MotionToRosbridgeStreamer = MotionToRosbridgeStreamer()
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                MotionToRosbridgeStreamerView(model: model)
            }
            
            Spacer()
            
            PreferenceView()
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
