//
//  RateBoi is an open-source dependency for iOS & macOS designed to trigger events at the right time — app-review prompts, onboarding nudges, or any timed callback — Orrivo - Life Intelligence made by Joe Barbour
//  Please Credit this Library
//

import Foundation
import Combine

#if canImport(StoreKit)
    import StoreKit
#endif

#if canImport(UIKit)
    import UIKit
#elseif canImport(AppKit)
    import AppKit
#endif

public enum RateMode: Sendable {
    case all
    case any

}

public enum RateScoring: Sendable {
    case manual
    case delight

}

public struct RateTrigger: Identifiable, Sendable {
    public let id: String
    public var days: Int
    public var sinceInstall: Int
    public var score: Int
    public var cooldown: TimeInterval?
    public var mode: RateMode
    public var scoring: RateScoring

    public init(id: String, days: Int = 0, sinceInstall: Int = 0, score: Int = 0, cooldown: TimeInterval? = nil, mode: RateMode = .all, scoring: RateScoring = .manual) {
        self.id = id
        self.days = days
        self.sinceInstall = sinceInstall
        self.score = score
        self.cooldown = cooldown
        self.mode = mode
        self.scoring = scoring

    }

}

public final class RateBoi: ObservableObject {
    public static let main = RateBoi()

    @Published public private(set) var fired: Set<String> = []

    private var store: UserDefaults = .standard
    private var registry: [String: RateTrigger] = [:]
    private var handlers: [String: () -> Void] = [:]
    private var debug: Bool = false
    private let subject = PassthroughSubject<String, Never>()

    public init() {

    }

    public var events: AnyPublisher<String, Never> {
        return self.subject.eraseToAnyPublisher()

    }

    public func configure(suite: String? = nil, debug: Bool = false) {
        self.debug = debug

        if let suite = suite, let defaults = UserDefaults(suiteName: suite) {
            self.store = defaults

        }
        else {
            self.store = .standard

        }

        if self.date(.install) == nil {
            self.write(.install, value: Date())

        }

        self.rateLog("Configured suite=\(suite ?? "standard")", status: 200)

    }

    public func register(_ trigger: RateTrigger) {
        self.registry[trigger.id] = trigger

        if self.flag(.resolved, id: trigger.id) == true {
            self.fired.insert(trigger.id)

        }

    }

    public func register(_ triggers: [RateTrigger]) {
        for trigger in triggers {
            self.register(trigger)

        }

    }

    public func on(_ id: String, _ handler: @escaping () -> Void) {
        self.handlers[id] = handler

    }

    public func active() {
        let last = self.date(.dayLast)

        if last == nil || Calendar.current.isDateInToday(last!) == false {
            let days = self.int(.days) + 1
            self.write(.days, value: days)
            self.write(.dayLast, value: Date())
            self.rateLog("Active day \(days)", status: 200)

        }

        self.evaluate()

    }

    public func increment(_ id: String, points: Int? = nil) {
        guard let trigger = self.registry[id] else {
            self.rateLog("increment ignored — unknown trigger \(id)", status: 404)
            return

        }

        let current = self.score(id)
        let delta = self.weight(trigger, points: points)

        self.write(.score, id: id, value: current + delta)
        self.rateLog("Score \(id) \(current + delta) (+\(delta))", status: 200)

        self.evaluate()

    }

    public func penalize(_ id: String, points: Int = 3) {
        let current = self.score(id)

        self.write(.score, id: id, value: current - points)
        self.write(.error, id: id, value: Date())
        self.rateLog("Penalize \(id) \(current - points) (-\(points))", status: 201)

    }

    public func resolve(_ id: String) {
        self.write(.resolved, id: id, value: true)
        self.fired.insert(id)
        self.rateLog("Resolved \(id)", status: 200)

    }

    public func snooze(_ id: String, days: Int) {
        let until = Date().addingTimeInterval(Double(days) * 86_400)

        self.write(.snooze, id: id, value: until)
        self.rateLog("Snoozed \(id) until \(until)", status: 200)

    }

    public func reset(_ id: String) {
        for key in RateKey.perTrigger {
            self.write(key, id: id, value: nil)

        }

        self.fired.remove(id)
        self.rateLog("Reset \(id)", status: 200)

    }

    public func reset() {
        for id in self.registry.keys {
            self.reset(id)

        }

        self.write(.days, value: nil)
        self.write(.dayLast, value: nil)
        self.rateLog("Reset all", status: 200)

    }

    public func score(_ id: String) -> Int {
        return self.int(.score, id: id)

    }

    public func evaluate() {
        for trigger in self.registry.values {
            self.assess(trigger)

        }

    }

    #if canImport(StoreKit)
    @MainActor
    public func review() {
        #if canImport(UIKit)
        let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene

        guard let scene = scene else {
            return

        }

        SKStoreReviewController.requestReview(in: scene)
        #elseif canImport(AppKit)
        SKStoreReviewController.requestReview()
        #endif

    }
    #endif

}

extension RateBoi {
    private func assess(_ trigger: RateTrigger) {
        guard self.flag(.resolved, id: trigger.id) == false else {
            return

        }

        if let snooze = self.date(.snooze, id: trigger.id), snooze > Date() {
            return

        }

        if let last = self.date(.fired, id: trigger.id) {
            guard let cooldown = trigger.cooldown else {
                return

            }

            guard Date().timeIntervalSince(last) >= cooldown else {
                return

            }

        }

        var checks: [Bool] = []

        if trigger.days > 0 {
            checks.append(self.int(.days) >= trigger.days)

        }

        if trigger.sinceInstall > 0 {
            checks.append(self.elapsed >= trigger.sinceInstall)

        }

        if trigger.score > 0 {
            checks.append(self.score(trigger.id) >= trigger.score)

        }

        guard checks.isEmpty == false else {
            return

        }

        let met = trigger.mode == .all ? checks.allSatisfy { $0 == true } : checks.contains(true)

        guard met == true else {
            return

        }

        self.write(.fired, id: trigger.id, value: Date())
        self.fired.insert(trigger.id)
        self.subject.send(trigger.id)
        self.handlers[trigger.id]?()
        self.rateLog("Fired \(trigger.id)", status: 200)

    }

    private func weight(_ trigger: RateTrigger, points: Int?) -> Int {
        if let points = points {
            return points

        }

        guard trigger.scoring == .delight else {
            return 1

        }

        var score = 1

        if let minutes = self.date(.touched, id: trigger.id)?.elapsedMinutes {
            switch minutes {
                case 0: score = 10
                case 1: score = 8
                case 2: score = 4
                case 3: score = 2
                default: score = 1

            }

        }

        self.write(.touched, id: trigger.id, value: Date())

        if let error = self.date(.error, id: trigger.id)?.elapsedMinutes, error < 20 {
            score = score / 2

        }

        return max(1, score)

    }

    private var elapsed: Int {
        guard let install = self.date(.install) else {
            return 0

        }

        let components = Calendar.current.dateComponents([.day], from: install, to: Date())

        return components.day ?? 0

    }

}

extension RateBoi {
    private func write(_ key: RateKey, id: String? = nil, value: Any?) {
        let name = key.name(id)

        if let value = value {
            self.store.set(value, forKey: name)

        }
        else {
            self.store.removeObject(forKey: name)

        }

    }

    private func int(_ key: RateKey, id: String? = nil) -> Int {
        return self.store.object(forKey: key.name(id)) as? Int ?? 0

    }

    private func date(_ key: RateKey, id: String? = nil) -> Date? {
        return self.store.object(forKey: key.name(id)) as? Date

    }

    private func flag(_ key: RateKey, id: String? = nil) -> Bool {
        return self.store.object(forKey: key.name(id)) as? Bool ?? false

    }

    private func rateLog(_ text: String, status: Int) {
        guard self.debug == true else {
            return

        }

        switch status {
            case 200: print("✅ RateBoi — \(text)")
            case 201: print("⚠️ RateBoi — \(text)")
            default: print("🚨 RateBoi — \(status) \(text)")

        }

    }

}

enum RateKey {
    case install
    case days
    case dayLast
    case score
    case fired
    case resolved
    case snooze
    case touched
    case error

    static let perTrigger: [RateKey] = [.score, .fired, .resolved, .snooze, .touched, .error]

    func name(_ id: String?) -> String {
        if let id = id {
            return "rateboi.\(id).\(self.suffix)"

        }

        return "rateboi.\(self.suffix)"

    }

    private var suffix: String {
        switch self {
            case .install: return "install"
            case .days: return "days"
            case .dayLast: return "day.last"
            case .score: return "score"
            case .fired: return "fired"
            case .resolved: return "resolved"
            case .snooze: return "snooze"
            case .touched: return "touched"
            case .error: return "error"

        }

    }

}

extension Date {
    var elapsedMinutes: Int? {
        let components = Calendar.current.dateComponents([.minute], from: self, to: Date())

        return components.minute

    }

}
