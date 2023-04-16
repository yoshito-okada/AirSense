//
//  WebSocketTaskControllerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/15.
//

import Foundation
import SwiftUI

struct WebSocketTaskControllerView: View {
    @AppStorage("webSocketUrlString") private var urlString: String = "ws://192.168.0.1:9090"
    @ObservedObject var model: WebSocketTaskController
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("WebSocket Status")
                .bold()
            switch model.state {
            case .hasTask(taskState: .idle):
                HImageTextView(image: ("globe", .gray), text: ("Idle", .gray))
            case .hasTask(taskState: .attemptingConnection(let url)):
                HImageTextView(image: ("globe", .yellow), text: ("Connecting to \(url)", .gray))
            case .hasTask(taskState: .connected(let url)):
                HImageTextView(image: ("globe", .green), text: ("Connected to \(url)", .gray))
            case .hasTask(taskState: .disconnected):
                HImageTextView(image: ("globe", .red), text: ("Disconnected", .gray))
            case .noTask:
                HImageTextView(image: ("globe", .gray), text: ("No task", .gray))
            }
            HStack {
                Text("URL")
                    .foregroundColor(.gray)
                TextField("URL", text: $urlString)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit {
                        // if the submitted text is valid as an WebSocket URL
                        // replace the current WebSocket task
                        guard let url = WebSocketURL(string: urlString) else { return }
                        model.changeTask(with: url)
                    }
            }
        }
        .onAppear() {
            // initialize the WebSocket task
            guard let url = WebSocketURL(string: urlString) else { return }
            model.changeTask(with: url)
        }
    }
}
