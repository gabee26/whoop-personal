#if os(iOS)
import SwiftUI
import StrandDesign

/// Device settings keep the root dock and expose actual transport readiness.
struct PersonalDeviceScreen: View {
    private typealias D = PersonalDeviceStyle
    private typealias W = PersonalWhoopStyle
    @EnvironmentObject private var live: LiveState
    @EnvironmentObject private var ble: BLEManager
    @Environment(\.dismiss) private var dismiss
    @State private var advanced = false
    @State private var showManager = false
    @State private var showInfo = false

    var body: some View {
        ZStack {
            D.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: D.headerGap) {
                    header
                    summary
                    HStack(spacing: D.headerGap) {
                        tab("ESTADO", selected: !advanced) { advanced = false }
                        tab("AVANÇADA", selected: advanced) { advanced = true }
                        Spacer()
                    }.padding(.horizontal, D.margin)
                    if advanced { diagnostics } else { status }
                    if live.historyReady {
                        Button { ble.syncNow() } label: {
                            Label(live.backfilling ? "A SINCRONIZAR…" : "SINCRONIZAR HISTÓRICO", systemImage: "arrow.triangle.2.circlepath")
                                .font(D.caption).frame(minHeight: W.touchTarget)
                        }.disabled(live.backfilling)
                    }
                    Button { showManager = true } label: {
                        HStack(spacing: W.margin) {
                            Image(systemName: live.connected ? "link" : "plus.circle").font(D.symbol)
                            Text(live.connected ? "GERIR DISPOSITIVO" : "EMPARELHAR UM DISPOSITIVO")
                                .font(D.title).tracking(D.tracking).frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, D.margin)
                        .frame(minHeight: D.buttonHeight)
                        .background(D.surface, in: RoundedRectangle(cornerRadius: D.buttonRadius))
                    }.padding(.horizontal, D.margin)
                }.padding(.bottom, D.bottomSpace)
            }
        }
        .foregroundStyle(W.text).buttonStyle(.plain)
        .toolbar(.hidden, for: .navigationBar).preferredColorScheme(.dark)
        .alert("Ligação e sincronização", isPresented: $showInfo) {
            Button("Fechar", role: .cancel) {}
        } message: {
            Text("Ligada indica uma ligação Bluetooth. A última sincronização indica uma transferência terminada, que pode não conter medições. Consulta Avançada para ver os blocos descodificados e os avisos. Sono e treinos dependem de dados recebidos e processados.")
        }
        .sheet(isPresented: $showManager) {
            NavigationStack {
                DevicesView().toolbar {
                    ToolbarItem(placement: .topBarTrailing) { Button("Fechar") { showManager = false } }
                }
            }
        }
    }

    private var header: some View {
        HStack(spacing: W.gap) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(D.symbol).frame(width: W.touchTarget, height: W.touchTarget)
            }.accessibilityLabel("Fechar definições do dispositivo")
            Text("DEFINIÇÕES DO DISPOSITIVO").font(D.title).tracking(D.tracking)
                .multilineTextAlignment(.center).frame(maxWidth: .infinity)
            Button { showInfo = true } label: {
                Image(systemName: "info.circle").font(D.symbol).frame(width: W.touchTarget, height: W.touchTarget)
            }.accessibilityLabel("Informações sobre sincronização")
        }.padding(.horizontal, W.gap)
    }

    private var summary: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .top, spacing: W.gap) { deviceName; Spacer(minLength: W.gap); syncSummary }
            VStack(alignment: .leading, spacing: W.margin) { deviceName; syncSummary }
        }.padding(.horizontal, D.margin)
    }

    private var deviceName: some View {
        VStack(alignment: .leading, spacing: W.gap) {
            Text(live.connected ? "CONECTADA A" : "NÃO CONECTADA A")
                .font(D.caption).foregroundStyle(W.secondary).tracking(D.tracking)
            Text(live.advertisingName ?? "DISPOSITIVO WHOOP").font(D.heading).tracking(D.tracking)
        }
    }

    private var syncSummary: some View {
        VStack(alignment: .trailing, spacing: W.gap) {
            Text("ÚLTIMA SINCRONIZAÇÃO").font(D.caption).foregroundStyle(W.secondary).tracking(D.tracking)
            HStack(spacing: W.gap) {
                Text(live.backfilling ? "A sincronizar…" : lastSyncLabel)
                if live.backfilling { ProgressView().tint(W.text) }
                else { Image(systemName: live.lastSyncError == nil ? "iphone" : "exclamationmark.circle") }
            }.font(D.caption)
        }.accessibilityElement(children: .combine)
    }

    private var lastSyncLabel: String {
        guard let timestamp = live.lastSyncedAt, timestamp.isFinite else { return "Sem registo" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_PT")
        formatter.dateFormat = "dd/MM HH:mm"
        return formatter.string(from: Date(timeIntervalSince1970: timestamp))
    }

    private func tab(_ title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title).font(D.caption).tracking(D.tracking).foregroundStyle(selected ? W.text : W.muted)
                .frame(minHeight: W.touchTarget)
                .overlay(alignment: .bottom) {
                    Rectangle().fill(selected ? W.text : .clear).frame(height: W.glassStroke * 3)
                }
        }.accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var status: some View {
        VStack(spacing: W.gap) {
            PersonalDeviceArtwork(connected: live.connected).frame(height: D.heroHeight)
            Text(live.connected ? "WHOOP LIGADA" : "WHOOP DESLIGADA").font(D.heading).tracking(D.tracking)
            Text(statusMessage).font(D.body).foregroundStyle(W.secondary)
                .multilineTextAlignment(.center).padding(.horizontal, D.margin)
            warnings
        }
    }

    private var statusMessage: String {
        if !live.connected { return "Toca abaixo em \"emparelhar um dispositivo\" para continuares." }
        if live.backfilling { return "A receber o histórico da tua pulseira…" }
        if !live.historyReady { return "Bluetooth ligado. O acesso ao histórico ainda não está disponível. Abre Avançada para verificar a ligação." }
        if live.historySyncExperimental { return "A pulseira está ligada, mas ainda não entregou histórico utilizável." }
        if live.lastSyncError != nil { return "A ligação está ativa, mas a sincronização precisa de atenção." }
        return "Consulta acima a última sincronização. Os dados são guardados neste iPhone."
    }

    private var diagnostics: some View {
        VStack(alignment: .leading, spacing: W.section) {
            LabeledContent("Bluetooth", value: live.connected ? "Ligada" : "Desligada")
            LabeledContent("Emparelhamento cifrado", value: live.encryptedBond ? "Confirmado" : "Não confirmado")
            LabeledContent("Acesso ao histórico", value: live.historyReady ? "Disponível" : "Indisponível")
            LabeledContent("Última transferência", value: lastSyncLabel)
            LabeledContent("Blocos recebidos nesta sessão", value: String(live.syncChunksThisSession))
            LabeledContent("Blocos descodificados", value: String(live.decodedChunksThisSession))
            LabeledContent("Blocos de diagnóstico", value: String(live.consoleChunksThisSession))
            LabeledContent("Blocos por descodificar", value: String(live.rejectedFramesThisSession))
            LabeledContent("Frequência cardíaca", value: PersonalConnectionPresentation.heartRate(connected: live.connected, bpm: live.heartRate).map { "\($0) BPM" } ?? "Sem medição")
            if live.activeIsWhoop, live.connected, let pct = live.batteryPct, pct.isFinite {
                LabeledContent("Bateria", value: "\(Int(pct.rounded()))%")
            }
            warnings
            NavigationLink { PersonalLiveScreen() } label: { Label("TESTAR BATIMENTOS EM DIRETO", systemImage: "waveform.path.ecg") }
            Text("Os contadores são da sessão de transferência, não representam o total guardado. Uma transferência sem blocos descodificados não confirma a receção do sono ou do treino.")
                .foregroundStyle(W.secondary)
        }.font(W.body).padding(.horizontal, D.margin)
    }

    @ViewBuilder private var warnings: some View {
        if let error = live.lastSyncError, !error.isEmpty { Text(error).font(W.body).foregroundStyle(W.yellow) }
        if let hint = live.pairingHint { Text(hint).font(W.body).foregroundStyle(W.secondary) }
        if let guide = live.reconnectGuide { Text(guide).font(W.body).foregroundStyle(W.yellow) }
        if live.historySyncExperimental {
            Text("O histórico WHOOP 5.0/MG é experimental. Sem dados recebidos não é possível reconstruir esta noite ou este treino.")
                .font(W.body).foregroundStyle(W.yellow)
        }
    }
}
#endif
