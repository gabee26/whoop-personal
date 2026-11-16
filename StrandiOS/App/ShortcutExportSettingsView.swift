#if os(iOS)
import SwiftUI
import StrandDesign

/// #155 — the opt-in surface for the Apple-Health-free export. Sideloaded installs (free 7-day
/// signing) can't carry the HealthKit entitlement, so HealthKitBridge never runs for them; this
/// toggle instead has NOOP rewrite Documents/noop_sync.txt on every background transition, and the
/// user's Siri Shortcut reads the file and logs the rows into Apple Health. Default OFF.
struct ShortcutExportSettingsView: View {
    @AppStorage(ShortcutHealthExport.enabledKey) private var enabled = false

    var body: some View {
        PersonalPage(title: "EXPORTAR PARA ATALHOS") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: PersonalWhoopStyle.section) {
                    Image(systemName: "square.and.arrow.up").font(PersonalWhoopStyle.number)
                    Toggle("Exportação para a Saúde da Apple", isOn: $enabled).tint(PersonalWhoopStyle.green)
                    Text("Quando ativa, a aplicação atualiza o ficheiro noop_sync.txt ao passar para segundo plano. Um atalho pode ler esse ficheiro e registar as medições na Saúde da Apple.")
                        .font(PersonalWhoopStyle.body).foregroundStyle(PersonalWhoopStyle.secondary)
                    Text("O nome técnico do ficheiro mantém-se para preservar a compatibilidade com os atalhos existentes.")
                        .font(PersonalWhoopStyle.label).foregroundStyle(PersonalWhoopStyle.secondary)
                }
            }
        }
    }

    private var exportCard: some View {
        StrandCard(padding: 20) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up.on.square.fill")
                        .foregroundStyle(StrandPalette.accent)
                        .accessibilityHidden(true)
                    Text("Shortcuts file export")
                        .font(StrandFont.headline)
                        .foregroundStyle(StrandPalette.textPrimary)
                }
                Toggle(isOn: $enabled) {
                    Text("Export for Shortcuts (Apple Health)")
                        .font(StrandFont.subhead)
                        .foregroundStyle(StrandPalette.textPrimary)
                }
                .toggleStyle(.switch)
                .tint(StrandPalette.accent)
                Text("When this is on, NOOP rewrites a plain-text file (On My iPhone › NOOP › noop_sync.txt) each time you leave the app: one line per 15 minutes of heart rate, HRV and steps, read straight from your strap. Pair it with the Siri Shortcut that reads the file and logs everything into Apple Health (no HealthKit entitlement needed), so it works on sideloaded installs. The setup guide and the pre-built Shortcut live in the project wiki on GitHub.")
                    .font(StrandFont.caption)
                    .foregroundStyle(StrandPalette.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
#endif
