#if os(iOS)
import SwiftUI
import Charts
import StrandDesign

struct PersonalActivityStress: View {
    enum Mode { case activities, stress }
    let mode: Mode
    var initialDayKey: String? = nil
    @EnvironmentObject private var repo: Repository
    @State private var stress: [(day: String, value: Double)] = []
    @State private var loading = true
    @State private var sheet: Action?
    private enum Action: String, Identifiable {
        case history, live, stress
        var id: String { rawValue }
    }
    private typealias S = PersonalWhoopStyle
    var body: some View {
        ZStack {
            S.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: S.section) {
                    if mode == .activities { activities } else { stressContent }
                }.padding(S.margin).padding(.bottom, S.section)
            }.refreshable { await repo.refresh() }
        }.foregroundStyle(S.text).buttonStyle(.plain)
            .navigationTitle(mode == .activities ? "ATIVIDADES" : "MONITOR DE STRESS")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task(id: repo.refreshSeq) {
                guard mode == .stress else { return }
                loading = true
                let points = await repo.exploreSeries(key: "stress", source: Repository.whoopSource, days: 14)
                guard !Task.isCancelled else { return }
                stress = points.filter { $0.value.isFinite }.sorted { $0.day < $1.day }
                loading = false
            }
            .sheet(item: $sheet) { action in
                NavigationStack {
                    Group {
                        switch action {
                        case .history: WorkoutsView()
                        case .live: LiveView()
                        case .stress: StressView()
                        }
                    }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { sheet = nil } } }
                }
            }
    }
    private var selectedDay: String { initialDayKey ?? repo.today?.day ?? Repository.localDayKey(Date()) }
    private var activities: some View {
        VStack(alignment: .leading, spacing: S.section) {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.margin) {
                    Text("RESUMO DO DIA").font(S.label).tracking(1)
                    Text(repo.days.last(where: { $0.day == selectedDay })?.exerciseCount.map { "\($0) atividade(s)" } ?? "Sem resumo disponível").font(S.heading)
                    Text(selectedDay).font(S.body).foregroundStyle(S.secondary)
                }
            }
            button("INICIAR ATIVIDADE", "stopwatch", .live)
            button("ADICIONAR OU EDITAR ATIVIDADE", "plus", .history)
            Text("HISTÓRICO POR DIA").font(S.label).tracking(1)
            let rows = repo.days.filter { ($0.exerciseCount ?? 0) > 0 }.sorted { $0.day > $1.day }
            if rows.isEmpty {
                PersonalWhoopCard { Text("Ainda não há atividades no resumo diário. Podes consultar ou adicionar registos no gestor de atividades.").font(S.body).foregroundStyle(S.secondary) }
            }
            ForEach(Array(rows.prefix(30)), id: \.day) { day in
                PersonalWhoopCard {
                    HStack {
                        VStack(alignment: .leading, spacing: S.gap) {
                            Text(day.day).font(S.label)
                            Text("\(day.exerciseCount ?? 0) atividade(s)").font(S.body)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: S.gap) {
                            Text(PersonalMetricScale.effort(day.strain).map { String(format: "%.1f", $0) } ?? "--").font(S.number).foregroundStyle(S.effort)
                            Text("ESFORÇO DO DIA · 0–21").font(S.label).foregroundStyle(S.secondary)
                        }
                    }
                }
            }
            button("ABRIR TODAS AS ATIVIDADES", "list.bullet", .history)
        }
    }
    private var stressContent: some View {
        VStack(alignment: .leading, spacing: S.section) {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.margin) {
                    Text("HISTÓRICO DIÁRIO · 14 DIAS").font(S.label).tracking(1)
                    if loading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: S.detailChartHeight)
                    } else if stress.isEmpty {
                        VStack(spacing: S.gap) {
                            Image(systemName: "chart.xyaxis.line").font(S.number)
                            Text("SEM REGISTOS DIÁRIOS").font(S.label)
                        }.foregroundStyle(S.muted).frame(maxWidth: .infinity, minHeight: S.detailChartHeight)
                    } else {
                        Chart {
                            ForEach(stress, id: \.day) { point in
                                BarMark(x: .value("Dia", String(point.day.suffix(5))), y: .value("Stress", point.value))
                                    .foregroundStyle(S.sleep)
                            }
                        }.frame(height: S.detailChartHeight)
                    }
                    Text("Valores diários guardados pelo NOOP. Este gráfico não representa uma medição contínua nem o stress neste momento.")
                        .font(S.body).foregroundStyle(S.secondary)
                }
            }
            button("ABRIR ANÁLISE INTRADIÁRIA", "waveform.path.ecg", .stress)
            Text("A análise detalhada usa os sinais disponíveis e mostra a cobertura de dados. Pode existir informação intradiária mesmo sem um resumo diário guardado.")
                .font(S.body).foregroundStyle(S.secondary)
        }
    }
    private func button(_ title: String, _ icon: String, _ action: Action) -> some View {
        Button { sheet = action } label: {
            PersonalWhoopCard {
                HStack(spacing: S.margin) {
                    Image(systemName: icon).font(S.icon)
                    Text(title).font(S.label).tracking(1)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(S.muted)
                }.padding(.vertical, S.gap)
            }
        }
    }
}
#endif
