import SwiftUI

struct TotpSetupView: View {
    var body: some View {
        ContentUnavailableView(
            "Usa el código del correo",
            systemImage: "envelope",
            description: Text("Esta cuenta entra con el código de 6 dígitos que envía el servidor.")
        )
    }
}
