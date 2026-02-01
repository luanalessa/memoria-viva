import Foundation

@MainActor
final class MyEventsViewModel: ObservableObject {
    @Published private(set) var events: [MVEvent] = []
    @Published private(set) var totalSaved: Int = 0
    @Published var errorMessage: String?

    private var usersFile: UsersFile?

    func load() {
        do {
            let file = try UsersRepository.shared.load()
            self.usersFile = file

            guard let user = file.users.first(where: { $0.id == file.currentUserId }) else {
                self.events = []
                self.totalSaved = 0
                return
            }

            // ordena por data/hora
            self.events = user.savedEvents.sorted(by: { $0.startAt < $1.startAt })
            self.totalSaved = user.savedEvents.count

        } catch {
            self.errorMessage = error.localizedDescription
        }
    }

    func toggleReminder(for eventId: String) {
        guard var file = usersFile else { return }
        guard let uIndex = file.users.firstIndex(where: { $0.id == file.currentUserId }) else { return }
        guard let eIndex = file.users[uIndex].savedEvents.firstIndex(where: { $0.id == eventId }) else { return }

        file.users[uIndex].savedEvents[eIndex].reminderEnabled.toggle()

        persistAndRefresh(file)
    }

    func delete(eventId: String) {
        guard var file = usersFile else { return }
        guard let uIndex = file.users.firstIndex(where: { $0.id == file.currentUserId }) else { return }

        file.users[uIndex].savedEvents.removeAll(where: { $0.id == eventId })

        persistAndRefresh(file)
    }

    private func persistAndRefresh(_ file: UsersFile) {
        do {
            try UsersRepository.shared.save(file)
            self.usersFile = file
            load()
        } catch {
            self.errorMessage = error.localizedDescription
        }
    }
}
