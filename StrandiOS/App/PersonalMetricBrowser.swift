#if os(iOS)
import SwiftUI
import Charts
import StrandDesign

/// Catalogue navigation retains both key and source so an Apple metric never opens a strap series.
struct PersonalMetricBrowser: View {
    @State private var query = ""
    private var metrics: [MetricDescriptor] {
        MetricCatalog.all.filter { query.isEmpty || $0.title.localizedCaseInsensitiveContains(query) || $0.key.localizedCaseInsensitiveContains(query) }
    }
    var body: some View {
        PersonalPage(title: "INDICADORES") {
            ForEach(metrics) { metric in
                NavigationLink { PersonalSeriesDetail(metric: metric) } label: {
                    PersonalWhoopCard {
                        HStack(spacing: PersonalWhoopStyle.margin) {
                            Image(systemName: metric.icon).font(PersonalWhoopStyle.icon)
                            VStack(alignment: .leading, spacing: PersonalWhoopStyle.gap) {
                                Text(metric.title).font(PersonalWhoopStyle.body)
                                Text(metric.sourceLabel).font(PersonalWhoopStyle.label).foregroundStyle(PersonalWhoopStyle.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                    }
                }.buttonStyle(.plain)
            }
        }.searchable(text: $query, prompt: "Procurar indicador")
    }
}

struct PersonalSeriesDetail: View {
    let metric: MetricDescriptor
    @EnvironmentObject private var repo: Repository
    @State private var period = 30
    @State private var loading = true
    @State private var points: [(day: String, value: Double)] = []
    private typealias S = PersonalWhoopStyle
    private var loadKey: String { "\(metric.id)-\(period)-\(repo.refreshSeq)" }
    var body: some View {
        PersonalPage(title: metric.title.uppercased()) {
            Picker("Período", selection: $period) {
                Text("7 dias").tag(7)
                Text("30 dias").tag(30)
                Text("90 dias").tag(90)
                Text("1 ano").tag(365)
            }.pickerStyle(.segmented)
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.margin) {
                    Text(metric.sourceLabel).font(S.label).foregroundStyle(S.secondary)
                    if loading { ProgressView("A carregar…") }
                    else if let last = points.last {
                        Text(formatted(last.value)).font(S.number)
                        Text(last.day).font(S.label).foregroundStyle(S.secondary)
                        // Bars deliberately avoid connecting unmeasured days with a continuous line.
                        Chart(points, id: \.day) { point in
                            BarMark(x: .value("Dia", point.day), y: .value("Valor", displayed(point.value)))
                                .foregroundStyle(S.effort)
                        }.frame(height: S.detailChartHeight)
                    } else {
                        Text("SEM DADOS NESTE PERÍODO").font(S.label)
                    }
                }
            }
            if let description = metric.description {
                Text(description).font(S.body).foregroundStyle(S.secondary)
            }
            ForEach(points.reversed(), id: \.day) { point in
                PersonalWhoopCard {
                    HStack {
                        Text(point.day).font(S.label)
                        Spacer()
                        Text(formatted(point.value)).font(S.body)
                    }
                }
            }
        }.task(id: loadKey) {
            loading = true
            points = []
            let values = await repo.exploreSeries(key: metric.key, source: metric.source, days: period)
            guard !Task.isCancelled else { return }
            let since = Calendar.current.date(byAdding: .day, value: -(period - 1), to: Date()) ?? Date()
            let cutoff = Repository.localDayKey(since)
            points = values.filter { $0.value.isFinite && $0.day >= cutoff }.sorted { $0.day < $1.day }
            loading = false
        }
    }
    private func displayed(_ value: Double) -> Double {
        metric.key == "strain" ? value * 21 / 100 : value
    }
    private func formatted(_ value: Double) -> String {
        if metric.key == "strain" {
            return PersonalMetricScale.effort(value).map { String(format: "%.1f / 21", $0) } ?? "--"
        }
        return metric.format(value)
    }
}
#endif
