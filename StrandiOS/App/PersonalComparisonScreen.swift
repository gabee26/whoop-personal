#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopStore

/// Separate raw source reads: dashboard merge precedence would contaminate a comparison.
struct PersonalComparisonScreen: View {
    @EnvironmentObject private var repo: Repository
    @State private var imported: [String: DailyMetric] = [:]
    @State private var computed: [String: DailyMetric] = [:]
    @State private var metric: Metric = .sleep
    @State private var loading = true
    @State private var loadID = UUID()
    @State private var error: String?
    @State private var showBackup = false
    private typealias S = PersonalWhoopStyle

    private enum Metric: String, CaseIterable, Identifiable {
        case sleep = "Tempo de sono", hrv = "VFC", rhr = "FC em repouso"
        case recovery = "Recuperação", effort = "Esforço"
        var id: String { rawValue }
        var unit: String {
            switch self {
            case .sleep: "min"
            case .hrv: "ms"
            case .rhr: "bpm"
            case .recovery: "pontos percentuais"
            case .effort: "pontos (0–21)"
            }
        }
        func value(_ row: DailyMetric) -> Double? {
            let value: Double?
            switch self {
            case .sleep: value = row.totalSleepMin
            case .hrv: value = row.avgHrv
            case .rhr: value = row.restingHr.map(Double.init)
            case .recovery: value = PersonalMetricScale.percentage(row.recovery)
            case .effort: value = PersonalMetricScale.effort(row.strain)
            }
            guard let value, value.isFinite, value >= 0 else { return nil }
            return value
        }
    }

    private func summary(for metric: Metric) -> PersonalComparisonSummary {
        PersonalComparisonSummary(reference: imported.compactMapValues { metric.value($0) },
                                  local: computed.compactMapValues { metric.value($0) })
    }
    private var result: PersonalComparisonSummary { summary(for: metric) }

    var body: some View {
        ZStack {
            S.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: S.section) {
                    PersonalWhoopCard {
                        VStack(alignment: .leading, spacing: S.gap) {
                            Text("IMPORTADO × CÁLCULO LOCAL").font(S.label).tracking(1)
                            Text("Compara o mesmo dia, sem misturar as duas fontes nem modificar os teus dados.")
                                .font(S.body).foregroundStyle(S.secondary)
                            Text("Usa uma exportação original da WHOOP como referência. Um ficheiro reexportado por esta aplicação pode conter cálculos locais e não é uma referência independente.")
                                .font(S.body).foregroundStyle(S.secondary)
                            Button("IMPORTAR OU GERIR HISTÓRICO") { showBackup = true }.font(S.label).tint(S.effort)
                        }
                    }
                    if loading {
                        ProgressView("A ler as duas fontes…").frame(maxWidth: .infinity)
                    } else if let error {
                        PersonalWhoopCard { Text(error).font(S.body).foregroundStyle(S.secondary) }
                        Button("TENTAR NOVAMENTE") { Task { await load() } }.font(S.label)
                    } else {
                        Picker("Indicador", selection: $metric) {
                            ForEach(Metric.allCases) { Text($0.rawValue).tag($0) }
                        }.pickerStyle(.menu).tint(S.text)
                        overview
                        if !result.pairs.isEmpty {
                            HStack {
                                Text("DIFERENÇAS POR DIA").font(S.label)
                                Spacer()
                                ShareLink(item: csv, preview: SharePreview("Comparação dos indicadores")) {
                                    Image(systemName: "square.and.arrow.up").font(S.icon)
                                }.accessibilityLabel("Partilhar comparação de todos os indicadores em CSV")
                            }
                            Text("Importado → Local · diferença em \(metric.unit)")
                                .font(S.label).foregroundStyle(S.secondary)
                            ForEach(result.pairs.reversed(), id: \.day) { pair in
                                PersonalWhoopCard {
                                    HStack {
                                        VStack(alignment: .leading, spacing: S.gap) {
                                            Text(pair.day).font(S.label)
                                            Text("\(number(pair.reference)) → \(number(pair.local))").font(S.body)
                                        }
                                        Spacer()
                                        Text(String(format: "%+.1f", pair.difference)).font(S.number).foregroundStyle(S.effort)
                                    }
                                }
                            }
                        }
                    }
                }.padding(S.margin).padding(.bottom, S.section)
            }.refreshable { await load() }
        }.foregroundStyle(S.text)
            .navigationTitle("COMPARAR INDICADORES")
            .navigationBarTitleDisplayMode(.inline)
            .task(id: repo.refreshSeq) { await load() }
            .sheet(isPresented: $showBackup) {
                NavigationStack {
                    PersonalImportScreen().toolbar {
                        ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { showBackup = false } }
                    }
                }
            }
    }

    private var overview: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.margin) {
                Text("\(result.pairs.count) dias comparáveis").font(S.heading)
                Text("Só importado: \(result.referenceOnly) · Só local: \(result.localOnly)")
                    .font(S.body).foregroundStyle(S.secondary)
                if let absolute = result.meanAbsoluteDifference, let bias = result.meanDifference {
                    Text("Diferença absoluta média: \(number(absolute)) \(metric.unit)").font(S.body)
                    Text("Desvio médio (local − importado): \(number(bias)) \(metric.unit)").font(S.body)
                    Text("Valores positivos significam que o cálculo local é maior. Uma diferença baixa não prova exatidão fisiológica. Confirma que os registos representam o mesmo ciclo ou noite.")
                        .font(S.body).foregroundStyle(S.secondary)
                } else {
                    Text("Ainda não há dias com este indicador nas duas fontes. Dias em falta não são tratados como zero.")
                        .font(S.body).foregroundStyle(S.secondary)
                }
            }
        }
    }

    private var csv: String {
        var lines = ["day,metric,unit,imported,local,local_minus_imported"]
        for item in Metric.allCases {
            for pair in summary(for: item).pairs {
                lines.append("\(pair.day),\(item.rawValue),\(item.unit),\(pair.reference),\(pair.local),\(pair.difference)")
            }
        }
        return lines.joined(separator: "\n")
    }
    private func number(_ value: Double) -> String { String(format: "%.1f", value) }

    @MainActor private func load() async {
        let requestID = UUID()
        loadID = requestID
        loading = true
        error = nil
        guard let store = await repo.storeHandle() else {
            guard !Task.isCancelled, loadID == requestID else { return }
            error = "Não foi possível abrir o histórico local."
            loading = false
            return
        }
        let importedIDs = repo.importedReadIds
        let computedIDs = repo.computedReadIds
        do {
            var a: [String: DailyMetric] = [:]
            var b: [String: DailyMetric] = [:]
            for id in importedIDs {
                for row in try await store.dailyMetrics(deviceId: id, from: "0000-01-01", to: "9999-12-31") where a[row.day] == nil {
                    a[row.day] = row
                }
            }
            for id in computedIDs {
                for row in try await store.dailyMetrics(deviceId: id, from: "0000-01-01", to: "9999-12-31") where b[row.day] == nil {
                    b[row.day] = row
                }
            }
            guard !Task.isCancelled, loadID == requestID else { return }
            imported = a
            computed = b
            loading = false
        } catch {
            guard !Task.isCancelled, loadID == requestID else { return }
            self.error = "Não foi possível ler as duas fontes. Tenta novamente."
            loading = false
        }
    }
}
#endif
