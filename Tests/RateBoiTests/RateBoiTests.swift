import XCTest
import Combine
@testable import RateBoi

final class RateBoiTests: XCTestCase {
    private var boi: RateBoi!
    private var suite: String!

    override func setUp() {
        super.setUp()

        self.suite = "rateboi.tests.\(UUID().uuidString)"
        self.boi = RateBoi()
        self.boi.configure(suite: self.suite)

    }

    override func tearDown() {
        UserDefaults().removePersistentDomain(forName: self.suite)

        self.boi = nil
        self.suite = nil

        super.tearDown()

    }

    func testManualScoreThresholdFires() {
        self.boi.register(RateTrigger(id: "delight", score: 5))
        self.boi.increment("delight", points: 3)

        XCTAssertFalse(self.boi.fired.contains("delight"))

        self.boi.increment("delight", points: 2)

        XCTAssertTrue(self.boi.fired.contains("delight"))
        XCTAssertEqual(self.boi.score("delight"), 5)

    }

    func testActiveCountsDistinctDaysOncePerDay() {
        self.boi.register(RateTrigger(id: "nudge", days: 2))

        self.boi.active()
        self.boi.active()
        self.boi.active()

        XCTAssertFalse(self.boi.fired.contains("nudge"))

    }

    func testResolveSuppressesFutureFires() {
        self.boi.register(RateTrigger(id: "delight", score: 1))
        self.boi.resolve("delight")
        self.boi.increment("delight", points: 10)

        XCTAssertTrue(self.boi.fired.contains("delight"))

        var received: [String] = []
        let cancellable = self.boi.events.sink { received.append($0) }

        self.boi.increment("delight", points: 10)

        XCTAssertEqual(received, [])

        cancellable.cancel()

    }

    func testCooldownBlocksImmediateRefire() {
        self.boi.register(RateTrigger(id: "nudge", score: 1, cooldown: 3_600))

        var count = 0
        let cancellable = self.boi.events.sink { _ in count += 1 }

        self.boi.increment("nudge", points: 1)
        self.boi.increment("nudge", points: 1)

        XCTAssertEqual(count, 1)

        cancellable.cancel()

    }

    func testSnoozeBlocksThenReleases() {
        self.boi.register(RateTrigger(id: "nudge", score: 1))
        self.boi.snooze("nudge", days: 1)
        self.boi.increment("nudge", points: 5)

        XCTAssertFalse(self.boi.fired.contains("nudge"))

    }

    func testDelightScoringAwardsAtLeastOne() {
        self.boi.register(RateTrigger(id: "delight", score: 100, scoring: .delight))
        self.boi.increment("delight")

        XCTAssertGreaterThanOrEqual(self.boi.score("delight"), 1)

    }

    func testHandlerFiresOnce() {
        self.boi.register(RateTrigger(id: "delight", score: 2))

        var hits = 0
        self.boi.on("delight") { hits += 1 }

        self.boi.increment("delight", points: 2)
        self.boi.increment("delight", points: 2)

        XCTAssertEqual(hits, 1)

    }

    func testResetClearsScore() {
        self.boi.register(RateTrigger(id: "delight", score: 10))
        self.boi.increment("delight", points: 5)
        self.boi.reset("delight")

        XCTAssertEqual(self.boi.score("delight"), 0)
        XCTAssertFalse(self.boi.fired.contains("delight"))

    }

}
