import Foundation

struct GameFlowStateMachine {
    enum State: Equatable {
        case idle
        case animating
        case firstImpact
        case autoResetCountdown(secondsRemaining: Int)
    }

    private(set) var state: State = .idle

    var countdownSecondsRemaining: Int? {
        guard case let .autoResetCountdown(secondsRemaining) = state else {
            return nil
        }
        return secondsRemaining
    }

    mutating func resetToIdle() {
        state = .idle
    }

    mutating func startSimulation() -> Bool {
        guard case .idle = state else { return false }
        state = .animating
        return true
    }

    mutating func markFirstImpact() -> Bool {
        guard case .animating = state else { return false }
        state = .firstImpact
        return true
    }

    mutating func startAutoResetCountdown(seconds: Int) -> Bool {
        guard seconds > 0 else { return false }
        guard countdownSecondsRemaining == nil else { return false }
        state = .autoResetCountdown(secondsRemaining: seconds)
        return true
    }

    @discardableResult
    mutating func tickCountdown() -> Int? {
        guard case let .autoResetCountdown(secondsRemaining) = state else {
            return nil
        }

        let next = secondsRemaining - 1
        if next > 0 {
            state = .autoResetCountdown(secondsRemaining: next)
            return next
        }

        state = .idle
        return 0
    }
}
