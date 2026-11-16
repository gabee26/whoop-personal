#if os(iOS)
import SwiftUI
import StrandDesign

/// Personal first-run navigation keeps the existing completion flag and underlying settings.
struct PersonalWelcome: View {
    let onFinished: () -> Void
    var body: some View {
        NavigationStack {
            PersonalPage(title: "WHOOP") {
                VStack(alignment: .leading, spacing: PersonalWhoopStyle.margin) {
                    Image(systemName: "waveform.path.ecg").font(PersonalWhoopStyle.deviceIllustration)
                        .foregroundStyle(PersonalWhoopStyle.effort)
                    Text("Conhece o teu ritmo.").font(PersonalWhoopStyle.heading)
                    Text("Sono, recuperação e atividade num espaço pessoal. Os teus registos ficam no iPhone.")
                        .font(PersonalWhoopStyle.body).foregroundStyle(PersonalWhoopStyle.secondary)
                }.padding(.vertical, PersonalWhoopStyle.section)
                link("1 · LIGAR A PULSEIRA", "applewatch") { PersonalPairingScreen() }
                link("2 · COMPLETAR O PERFIL", "person.crop.circle") { PersonalProfileScreen() }
                link("3 · IMPORTAR HISTÓRICO", "square.and.arrow.down") { PersonalImportScreen() }
                PersonalAction(title: "ENTRAR NA APLICAÇÃO", icon: "arrow.right") { onFinished() }
                Text("Podes concluir estes passos mais tarde nas definições. Sem dados suficientes, os indicadores ficam por preencher.")
                    .font(PersonalWhoopStyle.label).foregroundStyle(PersonalWhoopStyle.secondary)
            }
        }.preferredColorScheme(.dark)
    }
    private func link<Destination: View>(_ title: String, _ icon: String, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            PersonalWhoopCard { Label(title, systemImage: icon).font(PersonalWhoopStyle.label) }
        }.buttonStyle(.plain)
    }
}

struct PersonalTermsGate: View {
    let onAccept: () -> Void
    @State private var checks = Array(repeating: false, count: Terms.attestations.count)
    var body: some View {
        NavigationStack {
            PersonalPage(title: "BEM-VINDO À TUA WHOOP") {
                Text("Versão pessoal independente. Antes de começar, lê e confirma as condições.")
                    .font(PersonalWhoopStyle.body).foregroundStyle(PersonalWhoopStyle.secondary)
                ForEach(Terms.points.indices, id: \.self) { index in
                    PersonalWhoopCard {
                        VStack(alignment: .leading, spacing: PersonalWhoopStyle.gap) {
                            Text(Terms.points[index].0).font(PersonalWhoopStyle.label)
                            Text(Terms.points[index].1).font(PersonalWhoopStyle.body).foregroundStyle(PersonalWhoopStyle.secondary)
                        }
                    }
                }
                PersonalWhoopCard {
                    VStack(spacing: PersonalWhoopStyle.margin) {
                        ForEach(Terms.attestations.indices, id: \.self) { index in
                            Toggle(Terms.attestations[index], isOn: $checks[index])
                        }
                    }.tint(PersonalWhoopStyle.green)
                }
                PersonalAction(title: "ACEITAR E CONTINUAR", icon: "checkmark") { onAccept() }
                    .disabled(!checks.allSatisfy { $0 })
            }
        }.preferredColorScheme(.dark)
    }
}

struct PersonalWhatsNew: View {
    static let revision = "premium-1"
    let onClose: () -> Void
    var body: some View {
        NavigationStack {
            PersonalPage(title: "WHOOP · NOVA EXPERIÊNCIA") {
                PersonalWhoopCard {
                    VStack(alignment: .leading, spacing: PersonalWhoopStyle.section) {
                        Text("O teu ritmo. Mais claro.").font(PersonalWhoopStyle.heading)
                        Label("Interface de vidro com contraste adaptável", systemImage: "square.stack.3d.up")
                        Label("Sincronização e estado da pulseira no Início", systemImage: "arrow.triangle.2.circlepath")
                        Label("Objetivos pessoais e progresso diário", systemImage: "checkmark.circle")
                        Label("Sono e indicadores com os dados locais", systemImage: "moon")
                    }.font(PersonalWhoopStyle.body)
                }
                Text("As medições e estimativas continuam a usar o motor local existente. Esta versão não é a aplicação oficial nem dá acesso aos serviços privados da WHOOP.")
                    .font(PersonalWhoopStyle.body).foregroundStyle(PersonalWhoopStyle.secondary)
                PersonalAction(title: "CONTINUAR", icon: "arrow.right") { onClose() }
            }.toolbar { ToolbarItem(placement: .topBarTrailing) { Button("Fechar", action: onClose) } }
        }.preferredColorScheme(.dark)
    }
}
#endif
