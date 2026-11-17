import Foundation

/// Presentation policy only; does not change Bluetooth commands or stored metrics.
enum PersonalConnectionPresentation {
    static func heartRate(connected: Bool, bpm: Int?) -> Int? {
        guard connected, let bpm, bpm > 0 else { return nil }
        return bpm
    }

    static func wantsLive(visible: Bool, active: Bool, connected: Bool, backfilling: Bool) -> Bool {
        visible && active && connected && !backfilling
    }

    static func title(connected: Bool, historyReady: Bool, backfilling: Bool,
                      experimental: Bool, hasError: Bool) -> String {
        if !connected { return "PULSEIRA DESLIGADA" }
        if backfilling { return "A RECEBER HISTÓRICO" }
        if !historyReady { return "LIGADA · HISTÓRICO INDISPONÍVEL" }
        if hasError { return "SINCRONIZAÇÃO INTERROMPIDA" }
        if experimental { return "LIGADA · SEM HISTÓRICO RECEBIDO" }
        return "LIGADA · PRONTA A SINCRONIZAR"
    }
}
