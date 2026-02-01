import Foundation

struct UsersFile: Codable {
    var currentUserId: String
    var users: [MVUser]
}

struct MVUser: Codable, Identifiable {
    var id: String
    var name: String
    var savedEvents: [MVEvent]
}

struct MVEvent: Codable, Identifiable, Equatable {
    var id: String
    var title: String
    var place: String
    var startAt: Date
    var reminderEnabled: Bool
    var reminderMinutesBefore: Int
}
