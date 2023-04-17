//
//  WebSocketTaskControllerView.swift
//  HeadphoneMotionPub
//
//  Created by SpacialVision on 2023/04/15.
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
            case .hasTask(taskState: .idle):
                HImageText(image: ("globe", .gray), text: ("Idle", .gray))
            case .hasTask(taskState: .attemptingConnection(let url)):
                HImageText(image: ("globe", .yellow), text: ("Connecting to \(url)", .gray))
            case .hasTask(taskState: .connected(let url)):
                HImageText(image: ("globe", .green), text: ("Connected to \(url)", .gray))
            case .hasTask(taskState: .disconnected):
                HImageText(image: ("globe", .red), text: ("Disconnected", .gray))
            case .noTask:
                HImageText(image: ("globe", .gray), text: ("No task", .gray))
            }
            HTextUrlField(text: ("URL", .gray), textField: ($url, { changeTask(with: url) }))
        }
        .onAppear() {
            // initialize the WebSocket task
            changeTask(with: url)
        }
    }
    
    private func changeTask(with url: URL) {
        guard let url = WebSocketURL(value: url) else { return }
        model.changeTask(with: url)
    }
}
