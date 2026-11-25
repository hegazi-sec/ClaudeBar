// UsageBar: menu bar readout of Claude plan limits (5-hour, weekly, per-model weekly).
// ponytail: uses the undocumented /api/oauth/usage endpoint with Claude Code's Keychain token; may break on Anthropic updates.
import AppKit

struct Limit { let label: String; let percent: Int; let resetsAt: Date? }

func readToken() -> String? {
    let p = Process(), out = Pipe()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
    p.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
    p.standardOutput = out; p.standardError = Pipe()
    guard (try? p.run()) != nil else { return nil }
    p.waitUntilExit()
    guard p.terminationStatus == 0,
          let json = try? JSONSerialization.jsonObject(with: out.fileHandleForReading.readDataToEndOfFile()) as? [String: Any],
          let oauth = json["claudeAiOauth"] as? [String: Any] else { return nil }
    return oauth["accessToken"] as? String
}

func parseLimits(_ data: Data) -> [Limit]? {
    guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
          let limits = json["limits"] as? [[String: Any]] else { return nil }
    let iso = ISO8601DateFormatter(); iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return limits.compactMap { l in
        guard let pct = l["percent"] as? Int else { return nil }
        let model = ((l["scope"] as? [String: Any])?["model"] as? [String: Any])?["display_name"] as? String
        let label: String
        switch l["kind"] as? String {
        case "session": label = "5h"
        case "weekly_all": label = "Week"
        default: label = model ?? (l["kind"] as? String ?? "?")
        }
        return Limit(label: label, percent: pct, resetsAt: (l["resets_at"] as? String).flatMap { iso.date(from: $0) })
    }
}

func ringColor(_ p: Int) -> NSColor { p >= 90 ? .systemRed : p >= 70 ? .systemOrange : .systemGreen }

func ring(percent: Int, stale: Bool) -> NSImage {
    NSImage(size: NSSize(width: 18, height: 18), flipped: false) { r in
        let c = NSPoint(x: r.midX, y: r.midY), radius: CGFloat = 6.5
        let track = NSBezierPath(); track.appendArc(withCenter: c, radius: radius, startAngle: 0, endAngle: 360)
        track.lineWidth = 2.5; NSColor.tertiaryLabelColor.setStroke(); track.stroke()
        guard !stale || percent > 0 else { return true }
        let arc = NSBezierPath() // clockwise from 12 o'clock
        arc.appendArc(withCenter: c, radius: radius, startAngle: 90, endAngle: 90 - 360 * CGFloat(min(percent, 100)) / 100, clockwise: true)
        arc.lineWidth = 2.5; arc.lineCapStyle = .round
        (stale ? NSColor.secondaryLabelColor : ringColor(percent)).setStroke(); arc.stroke()
        return true
    }
}

final class App: NSObject, NSApplicationDelegate {
    let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    var limits: [Limit] = [], status = "Loading…", updated: Date?

    func applicationDidFinishLaunching(_ n: Notification) {
        item.button?.image = ring(percent: 0, stale: true)
        refresh()
        Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in self?.refresh() } // 1 min poll; backs off on 429
    }

    var token: String?, pausedUntil = Date.distantPast, inFlight = false

    @objc func refresh() {
        guard !inFlight, Date() >= pausedUntil else { return }
        if token == nil { token = readToken() } // cached; re-read from Keychain only after a 401
        guard let token else {
            return show(status: "No Claude sign-in in Keychain (API key users have no plan limits)")
        }
        inFlight = true
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        URLSession.shared.dataTask(with: req) { data, resp, err in
            let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async {
                self.inFlight = false
                if code == 401 { self.token = nil; return self.show(status: "Token expired: open Claude Code to refresh") }
                if code == 429 { // rate limited: pause for Retry-After, default 60s
                    let wait = ((resp as? HTTPURLResponse)?.value(forHTTPHeaderField: "Retry-After")).flatMap(Double.init) ?? 60
                    self.pausedUntil = Date().addingTimeInterval(wait)
                    return self.show(status: "Rate limited, pausing \(Int(wait))s")
                }
                guard code == 200, let data, let l = parseLimits(data) else {
                    return self.show(status: "Fetch failed (\(err?.localizedDescription ?? "HTTP \(code)"))")
                }
                self.limits = l; self.updated = Date(); self.show(status: nil)
            }
        }.resume()
    }

    func show(status: String?) {
        self.status = status ?? ""
        // Ring = the most-used limit; percentages live in the click menu. Gray ring = no data / stale.
        let worst = limits.map(\.percent).max()
        item.button?.title = ""
        item.button?.image = ring(percent: worst ?? 0, stale: worst == nil || status != nil)
        item.button?.toolTip = limits.map { "\($0.label) \($0.percent)%" }.joined(separator: " · ")

        let menu = NSMenu(), rel = RelativeDateTimeFormatter()
        for l in limits {
            let reset = l.resetsAt.map { "resets " + rel.localizedString(for: $0, relativeTo: Date()) } ?? ""
            menu.addItem(withTitle: "\(l.label): \(l.percent)%   \(reset)", action: nil, keyEquivalent: "")
        }
        if let status, !status.isEmpty { menu.addItem(withTitle: status, action: nil, keyEquivalent: "") }
        if let updated { menu.addItem(withTitle: "Updated " + rel.localizedString(for: updated, relativeTo: Date()), action: nil, keyEquivalent: "") }
        menu.addItem(.separator())
        menu.addItem(withTitle: "Refresh", action: #selector(refresh), keyEquivalent: "r").target = self
        menu.addItem(withTitle: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
    }
}

if CommandLine.arguments.contains("--selftest") {
    let sample = #"{"limits":[{"kind":"session","percent":93,"resets_at":"2026-11-25T06:59:59.867047+00:00","scope":null},{"kind":"weekly_all","percent":42,"resets_at":"2026-11-26T07:59:59.867065+00:00"},{"kind":"weekly_scoped","percent":82,"resets_at":null,"scope":{"model":{"display_name":"Fable"}}}]}"#
    let l = parseLimits(Data(sample.utf8))!
    assert(l.map(\.label) == ["5h", "Week", "Fable"] && l.map(\.percent) == [93, 42, 82])
    assert(l[0].resetsAt != nil && l[2].resetsAt == nil)
    assert(parseLimits(Data("{}".utf8)) == nil)
    assert(ringColor(42) == .systemGreen && ringColor(82) == .systemOrange && ringColor(93) == .systemRed)
    if let out = CommandLine.arguments.last, out.hasSuffix(".png") { // optional: render sample rings to eyeball
        let sheet = NSImage(size: NSSize(width: 72, height: 18), flipped: false) { _ in
            for (i, p) in [42, 82, 93, 0].enumerated() { ring(percent: p, stale: p == 0).draw(at: NSPoint(x: i * 18, y: 0), from: .zero, operation: .sourceOver, fraction: 1) }
            return true
        }
        let rep = NSBitmapImageRep(data: sheet.tiffRepresentation!)!
        try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: out))
    }
    print("selftest ok"); exit(0)
}

if CommandLine.arguments.contains("--print") { // live check from the terminal, same fetch as the menu bar
    var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
    req.setValue("Bearer \(readToken() ?? "")", forHTTPHeaderField: "Authorization")
    req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
    let done = DispatchSemaphore(value: 0)
    URLSession.shared.dataTask(with: req) { data, _, _ in
        print((data.flatMap(parseLimits) ?? []).map { "\($0.label) \($0.percent)%" }.joined(separator: " · "))
        done.signal()
    }.resume()
    done.wait(); exit(0)
}

let app = NSApplication.shared, delegate = App()
app.delegate = delegate
app.setActivationPolicy(.accessory) // menu bar only, no Dock icon
app.run()
