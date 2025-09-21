import Foundation

struct FocusSession: Identifiable, Codable, Equatable {
    enum Outcome: String, Codable {
        case completed
        case abandoned
    }

    let id: UUID
    let duration: TimeInterval
    var reflection: String
    let startedAt: Date
    let endedAt: Date
    let outcome: Outcome

    init(id: UUID = UUID(),
         duration: TimeInterval,
         reflection: String = "",
         startedAt: Date,
         endedAt: Date,
         outcome: Outcome = .completed) {
        self.id = id
        self.duration = duration
        self.reflection = reflection
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.outcome = outcome
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        return "\(minutes) min"
    }
}
