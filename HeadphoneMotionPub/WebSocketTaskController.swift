//
//  WebSocketTaskController.swift
//  HeadphoneMotionPub
//
//  Created by Yoshito Okada on 2023/04/09.
//

import Combine
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

// a wrapper of URLSessionWebSocketTask
//   - automatically attempt connection on init, and disconnect on deinit
//   - publish connection state
class WebSocketTask: NSObject, URLSessionWebSocketDelegate, ObservableObject {
    
    // MARK: - State definitions
    
    enum State {
        case idle
        case attemptingConnection(url: WebSocketURL)
        case connected(url: WebSocketURL)
        // case connectionFailed(url: WebSocketUrl, error: Error)
        case disconnected//(url: WebSocketUrl, closeCode: URLSessionWebSocketTask.CloseCode)
        // case aborted(url: WebSocketUrl)
    }

    // MARK: - Properties
    
    let url: WebSocketURL
    @Published private(set) var state: State

    // MARK: - Private properties
    
    private var task: URLSessionWebSocketTask?
    
    // MARK: - Initializers
    
    init(with url: WebSocketURL) {
        // init properties first
        self.url = url
        self.state = .idle
        self.task = nil
        // init the super classes. this makes using "self" possible
        super.init()
        // init and start task using "self" (we must call resume() to attempt connection)
        self.task = URLSession(configuration: .default, delegate: self, delegateQueue: .main).webSocketTask(with: url.url)
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
        state = .attemptingConnection(url: url)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError maybeError: Error?) {
        state = .disconnected
    }
    
    // MARK: - URLSessionWebSocketTaskDelegate
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        state = .connected(url: url)
    }
    
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask,
                    didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        state = .disconnected
    }
}

// a controller of WebSocket task
//   - owns 1 task at most
//   - monitors the task and resumes if in the disconnected state
class WebSocketTaskController: ObservableObject {
    
    // MARK: - Enums
    
    enum State {
        case noTask
        case hasTask(taskState: WebSocketTask.State)
    }
    
    // MARK: - Properties
    
    @Published var state: State = .noTask

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
    
    func send(_ message: URLSessionWebSocketTask.Message) {
        task?.send(message)
    }
    
    func changeTask(with newUrl: WebSocketURL) {
        // do nothing if the given url is equal to the url of the current task
        guard task?.url != newUrl else { return }
        // discard the current task
        task = nil
        stateSyncCancellable = nil
        // start a new task with the given url
        task = WebSocketTask(with: newUrl)
        state = .hasTask(taskState: task!.state)
        stateSyncCancellable = task!.$state.sink {
            [weak weakSelf = self] newValue in
            weakSelf?.state = .hasTask(taskState: newValue)
        }
    }
    
    // MARK: - Private methods
    
    private func resumeTask() {
        // if the current task is in the disconnected state,
        // start a new task with the same url
        switch task?.state {
        case .disconnected:
            // discard the current disconnected task after remembering the url
            let url = task!.url
            task = nil
            stateSyncCancellable = nil
            // start a new task with the same url
            task = WebSocketTask(with: url)
            state = .hasTask(taskState: task!.state)
            stateSyncCancellable = task!.$state.sink {
                [weak weakSelf = self] newValue in
                weakSelf?.state = .hasTask(taskState: newValue)
            }
        default:
            break
        }
    }
}
