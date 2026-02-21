import XCTest
@testable import dominoes

final class GameFlowStateMachineTests: XCTestCase {
    func testStartFirstImpactThenCountdownResetsToIdle() {
        var machine = GameFlowStateMachine()

        XCTAssertTrue(machine.startSimulation())
        XCTAssertEqual(machine.state, .animating)

        XCTAssertTrue(machine.markFirstImpact())
        XCTAssertEqual(machine.state, .firstImpact)

        XCTAssertTrue(machine.startAutoResetCountdown(seconds: 3))
        XCTAssertEqual(machine.countdownSecondsRemaining, 3)

        XCTAssertEqual(machine.tickCountdown(), 2)
        XCTAssertEqual(machine.countdownSecondsRemaining, 2)

        XCTAssertEqual(machine.tickCountdown(), 1)
        XCTAssertEqual(machine.countdownSecondsRemaining, 1)

        XCTAssertEqual(machine.tickCountdown(), 0)
        XCTAssertEqual(machine.state, .idle)
        XCTAssertNil(machine.countdownSecondsRemaining)
    }

    func testInvalidTransitionsAreRejected() {
        var machine = GameFlowStateMachine()

        XCTAssertFalse(machine.markFirstImpact())
        XCTAssertFalse(machine.startAutoResetCountdown(seconds: 0))
        XCTAssertTrue(machine.startSimulation())
        XCTAssertFalse(machine.startSimulation())
    }
}
