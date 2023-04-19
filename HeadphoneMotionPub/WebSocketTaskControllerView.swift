//
//  WebSocketTaskControllerView.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/15.
//

import Foundation
import SwiftUI

struct WebSocketTaskControllerView: View {
    @AppStorage("webSocketUrl") private var url: URL = URL(string: "ws://192.168.0.1:9090")!
    
    @ObservedObject var model: WebSocketTaskController
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("WebSocket Status")
                .bold()
            switch model.state {
            case .hasTask(taskState: .connecting(let url)):
                HImageText(image: ("globe", .yellow), text: ("Connecting to \(url)", .secondary))
            case .hasTask(taskState: .connected(let url)):
                HImageText(image: ("globe", .green), text: ("Connected to \(url)", .secondary))
            case .noTask, .hasTask(taskState: .initialized),
                    .hasTask(taskState: .disconnected), .hasTask(taskState: .finished):
                HImageText(image: ("globe", .red), text: ("Disconnected", .secondary))
            }
            HTextUrlField(text: ("URL ", .secondary),
                          textField: ($url, .primary, Color(UIColor.systemGray6), { updateTask(with: url) }))
        }
        .onAppear() {
            // initialize the WebSocket task
            updateTask(with: url)
        }
    }
    
    private func updateTask(with url: URL) {
        guard let url = WebSocketURL(value: url) else { return }
        model.updateTask(with: url)
    }
}
