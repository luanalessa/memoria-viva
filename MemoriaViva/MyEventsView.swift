import SwiftUI

struct MyEventsView: View {
    @StateObject private var vm = MyEventsViewModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            header

            ScrollView {
                LazyVStack(spacing: 14) {
                    ForEach(vm.events) { event in
                        EventCard(
                            event: event,
                            onToggleReminder: { vm.toggleReminder(for: event.id) },
                            onDelete: { vm.delete(eventId: event.id) }
                        )
                    }
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 16)
        .onAppear { vm.load() }
        .alert("Erro", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { _ in vm.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Meus Eventos")
                .font(.system(size: 34, weight: .bold))

            Text("\(vm.totalSaved) eventos salvos")
                .foregroundStyle(.secondary)
        }
    }
}
