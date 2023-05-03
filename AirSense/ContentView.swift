//
//  ContentView.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/03/30.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var model: RosbridgeStreamer = RosbridgeStreamer()
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView {
                RosbridgeStreamerView(model: model)
                    .padding()
            }
            
            Spacer()
            
            PreferenceView()
                .padding()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
