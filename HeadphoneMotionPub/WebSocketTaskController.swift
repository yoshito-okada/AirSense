//
//  WebSocketTaskController.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/09.
//

import Foundation

// a wrapper around URL that only accepts standardized WebSocket URL
struct WebSocketURL: Equatable, CustomStringConvertible {
    let url: URL
    
    init?(string: String) {
        // parsed as an URL?
        guard let components = URLComponents(string: string) else { return nil }
        // has a web socket scheme?
        guard let scheme = components.scheme, (scheme == "ws" || scheme == "wss") else { return nil }
        // no invalid charactors?
        guard let parsedUrl = components.url, parsedUrl.absoluteString == string else { return nil }
        // accept!
        url = parsedUrl
    }
    
    var description: String {
        return url.absoluteString
    }
}

// general lifecycle of WebSocket
enum WebSocketState: CustomStringConvertible {
    case idle
    case connectionAttempting
    case connected
    case disconnected
    
    var description: String {
        switch self {
        case .idle:
            return "Idle"
        case .connectionAttempting:
            return "Connection Attempting"
        case .connected:
            return "Connected"
        case .disconnected:
            return "Disconnected"
        }
    }
}

// type of callback for handling WebSocket state
typealias WebSocketStateHandler = (/* url: */WebSocketURL, /* newState: */ WebSocketState, /* reason: */ String) -> Void

// a delegate that notifies WebSocket states
class WebSocketDelegate: NSObject, URLSessionWebSocketDelegate {
    let url: WebSocketURL
    private(set) var state: WebSocketState = .idle
    var stateHandler: WebSocketStateHandler? {
        didSet {
            stateHandler?(url, state, "State handler changed (\(url))")
        }
    }
    
    init(url: WebSocketURL) {
        self.url = url
    }
    
    // MARK: -URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        updateState(newState: .connectionAttempting, reason: "Task created (\(url))")
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError maybeError: Error?) {
        let errorString = (maybeError != nil ? maybeError!.localizedDescription : "Success")
        updateState(newState: .disconnected, reason: "Task completed (\(url), \(errorString))")
    }
    
    // MARK: -URLSessionWebSocketTaskDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        updateState(newState: .connected, reason: "WebSocket connected (\(url))")
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        updateState(newState: .disconnected, reason: "WebSocket disconnected (\(url), \(closeCode))")
    }
    
    //
    
    private func updateState(newState: WebSocketState, reason: String) {
        print("[WebSocket] \(state) -> \(newState): \(reason)")
        state = newState
        stateHandler?(url, newState, reason)
    }
}

// a wrapper of URLSessionWebSocketTask
//   - automatically attempt connection on init, and disconnect on deinit
//   - can change handlers to run when the WebSocket state changes
class WebSocketTask {
    var url: WebSocketURL {
        return delegate.url
    }
    var state: WebSocketState {
        return delegate.state
    }
    var stateHandler: WebSocketStateHandler? {
        get {
            return delegate.stateHandler
        }
        set {
            delegate.stateHandler = newValue
        }
    }
    
    private let delegate: WebSocketDelegate
    private let task: URLSessionWebSocketTask
    
    init(with url: WebSocketURL) {
        //
        self.delegate = WebSocketDelegate(url: url)
        self.task = URLSession(configuration: .default, delegate: self.delegate, delegateQueue: .main).webSocketTask(with: url.url)
        
        // call resume() to attempt connection
        self.task.resume()
    }
    
    deinit {
        // complete the task on deinit
        task.cancel()
    }
    
    func send(_ message: URLSessionWebSocketTask.Message) {
        task.send(message) { _ in }
    }
}

// a controller of WebSocket task
//   - owns 1 task at most
//   - notifies the task states using a handler
//   - changes the task when given a new URL
//   - monitors the task and resumes if in the disconnected state
class WebSocketTaskController {
    var url: WebSocketURL? {
        get {
            return task?.url
        }
        set {
            guard newValue != nil else { return }
            changeTask(with: newValue!)
        }
    }
    var stateHandler: WebSocketStateHandler? {
        didSet {
            task?.stateHandler = stateHandler
        }
    }
    
    private var task: WebSocketTask?
    private let resumeTimer: DispatchSourceTimer
    
    init() {
        // start repeating restartTask() every second
        self.resumeTimer = DispatchSource.makeTimerSource(queue: .main)
        self.resumeTimer.schedule(deadline: .now(), repeating: .seconds(1))
        self.resumeTimer.setEventHandler(handler: resumeTask)
        self.resumeTimer.resume()
    }
    
    deinit {
        // stop repitation in deinit
        resumeTimer.cancel()
    }
    
    func send(_ message: URLSessionWebSocketTask.Message) {
        task?.send(message)
    }
    
    private func changeTask(with newUrl: WebSocketURL) {
        // if the given url is not equal to the url of the current task,
        // discard the current task and start a new task with the given url.
        // replace the state handler with the new task before discarding the previous task
        // to avoid notification congestion.
        guard task?.url != newUrl else { return }
        task?.stateHandler = nil
        task = WebSocketTask(with: newUrl)
        task!.stateHandler = stateHandler
    }
    
    private func resumeTask() {
        // if the current task is in the disconnected state,
        // start a new task with the same url
        guard task?.state == .disconnected else { return }
        task!.stateHandler = nil
        task = WebSocketTask(with: task!.url)
        task!.stateHandler = stateHandler
    }
}
