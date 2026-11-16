#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import WhoopStore

/// Reads the existing weekly engine and its persisted estimator provenance; no parallel formulas.
struct PersonalFitnessScreen: View {
    @EnvironmentObject private var repo: Repository
    @EnvironmentObject private var profile: ProfileStore
    @EnvironmentObject private var intelligence: IntelligenceEngine
    @State private var age: [(day: String, value: Double)] = []
    @State private var oxygen: [(day: String, value: Double)] = []
    @State private var method = "Origem do método não registada"
    @State private var loading = true
    @State private var refreshing = false
    @State private var message: String?
    private typealias S = PersonalWhoopStyle

    var body: some View {
        PersonalPage(title: "CONDIÇÃO FÍSICA") {
            Text("Idade de condição física e VO₂ máx.").font(S.heading)
            Text("Estimativas locais · não são a Idade WHOOP oficial").font(S.body).foregroundStyle(S.secondary)
            if profile.age < 18 {
                PersonalWhoopCard {
                    Text("O modelo local de adultos não foi validado para menores de 18 anos. Não apresentamos uma idade de condição física nem um VO₂ máx. calculados por esse modelo para este perfil.")
                        .font(S.body).foregroundStyle(S.secondary)
                }
            } else if loading {
                ProgressView("A ler os indicadores…")
            } else {
                metricCard("IDADE DE CONDIÇÃO FÍSICA", unit: "anos", points: age, accent: S.purple)
                metricCard("VO₂ MÁX. ESTIMADO", unit: "ml/kg/min", points: oxygen, accent: S.effort)
                Text(method).font(S.label).foregroundStyle(S.secondary)
                Text("A idade é uma comparação de condição física com uma referência do modelo, não uma idade biológica. O VO₂ máx. é estimado e não substitui uma medição de laboratório.")
                    .font(S.body).foregroundStyle(S.secondary)
                Button {
                    refreshing = true
                    Task {
                        let written = await intelligence.recomputeFitnessAgeOnly()
                        guard !Task.isCancelled else { refreshing = false; return }
                        await load()
                        message = written ? "Cálculo concluído. Confirma a data dos resultados apresentados." : "Ainda não há dados suficientes. Confirma o perfil e sincroniza mais noites."
                        refreshing = false
                    }
                } label: {
                    HStack {
                        if refreshing { ProgressView() }
                        Label("ATUALIZAR CÁLCULO", systemImage: "arrow.clockwise")
                    }.font(S.label).frame(minHeight: S.touchTarget)
                }.disabled(refreshing).tint(S.effort)
                if let message { Text(message).font(S.body).foregroundStyle(S.secondary) }
            }
            NavigationLink { PersonalProfileScreen() } label: {
                PersonalWhoopCard { Label("COMPLETAR PERFIL", systemImage: "person.crop.circle").font(S.label) }
            }
            NavigationLink { PersonalMetricGuide() } label: {
                Label("COMO SÃO CALCULADOS", systemImage: "info.circle").font(S.label)
            }
        }.task(id: "\(repo.refreshSeq)-\(profile.age)-\(profile.waistCm)") { await load() }
    }

    private func metricCard(_ title: String, unit: String, points: [(day: String, value: Double)], accent: Color) -> some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.margin) {
                Text(title).font(S.label).tracking(1)
                HStack(alignment: .firstTextBaseline) {
                    Text(points.last.map { String(format: "%.1f", $0.value) } ?? "—").font(S.number).foregroundStyle(accent)
                    Text(unit).font(S.body).foregroundStyle(S.secondary)
                }
                if let latest = points.last {
                    Text("Último cálculo: \(latest.day)").font(S.label).foregroundStyle(S.secondary)
                    Chart(points, id: \.day) { point in
                        BarMark(x: .value("Data", point.day), y: .value(unit, point.value)).foregroundStyle(accent)
                    }.frame(height: S.detailChartHeight)
                } else {
                    Text("A aguardar perfil e histórico suficientes. Sincroniza a pulseira e atualiza o cálculo.").font(S.body).foregroundStyle(S.secondary)
                }
            }
        }
    }

    @MainActor private func load() async {
        loading = true
        age = []; oxygen = []; method = "Origem do método não registada"
        guard profile.age >= 18 else { loading = false; return }
        let ages = await repo.exploreSeries(key: "fitness_age", source: Repository.whoopSource, days: 365)
        let resolved = await repo.resolvedSeries(key: "vo2max_est", source: Repository.whoopSource)
        guard !Task.isCancelled else { return }
        let today = Repository.localDayKey(Date())
        age = ages.filter { $0.value.isFinite && $0.value > 0 && $0.day <= today }.sorted { $0.day < $1.day }
        let valid = resolved.points.filter { $0.value.isFinite && $0.value > 0 && $0.day <= today }.sorted { $0.day < $1.day }
        oxygen = valid.map { (day: $0.day, value: $0.value) }
        if let latest = valid.last {
            let tag = await repo.scoreProvenanceTag(resolvedSource: latest.source, day: latest.day, metricKey: "vo2max_est")
            guard !Task.isCancelled else { return }
            method = "Método: " + vo2MaxEstimatorDisplayName(tag.flatMap { Vo2MaxEstimator(rawValue: $0) })
        }
        loading = false
    }
}
#endif
