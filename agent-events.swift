import Foundation
import Network

struct AgentEvent: Decodable {
    let chat_name: String?
    let version: Int
    let source, type, event_id, preview: String
}

final class AgentReceiver {
    let pairingURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Sneakpaw/codex-pair.json")
    let queue = DispatchQueue(label: "com.caolibin.sneakpaw.agent-events")
    private var listener: NWListener?
    private struct Delivery: Equatable { let source, id: String }
    private var recent: [Delivery] = []
    var received: ((AgentEvent) -> Void)?
    var availability: ((Bool) -> Void)?
    private let token = UUID().uuidString + UUID().uuidString

    func start() {
        do {
            let parameters = NWParameters.tcp
            parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
            let service = try NWListener(using: parameters)
            listener = service
            service.stateUpdateHandler = { [weak self, weak service] state in
                guard let self else { return }
                if case .ready = state, let port = service?.port {
                    do {
                        try FileManager.default.createDirectory(at: pairingURL.deletingLastPathComponent(), withIntermediateDirectories: true,
                            attributes: [.posixPermissions: 0o700])
                        let bytes = try JSONSerialization.data(withJSONObject:["port": Int(port.rawValue),"token":token])
                        try bytes.write(to: pairingURL, options:.atomic)
                        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: pairingURL.path)
                        DispatchQueue.main.async { self.availability?(true) }
                    } catch { service?.cancel() }
                } else if case .failed = state { DispatchQueue.main.async { self.availability?(false) } }
            }
            service.newConnectionHandler = { [weak self] c in
                guard let self else { c.cancel(); return }
                c.start(queue: queue)
                queue.asyncAfter(deadline:.now()+2) { c.cancel() }
                read(c, bytes:Data())
            }
            service.start(queue:queue)
        } catch { availability?(false) }
    }

    private func read(_ c:NWConnection, bytes:Data) {
        c.receive(minimumIncompleteLength:1, maximumLength:8192) { [weak self] part,_,done,error in
            guard let self, error == nil else { c.cancel(); return }
            let data = bytes + (part ?? Data())
            guard data.count <= 16384 else { reply(c,413); return }
            guard let separator = data.range(of:Data("\r\n\r\n".utf8)) else {
                if !done { read(c,bytes:data) } else { c.cancel() }
                return
            }
            let lines = String(decoding:data[..<separator.lowerBound],as:UTF8.self).components(separatedBy:"\r\n")
            guard lines.first == "POST /v1/events HTTP/1.1" else { reply(c,404); return }
            var headers: [String:String] = [:]
            for line in lines.dropFirst() {
                let kv = line.split(separator:":",maxSplits:1)
                guard kv.count == 2, headers[kv[0].lowercased()] == nil else { reply(c,400); return }
                headers[kv[0].lowercased()] = kv[1].trimmingCharacters(in:.whitespaces)
            }
            guard headers["authorization"] == "Bearer "+token else { reply(c,401); return }
            guard let length = Int(headers["content-length"] ?? ""), (1...8192).contains(length), headers["transfer-encoding"] == nil else { reply(c,400); return }
            let body = data[separator.upperBound...]
            if body.count < length && !done { read(c,bytes:data); return }
            guard body.count == length, let event = try? JSONDecoder().decode(AgentEvent.self,from:body),
                  event.version == 1, (1...64).contains(event.source.count),
                  !event.source.trimmingCharacters(in:.whitespacesAndNewlines).isEmpty,
                  event.source.rangeOfCharacter(from:.controlCharacters) == nil, ["turn.completed","connection.test"].contains(event.type),
                  !event.event_id.isEmpty, event.event_id.count <= 256, event.preview.count <= 512 else { reply(c,400); return }
            let delivery = Delivery(source:event.source,id:event.event_id)
            if !recent.contains(delivery) {
                recent.append(delivery)
                if recent.count > 128 { recent.removeFirst() }
                DispatchQueue.main.async { self.received?(event) }
            }
            reply(c,204)
        }
    }
    private func reply(_ c:NWConnection,_ status:Int) {
        let response = Data("HTTP/1.1 \(status) Response\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".utf8)
        c.send(content:response,completion:.contentProcessed { _ in c.cancel() })
    }
}
