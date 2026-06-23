import Foundation

public enum ChildlockMonitoringStatus: String, CaseIterable, Sendable {
    case notStarted = "not_started"
    case running
    case intervalStarted = "interval_started"
    case thresholdReached = "threshold_reached"
    case challengeRequested = "challenge_requested"
    case moreTimeRequested = "more_time_requested"
    case intervalEnded = "interval_ended"
    case stopped
    case denied
    case failed

    public init?(storedValue: String?) {
        guard let storedValue else { return nil }
        self.init(rawValue: storedValue)
    }

    public var canRearmMonitoring: Bool {
        switch self {
        case .running, .intervalStarted, .thresholdReached, .challengeRequested, .moreTimeRequested:
            return true
        case .notStarted, .intervalEnded, .stopped, .denied, .failed:
            return false
        }
    }
}
