#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import WhoopStore

private typealias W = PersonalWhoopStyle

private enum PersonalDestination: String, Identifiable {
    case sleep, recovery, effort, health, stress, activities, live, alarm, settings, metrics, plans, devices, backup, journal, intelligence, comparison, tools, sources, trends, athlete, fitness
    var id: String { rawValue }
}

private struct PersonalDetail: View {
    let destination: PersonalDestination
    var dayKey: String? = nil
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            content.toolbar {
                ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { dismiss() } }
            }
        }.preferredColorScheme(.dark)
    }
    @ViewBuilder private var content: some View {
        switch destination {
        case .sleep: PersonalMetricDetail(metric: .sleep, initialDayKey: dayKey)
        case .recovery: PersonalMetricDetail(metric: .recovery, initialDayKey: dayKey)
        case .effort: PersonalMetricDetail(metric: .effort, initialDayKey: dayKey)
        case .fitness: PersonalFitnessScreen()
        case .health: PersonalHealthHistory()
        case .stress: PersonalActivityStress(mode: .stress, initialDayKey: dayKey)
        case .activities: PersonalActivityStress(mode: .activities, initialDayKey: dayKey)
        case .live: PersonalLiveScreen()
        case .alarm: SmartAlarmView()
        case .settings: PersonalSettingsScreen()
        case .metrics: PersonalHealthHistory()
        case .plans: PersonalDailyPlan()
        case .athlete: PersonalAthleteScreen()
        case .devices: PersonalDeviceScreen()
        case .backup: BackupSyncView()
        case .journal: InsightsView()
        case .intelligence: IntelligenceView()
        case .comparison: PersonalComparisonScreen()
        case .tools: PersonalTrainingTools()
        case .sources: PersonalImportScreen()
        case .trends: TrendsView()
        }
    }
}

private struct PersonalDestinationPresentation: ViewModifier {
    @Binding var destination: PersonalDestination?
    var dayKey: String? = nil
    func body(content: Content) -> some View {
        content
            .sheet(item: Binding(get: { destination == .devices ? nil : destination }, set: { destination = $0 })) {
                PersonalDetail(destination: $0, dayKey: dayKey)
            }
            .navigationDestination(isPresented: Binding(get: { destination == .devices }, set: { if !$0 { destination = nil } })) {
                PersonalDeviceScreen()
            }
    }
}

struct PersonalWhoopHome: View {
    @EnvironmentObject private var ble: BLEManager
    @EnvironmentObject private var repo: Repository
    @AppStorage("personal.dashboard.hrv") private var showHRV = true
    @AppStorage("personal.dashboard.rhr") private var showRHR = true
    @AppStorage("personal.dashboard.steps") private var showSteps = true
    @AppStorage("personal.dashboard.calories") private var showCalories = true
    @State private var selectedMetric: MetricDescriptor?
    @State private var customize = false
    @State private var offset = 0
    @State private var rest: Double?
    @State private var stressSeries: [(day: String, value: Double)] = []
    @State private var destination: PersonalDestination?
    private var dayKey: String {
        if offset == 0 { return repo.today?.day ?? Repository.localDayKey(Date()) }
        let anchor = dateFormatter.date(from: repo.today?.day ?? "") ?? Date()
        return dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -offset, to: anchor) ?? anchor)
    }
    private var dateFormatter: DateFormatter {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }
    private var day: DailyMetric? {
        offset == 0 ? repo.today : repo.days.last { $0.day == dayKey }
    }
    var body: some View {
        ZStack {
            W.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: W.section, pinnedViews: [.sectionHeaders]) {
                    Section {
                        PersonalSyncCard()
                        Text("WHOOP").font(W.wordmark).tracking(3).frame(maxWidth: .infinity)
                        HStack(spacing: W.margin) {
                            Button { destination = .sleep } label: { PersonalWhoopRing("SONO", value: rest, color: W.sleep).frame(maxWidth: W.homeRingSize) }.frame(maxWidth: .infinity)
                            Button { destination = .recovery } label: { PersonalWhoopRing("RECUPERAÇÃO", value: PersonalMetricScale.percentage(day?.recovery), color: W.recovery(day?.recovery)).frame(maxWidth: W.homeRingSize) }.frame(maxWidth: .infinity)
                            Button { destination = .effort } label: { PersonalWhoopRing("ESFORÇO", value: PersonalMetricScale.effort(day?.strain), maximum: 21, color: W.effort).frame(maxWidth: W.homeRingSize) }.frame(maxWidth: .infinity)
                        }.padding(.vertical, W.gap)
                        PersonalWhoopCard {
                            VStack(alignment: .leading, spacing: W.gap) {
                                Text(offset == 0 ? "O teu dia, num só lugar." : "O teu histórico").font(W.body)
                                Text(day == nil ? "Sincroniza a pulseira ou importa o teu histórico para veres os teus dados." : "Consulta o sono, a recuperação e o esforço deste dia. Os indicadores são calculados localmente.")
                                    .font(W.body).foregroundStyle(W.secondary)
                            }
                        }
                        HStack(spacing: W.gap) {
                            monitor("MONITOR\nDE SAÚDE", .health, hasData: day?.avgHrv != nil || day?.restingHr != nil)
                            monitor("MONITOR\nDE STRESS", .stress, hasData: false)
                        }
                        HStack {
                            Text("O meu dia").font(W.heading)
                            Spacer()
                            Button { destination = .activities } label: { Image(systemName: "plus.app.fill").font(W.number) }
                        }
                        PersonalWhoopCard {
                            VStack(alignment: .leading, spacing: W.section) {
                                caption("ATIVIDADES DO DIA")
                                if let count = day?.exerciseCount, count > 0 {
                                    Text("\(count) atividade(s) registada(s)").font(W.body)
                                }
                                HStack(spacing: W.gap) {
                                    action("ADICIONAR\nATIVIDADE", "plus", .activities)
                                    action("INICIAR\nATIVIDADE", "stopwatch", .live)
                                }
                            }
                        }
                        PersonalWhoopCard {
                            VStack(alignment: .leading, spacing: W.section) {
                                caption("SONO DESTA NOITE")
                                Text("Consulta a tua necessidade de sono e define o alarme.").font(W.body).foregroundStyle(W.secondary)
                                action("DEFINIR ALARME", "alarm", .alarm)
                            }
                        }
                        Button { destination = .athlete } label: {
                            PersonalWhoopCard {
                                VStack(alignment: .leading, spacing: W.gap) {
                                    Label("O MEU DIA DE ATLETA", systemImage: "sportscourt").font(W.heading)
                                    Text("Check-in, sono, treinos e recuperação numa visão pessoal.").font(W.body).foregroundStyle(W.secondary)
                                    Text("ABRIR DIÁRIO DE ATLETA →").font(W.label).foregroundStyle(W.effort)
                                }
                            }
                        }
                        Text("O meu plano").font(W.heading)
                        Button { destination = .plans } label: {
                            PersonalWhoopCard {
                                VStack(alignment: .leading, spacing: W.gap) {
                                    Text("Dá o melhor de ti").font(W.heading)
                                    Text("Define os teus objetivos e acompanha o progresso nos teus registos.").font(W.body).foregroundStyle(W.secondary)
                                    Text("VER OBJETIVOS  →").font(W.label).tracking(1).foregroundStyle(W.effort)
                                }
                            }
                        }
                        HStack {
                            Text("O Meu Painel").font(W.heading)
                            Spacer()
                            Button("PERSONALIZAR") { customize = true }.font(W.label).foregroundStyle(W.effort)
                        }
                        Button { destination = .fitness } label: {
                            PersonalWhoopCard {
                                HStack(spacing: W.gap) {
                                    Image(systemName: "figure.run").font(W.icon).foregroundStyle(W.purple)
                                    VStack(alignment: .leading, spacing: W.gap) {
                                        Text("IDADE DE CONDIÇÃO FÍSICA / VO₂ MÁX.").font(W.label)
                                        Text("Estimativas locais e evolução").font(W.body).foregroundStyle(W.secondary)
                                    }
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        if showHRV { metric("VARIABILIDADE DA FREQUÊNCIA CARDÍACA", "waveform.path.ecg", formatted(day?.avgHrv, unit: " ms"), key: "hrv") }
                        if showRHR { metric("FREQUÊNCIA CARDÍACA EM REPOUSO", "heart", day?.restingHr.map { "\($0) bpm" } ?? "--", key: "rhr") }
                        if showSteps { metric("PASSOS", "shoeprints.fill", day?.steps.map { String($0) } ?? "--", key: "steps") }
                        if showCalories { metric("CALORIAS DO DIA ESTIMADAS", "flame", formatted(day?.activeKcalEst, unit: " kcal"), key: "energy_kcal") }
                        Button { destination = .stress } label: {
                            PersonalWhoopCard {
                                VStack(alignment: .leading, spacing: W.margin) {
                                    caption("MONITOR DE STRESS")
                                    PersonalStressGauge(value: stressValue)
                                    Text("RESUMO DO DIA · ESTIMATIVA LOCAL").font(W.label).foregroundStyle(W.secondary)
                                    Text("VER HISTÓRICO E ANÁLISE  ›").font(W.label)
                                }
                            }
                        }
                        weeklyChart
                    } header: {
                        header.padding(.vertical, W.gap).background(W.top)
                    }
                }.padding(.horizontal, W.margin).padding(.bottom, W.dockHeight + W.section)
            }.refreshable {
                if ble.state.historyReady { ble.syncNow() }
                await repo.refresh()
            }
        }.foregroundStyle(W.text).buttonStyle(.plain)
            .modifier(PersonalDestinationPresentation(destination: $destination, dayKey: dayKey))
            .sheet(item: $selectedMetric) { metric in
                NavigationStack {
                    PersonalSeriesDetail(metric: metric)
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { selectedMetric = nil } } }
                }.preferredColorScheme(.dark)
            }
            .sheet(isPresented: $customize) {
                NavigationStack {
                    Form {
                        Toggle("Variabilidade da frequência cardíaca", isOn: $showHRV)
                        Toggle("Frequência cardíaca em repouso", isOn: $showRHR)
                        Toggle("Passos", isOn: $showSteps)
                        Toggle("Calorias do dia estimadas", isOn: $showCalories)
                    }.scrollContentBackground(.hidden).background(W.background)
                        .navigationTitle("O Meu Painel")
                        .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Concluído") { customize = false } } }
                }.preferredColorScheme(.dark)
            }
            .task(id: "\(dayKey)-\(repo.refreshSeq)") {
                rest = nil
                stressSeries = []
                let key = dayKey
                let points = await repo.exploreSeries(key: "sleep_performance", source: Repository.whoopSource)
                let stressRows = await repo.exploreSeries(key: "stress", source: Repository.whoopSource)
                guard !Task.isCancelled, key == dayKey else { return }
                stressSeries = stressRows.filter { $0.value.isFinite && (0...3).contains($0.value) && $0.day <= key }
                rest = PersonalMetricScale.percentage(points.last(where: { $0.day == key })?.value)
            }
    }
    private var stressValue: Double? {
        PersonalStressSummary.value(day: dayKey, days: repo.days, stored: stressSeries)
    }
    private var header: some View {
        HStack {
            Button { destination = .settings } label: { Image(systemName: "person.crop.circle").font(W.number) }.accessibilityLabel("Perfil")
            Spacer()
            HStack(spacing: W.margin) {
                Button { offset += 1 } label: { Image(systemName: "chevron.left").frame(minWidth: W.touchTarget, minHeight: W.touchTarget) }.accessibilityLabel("Dia anterior")
                Text(offset == 0 ? "HOJE" : dayKey).font(W.label).tracking(1)
                Button { offset = max(0, offset - 1) } label: { Image(systemName: "chevron.right").frame(minWidth: W.touchTarget, minHeight: W.touchTarget) }.disabled(offset == 0).accessibilityLabel("Dia seguinte")
            }.padding(W.gap).background(W.track.opacity(0.5), in: Capsule())
            Spacer()
            Button { destination = .devices } label: { PersonalStrapBadge() }
        }
    }
    private func caption(_ title: String) -> some View { Text(title).font(W.label).tracking(1.3) }
    private func monitor(_ title: String, _ route: PersonalDestination, hasData: Bool) -> some View {
        Button { destination = route } label: {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: W.section) {
                    HStack(alignment: .top) { caption(title); Spacer(minLength: 0); Image(systemName: "chevron.right").foregroundStyle(W.muted) }
                    Text(hasData ? "Consultar indicadores" : (route == .stress ? "Consultar histórico" : "Sem dados disponíveis"))
                        .font(W.body).foregroundStyle(W.secondary)
                }.frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            }
        }
    }
    private func action(_ title: String, _ icon: String, _ route: PersonalDestination) -> some View {
        Button { destination = route } label: {
            Label(title, systemImage: icon).font(W.label).tracking(1).frame(maxWidth: .infinity, minHeight: W.touchTarget)
                .padding(W.gap).background(W.track, in: RoundedRectangle(cornerRadius: W.radius))
        }
    }
    private func metric(_ title: String, _ icon: String, _ value: String, key: String) -> some View {
        Button { selectedMetric = MetricCatalog.metric(key: key, source: Repository.whoopSource) } label: {
            PersonalWhoopCard {
                HStack(spacing: W.gap) {
                    Image(systemName: icon).font(W.icon).foregroundStyle(W.muted)
                    caption(title)
                    Spacer(minLength: 0)
                    Text(value).font(W.label).foregroundStyle(W.secondary)
                    Image(systemName: "chevron.right")
                }.frame(minHeight: 32)
            }
        }
    }
    private var weeklyChart: some View {
        let end = dateFormatter.date(from: dayKey) ?? Date()
        let start = dateFormatter.string(from: Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end)
        let rows = repo.days.filter { $0.day >= start && $0.day <= dayKey }.sorted { $0.day < $1.day }
        return PersonalWhoopCard {
            VStack(alignment: .leading, spacing: W.margin) {
                caption("ESFORÇO E RECUPERAÇÃO")
                if rows.contains(where: { PersonalMetricScale.percentage($0.recovery) != nil || PersonalMetricScale.percentage($0.strain) != nil }) {
                    Chart {
                        ForEach(rows, id: \.day) { row in
                            if let strain = PersonalMetricScale.percentage(row.strain) {
                                LineMark(x: .value("Dia", row.day), y: .value("% da escala", strain), series: .value("Indicador", "Esforço"))
                                    .foregroundStyle(W.effort)
                            }
                            if let recovery = PersonalMetricScale.percentage(row.recovery) {
                                PointMark(x: .value("Dia", row.day), y: .value("Recuperação", recovery)).foregroundStyle(W.recovery(recovery))
                            }
                        }
                    }.chartYScale(domain: 0...100).frame(height: W.detailChartHeight)
                    Text("Azul: esforço (0–21 convertido para % da escala). Pontos: recuperação (%).")
                        .font(W.label).foregroundStyle(W.secondary)
                } else {
                    Text("SEM DADOS").font(W.label).frame(maxWidth: .infinity, minHeight: W.detailChartHeight).foregroundStyle(W.secondary)
                }
            }
        }
    }
}

private func formatted(_ value: Double?, unit: String = "", decimals: Int = 0) -> String {
    guard let value, value.isFinite else { return "--" }
    return String(format: "%.*f", decimals, value) + unit
}

private struct PersonalStrapBadge: View {
    @EnvironmentObject private var live: LiveState
    var body: some View {
        HStack(spacing: 4) {
            Text(formatted(live.batteryPct, unit: "%")).font(W.label).foregroundStyle(W.secondary)
            Image(systemName: "applewatch").font(W.icon)
                .overlay(alignment: .topTrailing) { Circle().fill(live.connected ? (live.historyReady && live.lastSyncError == nil && !live.historySyncExperimental ? W.green : W.yellow) : W.muted).frame(width: 6, height: 6) }
        }.accessibilityLabel(live.connected ? "Pulseira ligada" : "Pulseira desligada")
    }
}

struct PersonalWhoopHealth: View {
    @EnvironmentObject private var repo: Repository
    @State private var destination: PersonalDestination?
    var body: some View {
        ZStack {
            W.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: W.section) {
                    Text("SAÚDE").font(W.label).tracking(2).frame(maxWidth: .infinity).padding(.vertical, W.section)
                    Button { destination = .fitness } label: {
                        PersonalWhoopCard {
                            HStack {
                                VStack(alignment: .leading, spacing: W.gap) {
                                    Text("CONDIÇÃO FÍSICA").font(W.label)
                                    Text("Idade estimada e VO₂ máx.").font(W.heading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                            }
                        }
                    }
                    Button { destination = .live } label: {
                        VStack(alignment: .leading, spacing: W.gap) {
                            PersonalHeartRate()
                            HStack {
                                Text("ABRIR MONITORIZAÇÃO EM DIRETO").font(W.label)
                                Spacer()
                                Image(systemName: "chevron.right")
                            }.foregroundStyle(W.effort)
                        }
                    }
                    Button { destination = .health } label: {
                        PersonalWhoopCard {
                            VStack(alignment: .leading, spacing: W.section) {
                                HStack { Text("MONITOR DE SAÚDE"); Spacer(); Image(systemName: "chevron.right") }.font(W.label)
                                HStack(spacing: 0) {
                                    vital("FR", "lungs", formatted(repo.today?.respRateBpm, unit: " /min", decimals: 1))
                                    vital("SpO₂", "drop", formatted(repo.today?.spo2Pct, unit: "%"))
                                    vital("FCR", "heart", repo.today?.restingHr.map(String.init) ?? "--")
                                    vital("VFC", "waveform.path.ecg", formatted(repo.today?.avgHrv, unit: " ms"))
                                    vital("TEMP.", "thermometer", formatted(repo.today?.skinTempC, unit: " °C", decimals: 1))
                                }
                                Text("Valores disponíveis na última noite registada. Toca para ver origem e detalhes.")
                                    .font(W.body).foregroundStyle(W.secondary)
                            }
                        }
                    }
                    Button { destination = .stress } label: {
                        PersonalWhoopCard {
                            VStack(alignment: .leading, spacing: W.section) {
                                Text("MONITOR DE STRESS").font(W.label).tracking(1)
                                HStack { Image(systemName: "waveform.path.ecg").font(W.number); Spacer(); Image(systemName: "chevron.right") }
                                Text("Consultar o histórico e a cobertura de dados").font(W.body).foregroundStyle(W.secondary)
                            }
                        }
                    }
                }.padding(W.margin).padding(.bottom, W.dockHeight + W.section)
            }
        }.foregroundStyle(W.text).buttonStyle(.plain)
            .modifier(PersonalDestinationPresentation(destination: $destination))
    }
    private func vital(_ title: String, _ icon: String, _ value: String) -> some View {
        VStack(spacing: W.gap) {
            Image(systemName: icon).font(W.icon).foregroundStyle(W.muted)
            Text(title).font(W.label)
            Text(value).font(W.label).foregroundStyle(W.secondary).lineLimit(1).minimumScaleFactor(0.65)
        }.frame(maxWidth: .infinity)
    }
}

private struct PersonalHeartRate: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.scenePhase) private var scenePhase
    @State private var visible = false
    @State private var ownsStream = false
    @EnvironmentObject private var live: LiveState
    var body: some View {
        VStack(alignment: .leading, spacing: W.gap) {
            Text("FREQUÊNCIA CARDÍACA").font(W.label).tracking(1.2)
            Image(systemName: "waveform.path.ecg").font(W.icon).foregroundStyle(W.muted)
            Text(PersonalConnectionPresentation.heartRate(connected: live.connected, bpm: live.heartRate).map(String.init) ?? "--").font(W.number)
            Text("BPM").font(W.label).foregroundStyle(W.secondary)
            Text(live.connected ? (live.heartRate != nil ? "A receber dados da pulseira" : "À espera de medições") : "Dispositivo desconectado")
                .font(W.body).foregroundStyle(W.secondary)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, W.section)
            .onAppear { visible = true; reconcileStream() }
            .onDisappear { visible = false; reconcileStream() }
            .onChange(of: scenePhase) { _, _ in reconcileStream() }
            .onChange(of: live.connected) { _, _ in reconcileStream(rearm: true) }
            .onChange(of: live.bonded) { _, _ in reconcileStream(rearm: true) }
            .onChange(of: live.backfilling) { _, _ in reconcileStream() }
    }
    private func reconcileStream(rearm: Bool = false) {
        let wanted = PersonalConnectionPresentation.wantsLive(visible: visible,
            active: scenePhase == .active, connected: live.connected, backfilling: live.backfilling)
        if wanted && !ownsStream { model.startRealtimeHR(); ownsStream = true }
        else if !wanted && ownsStream { model.stopRealtimeHR(); ownsStream = false }
        else if wanted && rearm { model.rearmRealtimeIfWanted() }
    }
}

struct PersonalHumansScreen: View {
    var body: some View {
        ZStack {
            W.background.ignoresSafeArea()
            VStack(spacing: W.section) {
                Image(systemName: "person.3").font(W.number)
                Text("Humans").font(W.heading)
                Text("Esta versão é pessoal e local. Não está ligada à comunidade nem às equipas da WHOOP.")
                    .font(W.body).foregroundStyle(W.secondary).multilineTextAlignment(.center)
            }.padding(W.section)
        }.foregroundStyle(W.text)
    }
}

struct PersonalWhoopMore: View {
    @State private var destination: PersonalDestination?
    var body: some View {
        ZStack {
            W.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: W.gap) {
                    Text("MAIS").font(W.label).tracking(2).frame(maxWidth: .infinity).padding(.vertical, W.section)
                    row("DISPOSITIVO WHOOP", "applewatch", .devices)
                    row("PERFIL E DEFINIÇÕES", "person.crop.circle", .settings)
                    row("SONO", "moon", .sleep)
                    row("ATIVIDADES", "figure.run", .activities)
                    row("DIÁRIO", "book", .journal)
                    row("ALARME", "alarm", .alarm)
                    row("TENDÊNCIAS", "chart.xyaxis.line", .trends)
                    row("INDICADORES", "waveform.path.ecg", .metrics)
                    row("COMPARAR INDICADORES", "chart.bar.xaxis", .comparison)
                    row("DIÁRIO DE ATLETA", "sportscourt", .athlete)
                    row("INSIGHTS", "sparkles", .intelligence)
                    row("IMPORTAR HISTÓRICO", "square.and.arrow.down", .sources)
                    row("CÓPIAS DE SEGURANÇA", "externaldrive", .backup)
                    row("TREINO E FERRAMENTAS", "dumbbell", .tools)
                    Text("WHOOP · versão pessoal independente. Indicadores calculados no dispositivo.")
                        .font(W.label).foregroundStyle(W.muted).padding(.vertical, W.section)
                }.padding(W.margin).padding(.bottom, W.dockHeight + W.section)
            }
        }.foregroundStyle(W.text).buttonStyle(.plain)
            .modifier(PersonalDestinationPresentation(destination: $destination))
    }
    private func row(_ title: String, _ icon: String, _ route: PersonalDestination) -> some View {
        Button { destination = route } label: {
            PersonalWhoopCard {
                HStack(spacing: W.margin) {
                    Image(systemName: icon).font(W.icon).foregroundStyle(W.secondary)
                    Text(title).font(W.label).tracking(1)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(W.secondary)
                }.padding(.vertical, W.gap)
            }
        }
    }
}
#endif
