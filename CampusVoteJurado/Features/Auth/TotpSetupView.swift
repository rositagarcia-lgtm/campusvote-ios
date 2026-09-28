import SwiftUI

/// El alta del jurado no configura un autenticador.
/// El segundo paso es el código que llega al correo (`TotpView`).
struct TotpSetupView: View {
    var body: some View {
        ContentUnavailableView(
            "Usa el código del correo",
            systemImage: "envelope",
            description: Text("Esta cuenta entra con el código de 6 dígitos que envía el servidor.")
        )
    }
}
