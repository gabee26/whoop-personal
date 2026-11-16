#if os(iOS)
import SwiftUI
import Charts
import StrandDesign

struct PersonalHealthHistory: View {
    @EnvironmentObject private var repo: Repository
    @State private var selected: Indicator = .hrv
    @State private var period = 30
    @State private var points: [(day: String, value: Double)] = []
    @State private var loading = false
    private typealias S = PersonalWhoopStyle

    private enum Indicator: String, CaseIterable, Identifiable {
        case hrv, rhr, respiration, oxygen, steps, calories
        var id: String { rawValue }
        var title: String {
            switch self {
            case .hrv: "VARIABILIDADE DA FREQUÊNCIA CARDÍACA"
            case .rhr: "FREQUÊNCIA CARDÍACA EM REPOUSO"
            case .respiration: "FREQUÊNCIA RESPIRATÓRIA"
            case .oxygen: "OXIGÉNIO NO SANGUE"
            case .steps: "PASSOS"
            case .calories: "CALORIAS ATIVAS ESTIMADAS"
            }
        }
        var key: String {
            switch self {
            case .hrv: "hrv"
            case .rhr: "rhr"
            case .respiration: "resp_rate"
            case .oxygen: "spo2"
            case .steps: "steps"
            case .calories: "active_kcal"
            }
        }
        var unit: String {
            switch self {
            case .hrv: "ms"
            case .rhr: "bpm"
            case .respiration: "/min"
            case .oxygen: "%"
            case .steps: "passos"
            case .calories: "kcal"
            }
        }
    }

    var body: some View {
        ZStack {
            S.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: S.section) {
                    Picker("Indicador", selection: $selected) {
                        ForEach(Indicator.allCases) { Text($0.title).tag($0) }
                    }.pickerStyle(.menu).tint(S.text)
                    Picker("Período", selection: $period) {
                        Text("7 dias").tag(7)
                        Text("30 dias").tag(30)
                        Text("90 dias").tag(90)
                    }.pickerStyle(.segmented)
                    PersonalWhoopCard {
                        VStack(alignment: .leading, spacing: S.margin) {
                            Text(selected.title).font(S.label).tracking(1)
                            if loading {
                                ProgressView().frame(maxWidth: .infinity, minHeight: S.detailChartHeight)
                            } else if let last = points.last {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(number(last.value)).font(S.number)
                                    Text(selected.unit).font(S.body).foregroundStyle(S.secondary)
                                }
                                Text("Último registo: \(last.day)").font(S.label).foregroundStyle(S.secondary)
                                Chart(points, id: \.day) { point in
                                    BarMark(x: .value("Dia", point.day), y: .value(selected.unit, point.value))
                                        .foregroundStyle(S.effort)
                                }.frame(height: S.detailChartHeight)
                            } else {
                                Text("SEM DADOS NESTE PERÍODO").font(S.label)
                                    .frame(maxWidth: .infinity, minHeight: S.detailChartHeight).foregroundStyle(S.muted)
                            }
                        }
                    }
                    Text("REGISTOS DIÁRIOS").font(S.label).tracking(1)
                    ForEach(points.reversed(), id: \.day) { point in
                        PersonalWhoopCard {
                            HStack {
                                Text(point.day).font(S.body)
                                Spacer()
                                Text("\(number(point.value)) \(selected.unit)").font(S.body).monospacedDigit()
                            }
                        }
                    }
                }.padding(S.margin).padding(.bottom, S.section)
            }.refreshable { await repo.refresh() }
        }.foregroundStyle(S.text)
            .navigationTitle("INDICADORES").navigationBarTitleDisplayMode(.inline)
            .task(id: "\(selected.rawValue)-\(period)-\(repo.refreshSeq)") {
                loading = true
                points = []
                let rows = await repo.exploreSeries(key: selected.key, source: Repository.whoopSource, days: period)
                guard !Task.isCancelled else { return }
                let calendar = Calendar.current
                let start = Repository.localDayKey(calendar.date(byAdding: .day, value: -(period - 1), to: Date()) ?? Date())
                let end = Repository.localDayKey(Date())
                points = rows.filter { $0.day >= start && $0.day <= end && $0.value.isFinite && $0.value >= 0 }
                    .sorted { $0.day < $1.day }
                loading = false
            }
    }
    private func number(_ value: Double) -> String {
        String(format: selected == .respiration ? "%.1f" : "%.0f", value)
    }
}
#endif
