#if os(iOS)
import SwiftUI
import StrandDesign
import WhoopProtocol

struct PersonalPage<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        ZStack {
            PersonalWhoopStyle.background.ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: PersonalWhoopStyle.section) { content() }
                    .padding(PersonalWhoopStyle.margin).padding(.bottom, NoopMetrics.tabBarClearance)
            }
        }.scrollDismissesKeyboard(.interactively)
            .foregroundStyle(PersonalWhoopStyle.text)
            .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
    }
}

struct PersonalSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder var content: () -> Content
    var body: some View {
        VStack(alignment: .leading, spacing: PersonalWhoopStyle.margin) {
            Label(title, systemImage: icon)
                .font(PersonalWhoopStyle.label).tracking(1)
                .foregroundStyle(PersonalWhoopStyle.secondary)
            content()
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PersonalAction: View {
    let title: String
    let icon: String
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            PersonalWhoopCard {
                HStack {
                    Image(systemName: icon)
                    Text(title).font(PersonalWhoopStyle.label)
                    Spacer()
                    Image(systemName: "chevron.right")
                }.padding(.vertical, PersonalWhoopStyle.gap)
            }
        }.buttonStyle(.plain)
    }
}

struct PersonalPairingScreen: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState
    @AppStorage("selectedWhoopModel") private var family = WhoopModel.whoop4.rawValue
    @State private var scanning = false
    @State private var disconnect = false
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalPage(title: "LIGAR PULSEIRA") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    HStack {
                        Image(systemName: "applewatch").font(S.deviceIllustration)
                        Spacer()
                        Circle().fill(live.connected ? S.green : S.muted).frame(width: S.gap, height: S.gap)
                    }
                    Text(live.connected ? "PULSEIRA LIGADA" : "EMPARELHAR DISPOSITIVO").font(S.heading)
                    Text(live.advertisingName ?? "WHOOP").font(S.body).foregroundStyle(S.secondary)
                    Picker("Modelo", selection: Binding(get: { family }, set: { value in
                        guard family != value else { return }
                        family = value
                        scanning = false
                        model.prepareStrapSwitch()
                    })) {
                        Text("WHOOP 4.0").tag(WhoopModel.whoop4.rawValue)
                        Text("WHOOP 5.0 / MG").tag(WhoopModel.whoop5mg.rawValue)
                    }.pickerStyle(.segmented).disabled(live.connected)
                    Text("Mantém a pulseira perto do iPhone e coloca-a em modo de emparelhamento se ainda não estiver associada.")
                        .font(S.body).foregroundStyle(S.secondary)
                }
            }
            if let guide = live.reconnectGuide { Text(guide).font(S.body).foregroundStyle(S.secondary) }
            if let hint = live.pairingHint { Text(hint).font(S.body).foregroundStyle(S.secondary) }
            if live.connected {
                PersonalAction(title: "ATUALIZAR BATERIA", icon: "battery.100") { model.getBattery() }
                PersonalAction(title: "DESLIGAR PULSEIRA", icon: "link") { disconnect = true }
            } else {
                PersonalAction(title: scanning ? "PROCURAR NOVAMENTE" : "PROCURAR E LIGAR", icon: "antenna.radiowaves.left.and.right") {
                    scanning = true
                    model.scan(model: WhoopModel(rawValue: family) ?? .whoop4)
                }
                if scanning { Text("Procura iniciada. Aguarda a ligação; se não acontecer, verifica o modelo e o modo de emparelhamento.").font(S.body).foregroundStyle(S.secondary) }
            }
        }.alert("Desligar a pulseira?", isPresented: $disconnect) {
            Button("Cancelar", role: .cancel) {}
            Button("Desligar", role: .destructive) { model.disconnect(); scanning = false }
        } message: { Text("A ligação é interrompida. O histórico guardado mantém-se.") }
    }
}

struct PersonalLiveScreen: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var live: LiveState
    @State private var ownsStream = false
    @State private var ending = false
    @State private var sport = "Other"
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalPage(title: "EM DIRETO") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    Text("FREQUÊNCIA CARDÍACA").font(S.label).tracking(1)
                    HStack(alignment: .firstTextBaseline) {
                        Text(live.connected && live.liveFeedActive ? live.heartRate.map(String.init) ?? "--" : "--").font(S.number)
                        Text("BPM").font(S.label).foregroundStyle(S.secondary)
                    }
                    Text(live.connected ? "A aguardar ou receber medições da pulseira" : "Pulseira desligada").font(S.body).foregroundStyle(S.secondary)
                }
            }
            if !live.connected {
                NavigationLink { PersonalPairingScreen() } label: {
                    PersonalWhoopCard { Label("LIGAR PULSEIRA", systemImage: "applewatch").font(S.label) }
                }.buttonStyle(.plain)
            }
            if let session = model.activeWorkout {
                PersonalWhoopCard {
                    VStack(alignment: .leading, spacing: S.margin) {
                        Text("ATIVIDADE EM CURSO").font(S.label)
                        Text(session.sport).font(S.heading)
                        Text(session.start, style: .timer).font(S.number).monospacedDigit()
                    }
                }
                PersonalAction(title: "TERMINAR ATIVIDADE", icon: "stop.circle") { ending = true }
            } else {
                PersonalWhoopCard {
                    VStack(alignment: .leading, spacing: S.margin) {
                        Text("NOVA ATIVIDADE").font(S.label)
                        Picker("Atividade", selection: $sport) {
                            ForEach(WorkoutCatalog.all) { item in
                                Text(WorkoutSource.displaySport(item.name)).tag(item.name)
                            }
                        }.tint(S.text)
                    }
                }
                PersonalAction(title: "INICIAR ATIVIDADE", icon: "play.circle") { model.startWorkout(sport: sport) }
                    .disabled(!live.connected)
            }
        }.onAppear { arm() }
            .onChange(of: live.connected) { _, _ in arm() }
            .onChange(of: live.bonded) { _, _ in arm() }
            .onDisappear { if ownsStream { model.stopRealtimeHR(); ownsStream = false } }
            .alert("Terminar atividade?", isPresented: $ending) {
                Button("Continuar", role: .cancel) {}
                Button("Terminar e guardar") { model.endWorkout() }
            } message: { Text("O motor guarda os dados captados que cumpram os critérios mínimos. A gravação desta atividade termina.") }
    }
    private func arm() {
        guard live.connected else { return }
        if ownsStream { model.rearmRealtimeIfWanted() }
        else { model.startRealtimeHR(); ownsStream = true }
        model.getBattery()
    }
}

struct PersonalProfileScreen: View {
    @EnvironmentObject private var profile: ProfileStore
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalPage(title: "O MEU PERFIL") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    Text("DADOS PESSOAIS").font(S.label).tracking(1)
                    DatePicker("Nascimento", selection: $profile.dateOfBirth, in: ...Date(), displayedComponents: .date)
                    Picker("Sexo", selection: $profile.sex) {
                        Text("Masculino").tag("male")
                        Text("Feminino").tag("female")
                        Text("Não binário").tag("nonbinary")
                    }
                    Stepper("Peso: \(profile.weightKg, specifier: "%.1f") kg", value: $profile.weightKg, in: 20...350, step: 0.5)
                    Stepper("Altura: \(profile.heightCm, specifier: "%.0f") cm", value: $profile.heightCm, in: 80...250)
                }.font(S.body)
            }
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.margin) {
                    Text("FREQUÊNCIA CARDÍACA MÁXIMA").font(S.label)
                    Text(profile.hrMaxOverride == 0 ? "Estimativa automática" : "\(profile.hrMaxOverride) bpm").font(S.number)
                    Stepper("Ajustar valor", value: $profile.hrMaxOverride, in: 0...230)
                    Button("Usar estimativa automática") { profile.hrMaxOverride = 0 }.tint(S.effort)
                }
            }
            NavigationLink("UNIDADES, ZONAS E CALIBRAÇÃO") { SettingsView() }
            Text("As alterações são guardadas no teu perfil e utilizadas pelo motor de cálculo.").font(S.body).foregroundStyle(S.secondary)
        }
    }
}
#endif
