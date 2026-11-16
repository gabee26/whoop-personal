#if os(iOS)
import SwiftUI
import StrandDesign

struct PersonalMetricGuide: View {
    private typealias S = PersonalWhoopStyle
    var body: some View {
        PersonalPage(title: "OS TEUS INDICADORES") {
            explanation("DADOS E CONFIANÇA", "As leituras da pulseira, os valores importados e os registos manuais têm origens diferentes. Sincroniza antes de interpretar um dia. Uma noite em falta não é zero horas de sono. A quantidade de registos não garante a qualidade do sinal.")
            explanation("RECUPERAÇÃO", "O motor local combina desvios de VFC, frequência cardíaca em repouso e outros sinais face ao teu padrão. É um score estimado, com pesos próprios. Não reproduz a fórmula WHOOP ou Amazfit, nem mede diretamente a recuperação dos músculos. O diário mostra a tua sensação separadamente.")
            explanation("ESFORÇO", "O motor acumula carga cardiovascular por intensidade e duração e aplica uma curva logarítmica. A interface transforma a sua escala 0–100 em 0–21. Essa transformação só muda a apresentação; não converte o resultado no esforço oficial WHOOP.")
            explanation("CALORIAS DO DIA", "O cálculo local combina metabolismo de repouso estimado por Harris–Benedict revisto e energia de atividade estimada por Keytel. O valor diário inclui ambos nos períodos cobertos pelos registos; não são apenas calorias ativas e não inclui um cálculo separado da digestão. Lacunas podem reduzir o total. Altura, peso, idade e dados de frequência cardíaca influenciam a estimativa.")
            explanation("SONO", "Duração e fases são estimadas a partir dos sinais disponíveis. A deteção de uma noite e a sua atribuição ao dia devem ser verificadas antes de comparar percentagens. O planeador usa o objetivo escolhido por ti e um tempo para adormecer; não descobre automaticamente quantas horas o teu corpo precisa.")
            explanation("CARGA PERCEBIDA", "Duração em minutos × intensidade sentida de 1 a 10, apenas para sessões concluídas. Ajuda a registar trabalho de guarda-redes, força e esforço que a frequência cardíaca pode representar de forma incompleta. As unidades são próprias: não somes esta carga ao esforço da pulseira.")
            explanation("COMPARAÇÃO", "Compara os mesmos dias com a exportação original WHOOP. A semelhança entre scores não prova precisão fisiológica. Ajustes futuros precisam de ser avaliados em dias que não tenham sido usados para escolher os parâmetros. Sem dados emparelhados, não há um erro medido.")
            NavigationLink("ABRIR COMPARAÇÃO DE DADOS") { PersonalComparisonScreen() }
            NavigationLink("REVER PERFIL") { PersonalProfileScreen() }
        }.font(S.body)
    }
    private func explanation(_ title: String, _ body: String) -> some View {
        PersonalWhoopCard {
            VStack(alignment: .leading, spacing: S.gap) {
                Text(title).font(S.label)
                Text(body).font(S.body).foregroundStyle(S.secondary)
            }
        }
    }
}
#endif
