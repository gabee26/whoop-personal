#if os(iOS)
import SwiftUI
import StrandDesign

/// Personal navigation around the existing editors; settings retain their original bindings.
struct PersonalSettingsScreen: View {
    private typealias S = PersonalWhoopStyle
    var body: some View {
        ZStack {
            S.background.ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: S.section) {
                    section("A TUA CONTA LOCAL") {
                        link("Perfil e preferências", "Data de nascimento, medidas e frequência cardíaca", "person.crop.circle") { PersonalProfileScreen() }
                        link("Dispositivo WHOOP", "Ligação, bateria e sincronização", "applewatch") { PersonalDeviceScreen() }
                        link("Alarme", "Sono e hora de acordar", "alarm") { SmartAlarmView() }
                    }
                    section("DADOS E INTEGRAÇÕES") {
                        link("Importar histórico", "Fontes de dados e exportação original WHOOP", "square.and.arrow.down") { PersonalImportScreen() }
                        link("Cópias de segurança", "Guardar, restaurar e exportar", "externaldrive") { BackupSyncView() }
                        link("Saúde da Apple", "Configurar a integração disponível", "heart") { AppleHealthView() }
                        link("Atalhos e exportação", "Integrações através dos Atalhos", "square.and.arrow.up") { ShortcutExportSettingsView() }
                        link("Comparar indicadores", "Dados importados e cálculos locais", "chart.bar.xaxis") { PersonalComparisonScreen() }
                    }
                    section("PREFERÊNCIAS E SUPORTE") {
                        link("Coach", "Configuração do assistente e fornecedor", "sparkles") { CoachView() }
                        link("Preferências avançadas", "Unidades, calibração e captura de dados", "slider.horizontal.3") { SettingsView() }
                        link("Poupar bateria", "Preferências de funcionamento", "battery.25") { PowerSavingView() }
                        link("Automatizações", "Regras locais disponíveis", "wand.and.stars") { AutomationsView() }
                        link("Siri e Atalhos", "Ações rápidas no iPhone", "mic") { SiriShortcutsSettingsView() }
                        link("Diagnóstico", "Estado da ligação e registos técnicos", "stethoscope") { TestCentreView() }
                        link("Capacidades da pulseira", "Diferenças e limitações dos modelos", "info.circle") { NoopLimitationsView() }
                    }
                    PersonalWhoopCard {
                        VStack(alignment: .leading, spacing: S.gap) {
                            Text("WHOOP · VERSÃO PESSOAL").font(S.label)
                            Text("Dados e cálculos locais. Esta aplicação não é o serviço oficial WHOOP. Créditos e licenças da base NOOP nas preferências avançadas.")
                                .font(S.body).foregroundStyle(S.secondary)
                        }
                    }
                }.padding(S.margin).padding(.bottom, S.section)
            }
        }.foregroundStyle(S.text)
            .navigationTitle("DEFINIÇÕES").navigationBarTitleDisplayMode(.inline)
    }
    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: S.gap) {
            Text(title).font(S.label).tracking(1).foregroundStyle(S.secondary)
            content()
        }
    }
    private func link<Destination: View>(_ title: String, _ subtitle: String, _ icon: String,
                                        @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            PersonalWhoopCard {
                HStack(spacing: S.margin) {
                    Image(systemName: icon).font(S.icon).foregroundStyle(S.secondary)
                    VStack(alignment: .leading, spacing: S.gap) {
                        Text(title).font(S.body)
                        Text(subtitle).font(S.label).foregroundStyle(S.secondary)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right").foregroundStyle(S.muted)
                }
            }
        }.buttonStyle(.plain)
    }
}

struct PersonalTrainingTools: View {
    private typealias S = PersonalWhoopStyle
    var body: some View {
        ZStack {
            S.background.ignoresSafeArea()
            ScrollView {
                VStack(spacing: S.gap) {
                    tool("Treinos de força", "dumbbell") { LiftLogView() }
                    tool("Temporizador de intervalos", "timer") { IntervalTimerView() }
                    tool("Respiração", "wind") { BreathingView() }
                    tool("Tendências", "chart.xyaxis.line") { TrendsView() }
                    tool("Comparar períodos", "rectangle.split.2x1") { CompareView() }
                    tool("Registos e análises", "books.vertical") { LabBookView() }
                    tool("Explorar indicadores", "waveform.path.ecg") { PersonalMetricBrowser() }
                }.padding(S.margin).padding(.bottom, S.section)
            }
        }.foregroundStyle(S.text)
            .navigationTitle("FERRAMENTAS").navigationBarTitleDisplayMode(.inline)
    }
    private func tool<Destination: View>(_ title: String, _ icon: String,
                                        @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            PersonalWhoopCard {
                HStack(spacing: S.margin) {
                    Image(systemName: icon).font(S.icon)
                    Text(title).font(S.body)
                    Spacer()
                    Image(systemName: "chevron.right").foregroundStyle(S.muted)
                }.padding(.vertical, S.gap)
            }
        }.buttonStyle(.plain)
    }
}
#endif
