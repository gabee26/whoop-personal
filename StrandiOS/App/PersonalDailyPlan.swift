#if os(iOS)
import SwiftUI
import StrandDesign

/// Local, user-editable goals; they do not change stored physiology or the scoring engine.
struct PersonalDailyPlan: View {
    @EnvironmentObject private var repo: Repository
    @AppStorage("personal.goal.sleepHours") private var sleepHours = 8.0
    @AppStorage("personal.goal.steps") private var steps = 8000
    @AppStorage("personal.goal.weeklyActivities") private var activities = 4
    private typealias S = PersonalWhoopStyle
    private var today: String { Repository.localDayKey(Date()) }
    var body: some View {
        PersonalPage(title: "O MEU PLANO") {
            NavigationLink { PersonalAthleteScreen() } label: {
                PersonalWhoopCard { Label("DIÁRIO DE ATLETA E PLANO DE SONO", systemImage: "sportscourt").font(S.label) }
            }
            Text("Objetivos definidos por ti").font(S.heading)
            Text("O progresso usa apenas os registos disponíveis. Um valor em falta não significa zero; sincroniza a pulseira para atualizar.")
                .font(S.body).foregroundStyle(S.secondary)
            let day = repo.days.last { $0.day == today }
            goal("SONO DA ÚLTIMA NOITE", value: day?.totalSleepMin.map { $0 / 60 }, target: sleepHours, unit: "h")
            goal("PASSOS DE HOJE", value: day?.steps.map(Double.init), target: Double(steps), unit: "passos")
            let start = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
            let weekRows = repo.days.filter { $0.day >= Repository.localDayKey(start) && $0.day <= today }
            let counts = weekRows.compactMap(\.exerciseCount)
            goal("ATIVIDADES DESTA SEMANA", value: counts.isEmpty ? nil : Double(counts.reduce(0, +)), target: Double(activities), unit: "atividades")
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    Text("AJUSTAR OBJETIVOS").font(S.label)
                    Stepper("Sono: \(sleepHours, specifier: "%.1f") h", value: $sleepHours, in: 4...12, step: 0.5)
                    Stepper("Passos: \(steps)", value: $steps, in: 1000...30000, step: 500)
                    Stepper("Atividades por semana: \(activities)", value: $activities, in: 1...14)
                }.font(S.body)
            }
            NavigationLink { InsightsView() } label: { PersonalWhoopCard { Label("PREENCHER O DIÁRIO", systemImage: "book").font(S.label) } }
            NavigationLink { InsightsHubView() } label: { PersonalWhoopCard { Label("HÁBITOS E RESULTADOS", systemImage: "chart.bar").font(S.label) } }
            NavigationLink { SmartAlarmView() } label: { PersonalWhoopCard { Label("PREPARAR A PRÓXIMA NOITE", systemImage: "alarm").font(S.label) } }
        }.buttonStyle(.plain).refreshable { await repo.refresh() }
    }
    private func goal(_ title: String, value: Double?, target: Double, unit: String) -> some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.margin) {
                Text(title).font(S.label).foregroundStyle(S.secondary)
                if let value, value.isFinite, value >= 0, target.isFinite, target > 0 {
                    Text("\(value, specifier: unit == "h" ? "%.1f" : "%.0f") / \(target, specifier: unit == "h" ? "%.1f" : "%.0f") \(unit)").font(S.heading)
                    ProgressView(value: min(value / target, 1)).tint(value >= target ? S.green : S.effort)
                    Text(value >= target ? "Objetivo atingido" : "Em progresso").font(S.label)
                } else {
                    Text("SEM DADOS").font(S.heading)
                    Text("Ainda não há registos suficientes para mostrar progresso.").font(S.body).foregroundStyle(S.secondary)
                }
            }
        }
    }
}

/// A leaf observer isolates Bluetooth updates from the rest of the home dashboard.
struct PersonalSyncCard: View {
    @EnvironmentObject private var ble: BLEManager
    @EnvironmentObject private var live: LiveState
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.margin) {
                HStack {
                    Label(live.connected ? "PULSEIRA LIGADA" : "PULSEIRA DESLIGADA", systemImage: "applewatch")
                        .font(S.label)
                    Spacer()
                    Circle().fill(live.connected ? S.green : S.muted).frame(width: S.gap, height: S.gap)
                }
                if live.backfilling {
                    ProgressView("A sincronizar · \(live.syncChunksThisSession) blocos recebidos")
                } else if let last = live.lastSyncedAt {
                    Text("Última sincronização: \(Date(timeIntervalSince1970: last).formatted(date: .abbreviated, time: .shortened))")
                        .font(S.body).foregroundStyle(S.secondary)
                } else {
                    Text("Ainda sem sincronização concluída.").font(S.body).foregroundStyle(S.secondary)
                }
                if let error = live.lastSyncError, !error.isEmpty {
                    Text(error).font(S.body).foregroundStyle(S.red)
                }
                if live.connected && !live.historyReady {
                    Text("Ligação em preparação. O histórico ainda não está disponível para sincronizar.").font(S.label).foregroundStyle(S.secondary)
                }
                Button { ble.syncNow() } label: {
                    Label("SINCRONIZAR AGORA", systemImage: "arrow.triangle.2.circlepath").font(S.label)
                }.buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
                    .disabled(!live.historyReady || live.backfilling)
                if !live.connected {
                    NavigationLink("LIGAR PULSEIRA") { PersonalPairingScreen() }.font(S.label)
                }
            }
        }
    }
}
#endif
