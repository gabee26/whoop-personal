#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

struct PersonalWorkoutLog: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var intelligence: IntelligenceEngine
    @State private var rows: [WorkoutRow] = []
    @State private var period = 30
    @State private var loading = true
    @State private var editor: EditTarget?
    @State private var deletion: EditTarget?
    private struct EditTarget: Identifiable {
        let id = UUID()
        var row: WorkoutRow?
    }
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalPage(title: "ATIVIDADES") {
            NavigationLink { PersonalLiveScreen() } label: {
                PersonalWhoopCard { Label("INICIAR ATIVIDADE", systemImage: "play.circle").font(S.label) }
            }.buttonStyle(.plain)
            PersonalAction(title: "ADICIONAR ATIVIDADE", icon: "plus") { editor = EditTarget() }
            Picker("Histórico", selection: $period) {
                Text("30 dias").tag(30)
                Text("90 dias").tag(90)
                Text("Tudo").tag(4000)
            }.pickerStyle(.segmented)
            if loading { ProgressView("A carregar atividades…") }
            else if rows.isEmpty {
                PersonalWhoopCard { Text("Sem atividades neste período.").font(S.body).foregroundStyle(S.secondary) }
            }
            LazyVStack(spacing: S.gap) {
                ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                    NavigationLink {
                        PersonalPage(title: "ATIVIDADE") {
                            summary(row)
                            if WorkoutSource.classify(row.source) == .manual || WorkoutSource.classify(row.source) == .detected {
                                PersonalAction(title: "EDITAR ATIVIDADE", icon: "pencil") { editor = EditTarget(row: row) }
                                PersonalAction(title: "APAGAR ATIVIDADE", icon: "trash") { deletion = EditTarget(row: row) }
                            }
                            if let note = row.notes, !note.isEmpty {
                                PersonalWhoopCard { Text(note).font(S.body) }
                            }
                        }
                    } label: { summary(row) }.buttonStyle(.plain)
                }
            }
        }.task(id: "\(period)-\(repo.refreshSeq)") { await reload() }
            .confirmationDialog("Apagar esta atividade?", isPresented: Binding(get: { deletion != nil }, set: { if !$0 { deletion = nil } }), titleVisibility: .visible) {
                Button("Apagar", role: .destructive) {
                    guard let row = deletion?.row else { return }
                    deletion = nil
                    RouteStore.remove(startTs: row.startTs, sport: row.sport)
                    Task { await repo.deleteWorkout(row); await reload() }
                }
                Button("Cancelar", role: .cancel) { deletion = nil }
            } message: { Text("A atividade e o respetivo percurso serão apagados. Esta ação não pode ser anulada.") }
            .sheet(item: $editor) { target in
                ManualWorkoutSheet(editing: target.row) { row, replacing in
                    Task {
                        await repo.saveManualWorkout(row, replacing: replacing)
                        await intelligence.analyzeRecent()
                        await reload()
                    }
                }
            }
    }
    private func summary(_ row: WorkoutRow) -> some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.margin) {
                Text(WorkoutSource.displaySport(row.sport)).font(S.heading)
                Text(Date(timeIntervalSince1970: Double(row.startTs)), format: .dateTime.day().month().year().hour().minute())
                    .font(S.label).foregroundStyle(S.secondary)
                HStack {
                    stat("DURAÇÃO", "\(max(0, row.endTs - row.startTs) / 60) min")
                    stat("ESFORÇO", PersonalMetricScale.effort(row.strain).map { String(format: "%.1f", $0) } ?? "--")
                }
                HStack {
                    stat("FC MÉDIA", row.avgHr.map { "\($0) bpm" } ?? "--")
                    stat("FC MÁXIMA", row.maxHr.map { "\($0) bpm" } ?? "--")
                }
            }
        }
    }
    private func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: S.gap) {
            Text(title).font(S.label).foregroundStyle(S.secondary)
            Text(value).font(S.body)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
    @MainActor private func reload() async {
        loading = true
        let loaded = await repo.workoutRows(days: period)
        guard !Task.isCancelled else { return }
        rows = loaded.sorted { $0.startTs > $1.startTs }
        loading = false
    }
}
#endif
