//
//  WebSocketController.swift
//  AirSense
//
//  Created by Yoshito Okada on 2023/04/09.
//

import Combine
import Foundation

// a wrapper around URL that only accepts standardized WebSocket URL
struct WebSocketURL: Equatable, CustomStringConvertible {
    let value: URL
    
    init?(value: URL) {
        // parse input URL into components
        guard let components = URLComponents(string: value.absoluteString) else { return nil }
        // check for WebSocket scheme
        guard let scheme = components.scheme, (scheme == "ws" || scheme == "wss") else { return nil }
        // ensure input URL comforms to standard by comparing with reconstructed URL
        guard let url = components.url, url == value else { return nil }
        self.value = value
    }
    
    var description: String {
        return value.description
    }
}

// a wrapper of URLSessionWebSocketTask
//   - automatically attempt connection on init, and disconnect on deinit
//   - publish connection state
class WebSocketTask: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    
    // MARK: - State definitions
    
    enum State {
        case initialized(url: WebSocketURL)
        case connecting(url: WebSocketURL)
        case connected(url: WebSocketURL)
        case disconnected(url: WebSocketURL, closeCode: URLSessionWebSocketTask.CloseCode)
        case finished(url: WebSocketURL, error: Error?)
    }

    // MARK: - Properties
    
    let url: WebSocketURL
    @Published private(set) var state: State
    var isStopped: Bool {
        switch state {
        case .disconnected, .finished:
            return true
        default:
            return false
        }
    }

    // MARK: - Private properties
    
    private var task: URLSessionWebSocketTask?
    
    // MARK: - Initializers
    
    init(with url: WebSocketURL) {
        // init properties first
        self.url = url
        self.state = .initialized(url: url)
        self.task = nil
        // init the super classes. this makes using "self" possible
        super.init()
        // init and start task using "self" (we must call resume() to start)
        self.task = URLSession(configuration: .default, delegate: self, delegateQueue: .main).webSocketTask(with: url.value)
        self.task!.resume()
    }
    
    deinit {
        // complete the task on deinit
        task?.cancel()
    }
    
    // MARK: - Methods
    
    func send(_ message: URLSessionWebSocketTask.Message) {
        task?.send(message) { _ in
            // TODO: error handling
        }
    }
    
    // MARK: - URLSessionTaskDelegate
    
    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        state = .connecting(url: url)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        state = .finished(url: url, error: error)
    }
    
    // MARK: - URLSessionWebSocketTaskDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        state = .connected(url: url)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        state = .disconnected(url: url, closeCode: closeCode)
    }
}

// a controller of WebSocket task
//   - owns 1 task at most
//   - monitors the task and resumes if in the disconnected state
class WebSocketController: ObservableObject {
    
    // MARK: - Enums
    
    enum State {
        case noTask
        case hasTask(taskState: WebSocketTask.State)
    }
    
    // MARK: - Properties
    
    @Published private(set) var state: State = .noTask

    // MARK: - Private properties
    
    private let resumeTimer: DispatchSourceTimer
    private var task: WebSocketTask?
    private var stateSyncCancellable: AnyCancellable?
    
    // MARK: - Initializers
    
    init() {
        // start repeating restartTask() every 5 seconds
        self.resumeTimer = DispatchSource.makeTimerSource(queue: .main)
        self.resumeTimer.schedule(deadline: .now(), repeating: .seconds(5))
        self.resumeTimer.setEventHandler(handler: resumeTask)
        self.resumeTimer.resume()
    }
    
    deinit {
        // stop repitation in deinit
        resumeTimer.cancel()
    }
    
    // MARK: - Methods
    
    // start new task with URL, only if no running task
    func startTask(with url: WebSocketURL) {
        guard task == nil else { return }
        task = WebSocketTask(with: url)
        state = .hasTask(taskState: task!.state)
        stateSyncCancellable = task!.$state.sink {
            [weak weakSelf = self] newValue in
            weakSelf?.state = .hasTask(taskState: newValue)
        }
    }
    
    // discard current task if it exists
    func discardTask() {
        stateSyncCancellable = nil
        state = .noTask
        task = nil
    }
    
    // update task with new URL. if different, discard current and start new one.
    func updateTask(with newUrl: WebSocketURL) {
        guard task?.url != newUrl else { return }
        discardTask()
        startTask(with: newUrl)
    }
    
    // if current task stopped, discard and start new with same URL.
    // user does not have to call this as resumeTimer do periodically.
    func resumeTask() {
        guard let task = task, task.isStopped else { return }
        let url = task.url
        discardTask()
        startTask(with: url)
    }
    
    // send message using current task if it exists
    func send(_ message: URLSessionWebSocketTask.Message) {
        task?.send(message)
    }
}
