//
//  FrameSender.swift
//  sensorCollect
//
//  Created by 何子勤 on 8/10/25.
//

import Foundation
import Network

final class FrameSender {
    private var conn: NWConnection?
    private(set) var ready = false

    func connect(to host: String, port: UInt16 = 9999) {
        conn?.cancel()
        ready = false
        let connection = NWConnection(host: NWEndpoint.Host(host), port: NWEndpoint.Port(rawValue: port)!, using: .tcp)
        self.conn = connection
        connection.stateUpdateHandler = { [weak self] s in
            switch s {
            case .ready: self?.ready = true; print("[FrameSender] ready")
            case .failed(let e): self?.ready = false; print("[FrameSender] failed:", e)
            case .waiting(let e): print("[FrameSender] waiting:", e)
            default: break
            }
        }
        connection.start(queue: .global(qos: .userInitiated))
    }

    func sendJPEG(_ data: Data) {
        guard ready, let c = conn else { return }
        var lenBE = UInt32(data.count).bigEndian
        let header = Data(bytes: &lenBE, count: 4)
        c.send(content: header + data, completion: .contentProcessed { err in
            if let err = err { print("[FrameSender] send err:", err) }
        })
    }

    func disconnect() {
        conn?.cancel()
        ready = false
    }
}
