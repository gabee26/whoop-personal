#if os(iOS)
import SwiftUI
import Charts
import StrandDesign
import WhoopStore

/// Local athlete planning and descriptive reporting, independent of physiological scoring.
struct PersonalAthleteScreen: View {
    @EnvironmentObject private var repo: Repository
    @ObservedObject private var journal = PersonalAthleteStore.shared
    @AppStorage("personal.goal.sleepHours") private var sleepGoal = 8.0
    @AppStorage("personal.athlete.wakeHour") private var wakeHour = 7
    @AppStorage("personal.athlete.wakeMinute") private var wakeMinute = 30
    @AppStorage("personal.athlete.sleepBuffer") private var sleepBuffer = 20
    @State private var checkInDate = Date()
    @State private var editingCheckIn: PersonalAthleteCheckIn?
    @State private var editingSession: PersonalAthleteSession?
    @State private var deletingSession: PersonalAthleteSession?
    @State private var weekOffset = 0
    @State private var importing = false
    @State private var exporting = false
    @State private var document: PersonalAthleteDocument?
    @State private var pendingRestore: PersonalAthleteArchive?
    @State private var message: String?
    private typealias S = PersonalWhoopStyle
    private var calendar: Calendar { Calendar.current }
    private var today: String { Repository.localDayKey(Date()) }
    private var checkInKey: String { Repository.localDayKey(checkInDate) }
    private var week: DateInterval {
        let anchor = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: Date()) ?? Date()
        return calendar.dateInterval(of: .weekOfYear, for: anchor) ?? DateInterval(start: anchor, duration: 7 * 86400)
    }
    private var weekKeys: [String] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: week.start) }.map(Repository.localDayKey)
    }
    private var sessions: [PersonalAthleteSession] {
        journal.archive.sessions.filter { $0.date >= week.start && $0.date < week.end }.sorted { $0.date < $1.date }
    }
    private var checkIns: [PersonalAthleteCheckIn] {
        journal.archive.checkIns.filter { weekKeys.contains($0.id) }
    }
    private var nights: [DailyMetric] {
        repo.days.filter { weekKeys.contains($0.day) && $0.day <= today && ($0.totalSleepMin ?? 0) > 0 && ($0.totalSleepMin ?? 0) <= 1440 }
    }
    private var loads: [Int] { sessions.compactMap(\.perceivedLoad) }
    private var wakeDate: Binding<Date> {
        Binding(get: {
            calendar.nextDate(after: Date(), matching: DateComponents(hour: wakeHour, minute: wakeMinute), matchingPolicy: .nextTime) ?? Date()
        }, set: { date in
            wakeHour = calendar.component(.hour, from: date)
            wakeMinute = calendar.component(.minute, from: date)
        })
    }

    var body: some View {
        PersonalPage(title: "ATLETA") {
            morning
            if let next = journal.archive.sessions.filter({ !$0.completed && $0.date >= Date() }).min(by: { $0.date < $1.date }) {
                PersonalWhoopCard {
                    VStack(alignment: .leading, spacing: S.gap) {
                        Text("PRÓXIMA SESSÃO").font(S.label)
                        Text(next.kind).font(S.heading)
                        Text("\(next.date.formatted(date: .abbreviated, time: .shortened)) · \(next.minutes) min")
                        Button("VER / EDITAR") { editingSession = next }
                    }
                }
            }
            checkInCard
            sleepPlan
            weekHeader
            weeklySummary
            calendarCard
            backupCard
            NavigationLink("COMO INTERPRETAR OS INDICADORES") { PersonalMetricGuide() }
            if let error = journal.error {
                Text(error).font(S.body).foregroundStyle(S.red)
                Button("Tentar ler novamente") { journal.reload() }
            }
        }
        .font(S.body).tint(S.effort)
        .refreshable { await repo.refresh() }
        .sheet(item: $editingCheckIn) { item in
            NavigationStack { PersonalCheckInEditor(item: item) }
        }
        .sheet(item: $editingSession) { item in
            NavigationStack { PersonalSessionEditor(item: item) }
        }
        .alert("Apagar sessão?", isPresented: Binding(get: { deletingSession != nil }, set: { if !$0 { deletingSession = nil } })) {
            Button("Apagar", role: .destructive) {
                if let item = deletingSession { journal.remove(sessionID: item.id) }
                deletingSession = nil
            }
            Button("Cancelar", role: .cancel) { deletingSession = nil }
        } message: { Text("Remove apenas este registo manual. A atividade da pulseira mantém-se.") }
        .fileExporter(isPresented: $exporting, document: document, contentType: .json, defaultFilename: "diario-atleta-\(today)") { result in
            if case .failure = result { message = "Não foi possível exportar a cópia." }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= 20_000_000 else { throw PersonalAthleteArchive.ValidationError.invalid }
                pendingRestore = try PersonalAthleteStore.decode(Data(contentsOf: url))
            } catch { message = "Ficheiro inválido ou inacessível. O diário atual não foi alterado." }
        }
        .confirmationDialog("Substituir o diário atual?", isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }), titleVisibility: .visible) {
            Button("Substituir diário", role: .destructive) {
                if let candidate = pendingRestore, journal.restore(candidate) { message = "Diário restaurado." }
                pendingRestore = nil
            }
            Button("Cancelar", role: .cancel) { pendingRestore = nil }
        } message: {
            Text("A cópia contém \(pendingRestore?.checkIns.count ?? 0) check-ins e \(pendingRestore?.sessions.count ?? 0) sessões. Exporta primeiro o diário atual se o quiseres preservar. Não altera os dados da pulseira.")
        }
        .alert("Diário de atleta", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK") { message = nil }
        } message: { Text(message ?? "") }
    }

    private var morning: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.gap) {
                Label("COMO ESTOU HOJE", systemImage: "sun.max").font(S.label)
                let row = repo.days.last { $0.day == today }
                Text(row == nil ? "À espera dos dados de hoje" : "O teu ponto de situação").font(S.heading)
                Text("Recuperação estimada: \(number(PersonalMetricScale.percentage(row?.recovery)))% · Sono: \(number(row?.totalSleepMin.map { $0 / 60 })) h")
                baseline("VFC", current: row?.avgHrv, values: previousDays.compactMap(\.avgHrv), unit: "ms")
                baseline("FC em repouso", current: row?.restingHr.map(Double.init), values: previousDays.compactMap { $0.restingHr.map(Double.init) }, unit: "bpm")
                if let entry = journal.archive.checkIns.first(where: { $0.id == today }) {
                    Text("O que registaste: energia \(entry.energy)/5 · fadiga \(entry.fatigue)/5.")
                    if entry.fatigue >= 4 || entry.soreness.values.contains(where: { $0 >= 6 }) {
                        Text("Registaste fadiga ou desconforto elevados. Considera essa sensação com o teu treinador, mesmo que a recuperação estimada apareça verde.").foregroundStyle(S.yellow)
                    }
                } else {
                    Text("Completa o check-in para juntar a tua sensação aos indicadores.").foregroundStyle(S.secondary)
                }
                Text("Os indicadores podem reunir dados importados e cálculos locais. São estimativas; não medem diretamente a recuperação muscular nem autorizam um treino.")
                    .font(S.label).foregroundStyle(S.secondary)
            }
        }
    }

    private var previousDays: [DailyMetric] {
        let start = Repository.localDayKey(calendar.date(byAdding: .day, value: -14, to: Date()) ?? Date())
        return repo.days.filter { $0.day >= start && $0.day < today }
    }

    @ViewBuilder private func baseline(_ title: String, current: Double?, values: [Double], unit: String) -> some View {
        if let mean = PersonalAthleteSummary.referenceMean(values), let current, current.isFinite, current > 0 {
            Text("\(title): \(number(current)) \(unit) · média anterior \(number(mean)) · diferença \(String(format: "%+.1f", current - mean))")
        } else {
            Text("\(title): \(number(current)) \(unit) · referência indisponível (mínimo 7 dias válidos nos últimos 14)")
                .foregroundStyle(S.secondary)
        }
    }

    private var checkInCard: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.gap) {
                Label("CHECK-IN DIÁRIO", systemImage: "person.crop.circle.badge.checkmark").font(S.label)
                DatePicker("Dia", selection: $checkInDate, in: ...Date(), displayedComponents: .date)
                if let entry = journal.archive.checkIns.first(where: { $0.id == checkInKey }) {
                    Text("Energia \(entry.energy)/5 · Fadiga \(entry.fatigue)/5 · Sono \(entry.sleepQuality)/5")
                    ForEach(entry.soreness.keys.sorted(), id: \.self) { zone in
                        Text("\(zone): \(entry.soreness[zone] ?? 0)/10").foregroundStyle(S.secondary)
                    }
                    if !entry.notes.isEmpty { Text(entry.notes) }
                } else { Text("Ainda não preenchido.").foregroundStyle(S.secondary) }
                Button("PREENCHER / EDITAR") {
                    editingCheckIn = journal.archive.checkIns.first { $0.id == checkInKey } ?? PersonalAthleteCheckIn(day: checkInKey)
                }.buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
            }
        }
    }

    private var sleepPlan: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.gap) {
                Label("ESTA NOITE", systemImage: "moon.stars").font(S.label)
                DatePicker("Quero acordar às", selection: wakeDate, displayedComponents: .hourAndMinute)
                Stepper("Objetivo escolhido: \(sleepGoal, specifier: "%.1f") h", value: $sleepGoal, in: 4...12, step: 0.5)
                Stepper("Tempo para adormecer: \(sleepBuffer) min", value: $sleepBuffer, in: 0...120, step: 5)
                if let bed = PersonalAthleteSummary.bedtime(wake: wakeDate.wrappedValue, sleepHours: sleepGoal, bufferMinutes: sleepBuffer) {
                    Text("Deitar: \(bed.formatted(date: .abbreviated, time: .shortened))").font(S.heading)
                    if bed < Date() { Text("Essa hora já passou para o próximo despertar escolhido.").foregroundStyle(S.yellow) }
                }
                Text("Planeamento a partir do teu objetivo, não uma necessidade fisiológica calculada. Não programa o alarme da pulseira.").font(S.label).foregroundStyle(S.secondary)
                NavigationLink("ABRIR ALARME") { SmartAlarmView() }
            }
        }
    }

    private var weekHeader: some View {
        HStack {
            Button { weekOffset -= 1 } label: { Image(systemName: "chevron.left") }.accessibilityLabel("Semana anterior")
            Spacer()
            Text("SEMANA DE \(week.start.formatted(date: .abbreviated, time: .omitted))").font(S.label)
            Spacer()
            Button { weekOffset += 1 } label: { Image(systemName: "chevron.right") }.accessibilityLabel("Semana seguinte")
        }
    }

    private var weeklySummary: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.gap) {
                Label("RELATÓRIO SEMANAL", systemImage: "chart.bar").font(S.label)
                Text("\(sessions.filter(\.completed).count) sessões concluídas · \(loads.count) com intensidade registada")
                Text(loads.isEmpty ? "Carga percebida: sem dados" : "Carga percebida: \(loads.reduce(0, +)) UA").font(S.heading)
                Text("Carga = minutos × intensidade sentida (1–10). Não se soma ao esforço cardiovascular. Sessões planeadas não entram no total.").font(S.label).foregroundStyle(S.secondary)
                if !loads.isEmpty {
                    Chart(weekKeys, id: \.self) { key in
                        BarMark(x: .value("Dia", String(key.suffix(5))), y: .value("Carga registada", sessions.filter { Repository.localDayKey($0.date) == key }.compactMap(\.perceivedLoad).reduce(0, +)))
                            .foregroundStyle(S.effort)
                    }.frame(height: S.detailChartHeight)
                    Text("Barras sem carga significam ausência de carga registada, não descanso confirmado.").font(S.label).foregroundStyle(S.secondary)
                }
                Text("Cobertura: \(nights.count) noites com duração · \(checkIns.count) check-ins")
                let hours = nights.compactMap { $0.totalSleepMin.map { $0 / 60 } }
                Text("Média de sono: \(number(PersonalAthleteSummary.referenceMean(hours, minimumCount: 1))) h")
                Text("Horas abaixo do objetivo: \(number(PersonalAthleteSummary.sleepGap(hours: hours, target: sleepGoal))) h")
                Text("Soma das diferenças nas noites disponíveis, usando o objetivo atual. Não é uma medição de dívida de sono nem inclui noites em falta.").font(S.label).foregroundStyle(S.secondary)
                ShareLink(item: report, preview: SharePreview("Relatório semanal do atleta")) {
                    Label("PARTILHAR RELATÓRIO", systemImage: "square.and.arrow.up")
                }
            }
        }
    }

    private var calendarCard: some View {
        PersonalSection(title: "TREINOS E JOGOS", icon: "calendar") {
            Button("ADICIONAR SESSÃO") { editingSession = PersonalAthleteSession() }
                .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
            if sessions.isEmpty { Text("Sem sessões registadas nesta semana.").foregroundStyle(S.secondary) }
            ForEach(sessions) { item in
                PersonalWhoopCard {
                    VStack(alignment: .leading, spacing: S.gap) {
                        Text(item.kind).font(S.heading)
                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                        Text("\(item.minutes) min · \(item.completed ? "Concluída" : "Planeada") · RPE \(item.exertion.map(String.init) ?? "—")/10")
                        if let load = item.perceivedLoad { Text("Carga percebida: \(load) UA") }
                        if !item.notes.isEmpty { Text(item.notes).foregroundStyle(S.secondary) }
                        if item.completed { followingDay(item) }
                        HStack {
                            Button("EDITAR") { editingSession = item }
                            Spacer()
                            Button("APAGAR", role: .destructive) { deletingSession = item }
                        }.font(S.label)
                    }
                }
            }
        }
    }

    @ViewBuilder private func followingDay(_ session: PersonalAthleteSession) -> some View {
        let next = calendar.date(byAdding: .day, value: 1, to: session.date) ?? session.date
        let key = Repository.localDayKey(next)
        let row = repo.days.last { $0.day == key }
        let entry = journal.archive.checkIns.first { $0.id == key }
        Text("Dia seguinte: sono \(number(row?.totalSleepMin.map { $0 / 60 })) h · recuperação \(number(PersonalMetricScale.percentage(row?.recovery)))% · fadiga \(entry.map { String($0.fatigue) } ?? "—")/5")
            .font(S.label).foregroundStyle(S.secondary)
        Text("Associação descritiva; não demonstra que esta sessão causou a alteração.").font(S.label).foregroundStyle(S.secondary)
    }

    private var backupCard: some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.gap) {
                Text("OS TEUS REGISTOS").font(S.label)
                Text("Check-ins e sessões ficam neste iPhone e funcionam offline. A cópia abaixo guarda apenas este diário; usa também a cópia de segurança da aplicação para os dados da pulseira.").foregroundStyle(S.secondary)
                Button("EXPORTAR DIÁRIO") {
                    do { document = try PersonalAthleteDocument(archive: journal.archive); exporting = true }
                    catch { message = "Não foi possível preparar a cópia." }
                }.disabled(!journal.loaded)
                Button("RESTAURAR DIÁRIO") { importing = true }
            }
        }
    }

    private var report: String {
        var lines = ["RELATÓRIO DO ATLETA — \(weekKeys.first ?? "") a \(weekKeys.last ?? "")",
                     "Sessões concluídas: \(sessions.filter(\.completed).count); com RPE: \(loads.count)",
                     "Carga percebida registada (UA): \(loads.isEmpty ? "sem dados" : String(loads.reduce(0, +)))",
                     "Noites com duração: \(nights.count); check-ins: \(checkIns.count)"]
        for key in weekKeys {
            let row = repo.days.last { $0.day == key }
            let entry = checkIns.first { $0.id == key }
            lines.append("\(key): sono \(number(row?.totalSleepMin.map { $0 / 60 })) h; recuperação estimada \(number(PersonalMetricScale.percentage(row?.recovery)))%; energia \(entry.map { String($0.energy) } ?? "—")/5; fadiga \(entry.map { String($0.fatigue) } ?? "—")/5")
            for session in sessions where Repository.localDayKey(session.date) == key {
                lines.append("  \(session.kind), \(session.minutes) min, \(session.completed ? "concluída" : "planeada"), RPE \(session.exertion.map(String.init) ?? "—"), carga \(session.perceivedLoad.map(String.init) ?? "—") UA")
            }
        }
        lines.append("Valores em falta não são zero. Scores são estimativas, não uma avaliação médica. Notas pessoais e zonas de desconforto não estão incluídas neste relatório.")
        return lines.joined(separator: "\n")
    }
    private func number(_ value: Double?) -> String {
        guard let value, value.isFinite else { return "—" }
        return String(format: "%.1f", value)
    }
}

private struct PersonalCheckInEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var journal = PersonalAthleteStore.shared
    @State var item: PersonalAthleteCheckIn
    private typealias S = PersonalWhoopStyle
    private let zones = ["Pescoço", "Ombro esquerdo", "Ombro direito", "Punhos / mãos", "Lombar", "Adutor esquerdo", "Adutor direito", "Joelho esquerdo", "Joelho direito", "Tornozelo esquerdo", "Tornozelo direito"]
    var body: some View {
        PersonalPage(title: "CHECK-IN · \(item.id)") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    Text("Regista como te sentes. 1 = muito baixo / má qualidade; 5 = muito alto / boa qualidade.").font(S.body)
                    Stepper("Energia: \(item.energy)/5", value: $item.energy, in: 1...5)
                    Stepper("Fadiga: \(item.fatigue)/5 (5 = muito cansado)", value: $item.fatigue, in: 1...5)
                    Stepper("Qualidade do sono: \(item.sleepQuality)/5", value: $item.sleepQuality, in: 1...5)
                }
            }
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.gap) {
                    Text("DESCONFORTO POR ZONA").font(S.label)
                    Text("0 = nenhum; 10 = máximo. Não identifica lesões.").font(S.body).foregroundStyle(S.secondary)
                    ForEach(zones, id: \.self) { zone in
                        Stepper("\(zone): \(item.soreness[zone] ?? 0)/10", value: Binding(get: { item.soreness[zone] ?? 0 }, set: { value in
                            if value == 0 { item.soreness.removeValue(forKey: zone) } else { item.soreness[zone] = value }
                        }), in: 0...10)
                    }
                }
            }
            TextField("Notas opcionais", text: $item.notes, axis: .vertical).lineLimit(3...8)
            if let error = journal.error { Text(error).foregroundStyle(S.red) }
            Button("GUARDAR CHECK-IN") { if journal.save(item) { dismiss() } }
                .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true)).disabled(item.notes.count > 4000)
        }.font(S.body)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancelar") { dismiss() } } }
    }
}

private struct PersonalSessionEditor: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var journal = PersonalAthleteStore.shared
    @State var item: PersonalAthleteSession
    private typealias S = PersonalWhoopStyle
    private let kinds = ["Guarda-redes", "Equipa", "Ginásio", "Jogo", "Recuperação", "Outro"]
    private var futureCompleted: Bool { item.completed && item.date > Date() }
    var body: some View {
        PersonalPage(title: "SESSÃO") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    Picker("Tipo", selection: $item.kind) {
                        ForEach(Array(Set(kinds + [item.kind])).sorted(), id: \.self) { Text($0).tag($0) }
                    }
                    DatePicker("Data e hora", selection: $item.date)
                    Stepper("Duração: \(item.minutes) min", value: $item.minutes, in: 1...600)
                    Toggle("Sessão concluída", isOn: $item.completed)
                    Toggle("Registar intensidade sentida", isOn: Binding(get: { item.exertion != nil }, set: { item.exertion = $0 ? 5 : nil }))
                    if item.exertion != nil {
                        Stepper("RPE: \(item.exertion ?? 5)/10", value: Binding(get: { item.exertion ?? 5 }, set: { item.exertion = $0 }), in: 1...10)
                    }
                    Text("1 = muito fácil; 10 = esforço máximo. Preenche depois da sessão. Sem intensidade, a sessão fica registada mas não entra na carga percebida.").font(S.body).foregroundStyle(S.secondary)
                    TextField("Notas opcionais", text: $item.notes, axis: .vertical).lineLimit(3...8)
                    if futureCompleted { Text("Uma sessão futura deve ficar planeada.").foregroundStyle(S.yellow) }
                    if let error = journal.error { Text(error).foregroundStyle(S.red) }
                    Button("GUARDAR SESSÃO") { if journal.save(item) { dismiss() } }
                        .buttonStyle(NoopButtonStyle(.secondary, fullWidth: true))
                        .disabled(futureCompleted || item.notes.count > 4000)
                }
            }
        }.font(S.body)
            .toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Cancelar") { dismiss() } } }
    }
}
#endif
