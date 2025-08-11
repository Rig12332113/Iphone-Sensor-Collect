//
//  DataSender.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/3/25.
//

import Foundation
import Network

final class DataSender: ObservableObject {
    @Published var isReady = false
    @Published var status = "Idle"

    private var connection: NWConnection?
    private(set) var currentHost: String?
    private let port: NWEndpoint.Port = 8888

    // Call this when the user taps “Connect”
    func connect(to host: String) {
        // Clean up previous connection
        connection?.cancel()
        isReady = false
        status = "Connecting…"
        currentHost = host.trimmingCharacters(in: .whitespacesAndNewlines)

        let conn = NWConnection(host: NWEndpoint.Host(currentHost!), port: port, using: .tcp)
        connection = conn

        conn.stateUpdateHandler = { [weak self] state in
            DispatchQueue.main.async {
                switch state {
                case .ready:
                    self?.isReady = true
                    self?.status = "Connected to \(host)"
                    // Optional: start receiving server echoes
                    self?.receiveLoop()
                case .waiting(let e):
                    self?.isReady = false
                    self?.status = "Waiting: \(e.localizedDescription)"
                case .failed(let e):
                    self?.isReady = false
                    self?.status = "Failed: \(e.localizedDescription)"
                case .cancelled:
                    self?.isReady = false
                    self?.status = "Cancelled"
                default:
                    break
                }
            }
        }

        conn.start(queue: .global(qos: .userInitiated))
    }

    func disconnect() {
        connection?.cancel()
        isReady = false
        status = "Disconnected"
    }

    func send(_ text: String) {
        guard let connection, isReady else { status = "Not connected"; return }
        connection.send(content: Data(text.utf8), completion: .contentProcessed { [weak self] err in
            DispatchQueue.main.async {
                self?.status = err == nil ? "Sent" : "Send error: \(err!.localizedDescription)"
            }
        })
    }

    private func receiveLoop() {
        connection?.receive(minimumIncompleteLength: 1, maximumLength: 4096) { [weak self] data, _, done, error in
            if let data, !data.isEmpty {
                let text = String(decoding: data, as: UTF8.self)
                print("[iPhone] <- \(text)")
            }
            if done || error != nil { return }
            self?.receiveLoop()
        }
    }
}

