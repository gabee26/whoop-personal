#if os(iOS)
import SwiftUI
import UniformTypeIdentifiers
import StrandDesign

struct PersonalImportScreen: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var repo: Repository
    @State private var choosing = false
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalPage(title: "IMPORTAR HISTÓRICO") {
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.section) {
                    Image(systemName: "square.and.arrow.down").font(S.number)
                    Text("OS TEUS DADOS, NO IPHONE").font(S.heading)
                    Text("Escolhe a exportação ZIP original. A importação utiliza os dados do ficheiro sem exigir uma subscrição nesta aplicação.")
                        .font(S.body).foregroundStyle(S.secondary)
                }
            }
            PersonalAction(title: "IMPORTAR EXPORTAÇÃO WHOOP", icon: "archivebox") {
                pick(apple: false)
            }.disabled(choosing || model.hasActiveImport)
            if let summary = model.whoopImportSummary {
                Text(summary).font(S.body).foregroundStyle(model.whoopImportFailed ? S.red : S.secondary)
            }
            PersonalAction(title: "IMPORTAR EXPORTAÇÃO SAÚDE APPLE", icon: "heart") {
                pick(apple: true)
            }.disabled(choosing || model.hasActiveImport)
            if let summary = model.appleHealthImportSummary {
                Text(summary).font(S.body).foregroundStyle(model.appleHealthImportFailed ? S.red : S.secondary)
            }
            if model.hasActiveImport { ProgressView("A importar os dados…") }
            PersonalWhoopCard {
                VStack(alignment: .leading, spacing: S.gap) {
                    Text("HISTÓRICO DISPONÍVEL").font(S.label)
                    Text("\(repo.days.count) dias · \(repo.sleeps.count) registos de sono").font(S.body)
                    Text("Esta contagem inclui os dados disponíveis, tanto importados como locais.").font(S.label).foregroundStyle(S.secondary)
                }
            }
            NavigationLink { PersonalComparisonScreen() } label: {
                PersonalWhoopCard { Label("COMPARAR INDICADORES", systemImage: "chart.bar.xaxis").font(S.label) }
            }.buttonStyle(.plain)
        }
    }
    private func pick(apple: Bool) {
        guard !choosing, !model.hasActiveImport else { return }
        choosing = true
        Task { @MainActor in
            defer { choosing = false }
            // Reuse the asCopy picker, which materializes iCloud placeholders before import.
            guard let url = await DocumentPicker.importFile([.zip]) else { return }
            if apple { model.importAppleHealth(url: url) }
            else { model.importWhoop(url: url) }
        }
    }
}
#endif
