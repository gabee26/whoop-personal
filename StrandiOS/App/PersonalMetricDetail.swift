#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import WhoopStore

/// Presentation only: all scores come from the existing repository, without new formulas.
struct PersonalMetricDetail: View {
    enum Metric: String {
        case sleep = "SONO", recovery = "RECUPERAÇÃO", effort = "ESFORÇO"
        var maximum: Double { self == .effort ? 21 : 100 }
    }
    let metric: Metric
    let initialDayKey: String?
    @EnvironmentObject private var repo: Repository
    @State private var selectedKey = ""
    @State private var sleepPoints: [String: Double] = [:]
    @State private var historyDays = 7
    private typealias S = PersonalWhoopStyle

    private var dayKey: String { selectedKey.isEmpty ? (initialDayKey ?? repo.today?.day ?? Repository.localDayKey(Date())) : selectedKey }
    private var row: DailyMetric? { repo.days.last { $0.day == dayKey } }
    private var accent: Color {
        switch metric {
        case .sleep: S.sleep
        case .recovery: S.recovery(row?.recovery)
        case .effort: S.effort
        }
    }
    private func value(_ day: DailyMetric?) -> Double? {
        switch metric {
        case .sleep: PersonalMetricScale.percentage(day.flatMap { sleepPoints[$0.day] })
        case .recovery: PersonalMetricScale.percentage(day?.recovery)
        case .effort: PersonalMetricScale.effort(day?.strain)
        }
    }
    private var selectedValue: Double? {
        metric == .sleep ? PersonalMetricScale.percentage(sleepPoints[dayKey]) : value(row)
    }
    private var historyPoints: [(day: String, value: Double)] {
        if metric == .sleep {
            let end = formatter.date(from: dayKey) ?? Date()
            let start = formatter.string(from: Calendar.current.date(byAdding: .day, value: -(historyDays - 1), to: end) ?? end)
            return sleepPoints.compactMap { key, score in
                guard key >= start, key <= dayKey, let valid = PersonalMetricScale.percentage(score) else { return nil }
                return (day: key, value: valid)
            }.sorted { $0.day < $1.day }
        }
        return week.compactMap { day in value(day).map { (day: day.day, value: $0) } }
    }
    private var explanation: String {
        switch metric {
        case .sleep:
            "O score local combina duração, eficiência, sono reparador e regularidade. Não é apenas a percentagem da necessidade de sono cumprida. O histórico também pode incluir valores importados; os valores apresentados seguem a prioridade das fontes do teu histórico."
        case .recovery:
            "O cálculo local compara indicadores como VFC e frequência cardíaca em repouso com a tua referência pessoal. Dados em falta e uma referência ainda curta limitam a interpretação. O histórico pode incluir valores importados."
        case .effort:
            "O esforço local é calculado a partir da carga cardiovascular. Aqui convertemos a escala NOOP de 0–100 para 0–21, sem alterar o histórico. Esta conversão não torna o algoritmo igual ao da WHOOP."
        }
    }
    private var formatter: DateFormatter {
        let f = DateFormatter(); f.locale = Locale(identifier: "en_US_POSIX"); f.dateFormat = "yyyy-MM-dd"; return f
    }
    private var week: [DailyMetric] {
        let end = formatter.date(from: dayKey) ?? Date()
        let start = formatter.string(from: Calendar.current.date(byAdding: .day, value: -(historyDays - 1), to: end) ?? end)
        return repo.days.filter { $0.day >= start && $0.day <= dayKey }.sorted { $0.day < $1.day }
    }

    var body: some View {
        ZStack {
            S.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: S.section) {
                    dateSelector
                    PersonalWhoopRing(metric.rawValue, value: selectedValue, maximum: metric.maximum, color: accent)
                        .frame(width: S.detailRingSize).frame(maxWidth: .infinity)
                    Text(selectedValue == nil ? "Sem dados para este dia" : "Indicador do histórico local")
                        .font(S.body).foregroundStyle(S.secondary).frame(maxWidth: .infinity)
                    details
                    history
                    PersonalWhoopCard {
                        VStack(alignment: .leading, spacing: S.gap) {
                            Text("SOBRE ESTE INDICADOR").font(S.label).tracking(1)
                            Text(explanation)
                                .font(S.body).foregroundStyle(S.secondary)
                        }
                    }

                }.padding(S.margin).padding(.bottom, S.section)
            }.refreshable { await repo.refresh() }
        }.foregroundStyle(S.text).buttonStyle(.plain)
            .navigationTitle(metric.rawValue).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task(id: repo.refreshSeq) {
                guard metric == .sleep else { return }
                let points = await repo.exploreSeries(key: "sleep_performance", source: Repository.whoopSource)
                guard !Task.isCancelled else { return }
                sleepPoints = Dictionary(points.map { ($0.day, $0.value) }, uniquingKeysWith: { _, last in last })
            }
    }

    private var dateSelector: some View {
        HStack {
            Button { move(-1) } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Dia anterior")
            Spacer()
            Text(dayKey).font(S.label).tracking(1)
            Spacer()
            Button { move(1) } label: { Image(systemName: "chevron.right") }
                .disabled(dayKey >= Repository.localDayKey(Date())).accessibilityLabel("Dia seguinte")
        }.padding(S.margin).background(S.track.opacity(0.5), in: Capsule())
    }
    private func move(_ delta: Int) {
        guard let date = formatter.date(from: dayKey), let next = Calendar.current.date(byAdding: .day, value: delta, to: date) else { return }
        selectedKey = formatter.string(from: next)
    }
    @ViewBuilder private var details: some View {
        switch metric {
        case .sleep:
            metricRow("TEMPO DE SONO", duration(row?.totalSleepMin), "moon")
            metricRow("EFICIÊNCIA DO SONO", number(PersonalMetricScale.percentage(row?.efficiency.map { $0 * 100 }), "%"), "bed.double")
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.margin) {
                    Text("COMPOSIÇÃO DO SONO").font(S.label).tracking(1)
                    stage("Profundo", row?.deepMin, S.purple)
                    stage("REM", row?.remMin, S.sleep)
                    stage("Leve", row?.lightMin, S.secondary)
                    Text("Durações registadas; não representam uma cronologia das fases. A classificação local é uma estimativa.")
                        .font(S.label).foregroundStyle(S.muted)
                }
            }
            metricRow("PERTURBAÇÕES", row?.disturbances.map(String.init) ?? "--", "waveform")
        case .recovery:
            metricRow("VARIABILIDADE DA FREQUÊNCIA CARDÍACA", number(row?.avgHrv, " ms"), "waveform.path.ecg")
            metricRow("FREQUÊNCIA CARDÍACA EM REPOUSO", row?.restingHr.map { "\($0) bpm" } ?? "--", "heart")
            metricRow("FREQUÊNCIA RESPIRATÓRIA", number(row?.respRateBpm, " /min", decimals: 1), "lungs")
            metricRow("TEMPO DE SONO", duration(row?.totalSleepMin), "moon")
        case .effort:
            metricRow("ATIVIDADES", row?.exerciseCount.map(String.init) ?? "--", "figure.run")
            metricRow("PASSOS", row?.steps.map(String.init) ?? "--", "shoeprints.fill")
            metricRow("CALORIAS DO DIA ESTIMADAS", number(row?.activeKcalEst, " kcal"), "flame")
        }
    }
    private func metricRow(_ title: String, _ value: String, _ icon: String) -> some View {
        PersonalWhoopCard {
            HStack(spacing: S.margin) {
                Image(systemName: icon).font(S.icon).foregroundStyle(S.secondary)
                Text(title).font(S.label).tracking(1)
                Spacer(minLength: S.gap)
                Text(value).font(S.body).monospacedDigit()
            }
        }
    }
    private func stage(_ title: String, _ minutes: Double?, _ color: Color) -> some View {
        VStack(spacing: S.gap) {
            HStack { Text(title); Spacer(); Text(duration(minutes)) }.font(S.body)
            if let minutes, minutes.isFinite, let total = row?.totalSleepMin, total > 0 {
                ProgressView(value: min(1, max(0, minutes / total))).tint(color)
            }
        }
    }
    private var history: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.margin) {
                Picker("Período", selection: $historyDays) {
                    Text("7 dias").tag(7)
                    Text("30 dias").tag(30)
                    Text("90 dias").tag(90)
                }.pickerStyle(.segmented)
                if !historyPoints.isEmpty {
                    Chart {
                        ForEach(historyPoints, id: \.day) { point in
                            let score = point.value
                            if score.isFinite {
                                BarMark(x: .value("Dia", String(point.day.suffix(5))), y: .value(metric.rawValue, score))
                                    .foregroundStyle(metric == .recovery ? S.recovery(score) : accent)
                            }
                        }
                    }.chartYScale(domain: 0...metric.maximum).frame(height: S.detailChartHeight)
                } else {
                    Text("SEM DADOS").font(S.label).foregroundStyle(S.muted)
                        .frame(maxWidth: .infinity, minHeight: S.detailChartHeight)
                }
            }
        }
    }
    private func number(_ value: Double?, _ suffix: String, decimals: Int = 0) -> String {
        guard let value, value.isFinite else { return "--" }
        return String(format: "%.*f", decimals, value) + suffix
    }
    private func duration(_ minutes: Double?) -> String {
        guard let minutes, minutes.isFinite, minutes >= 0 else { return "--" }
        let total = Int(minutes.rounded())
        return "\(total / 60) h \(total % 60) min"
    }
}
#endif
