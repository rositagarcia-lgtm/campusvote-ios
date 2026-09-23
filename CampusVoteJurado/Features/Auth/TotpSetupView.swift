import SwiftUI
import UIKit

/// Primer acceso del jurado: escanear el QR con su app autenticadora,
/// confirmar el primer código y guardar los códigos de respaldo.
///
/// El QR solo existe en este momento: una vez activada la verificación en dos
/// pasos, el backend ya no lo vuelve a entregar. Por eso hay un botón para
/// guardarlo, y por eso los códigos de respaldo son la salida real si pierde
/// el autenticador.
struct TotpSetupView: View {
    @Environment(SessionStore.self) private var session
    @State private var code = ""

    private var yaActivado: Bool {
        !session.backupCodes.isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            ScrollView {
                VStack(spacing: 20) {
                    encabezado

                    if yaActivado {
                        respaldoCard
                        entrarButton
                    } else {
                        qrCard
                        codigoCard
                    }

                    if let message = session.errorMessage {
                        ErrorBanner(message: message)
                            .frame(maxWidth: .infinity)
                    }

                    Label(
                        yaActivado
                            ? "Guarda estos códigos antes de continuar"
                            : "Tu cuenta queda protegida con tu celular",
                        systemImage: "lock"
                    )
                    .font(.caption.italic())
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .task {
            await session.loadSetup()
        }
        .onChange(of: code) { _, nuevo in
            // Con el sexto dígito se activa sola.
            if nuevo.count == 6 {
                activar()
            }
        }
    }

    // MARK: - Partes de la pantalla

    private var topBar: some View {
        HStack {
            if !yaActivado {
                Button {
                    session.cancelCode()
                } label: {
                    Label("Volver al inicio", systemImage: "chevron.left")
                        .font(.subheadline)
                        .foregroundStyle(Color.brand)
                }
            }

            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    private var encabezado: some View {
        VStack(spacing: 8) {
            Text(yaActivado ? "Guarda tus códigos" : "Configura tu acceso")
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            Text(
                yaActivado
                    ? "Son tu única salida si pierdes el autenticador. Cada código sirve una sola vez y no se vuelven a mostrar."
                    : "Es la primera vez que entras. Escanea el código con tu app autenticadora (Google o Microsoft Authenticator) y confirma el número que te muestre."
            )
            .font(.footnote.italic())
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 4)
    }

    // MARK: - Paso 1 · el QR

    private var qrCard: some View {
        VStack(spacing: 14) {
            if let setup = session.setup, let imagen = setup.qrImagen {
                imagen
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: 210, height: 210)
                    .padding(12)
                    .background(RoundedRectangle(cornerRadius: 16).fill(.white))

                ShareLink(
                    item: imagen,
                    preview: SharePreview("Código QR de CampusVote", image: imagen)
                ) {
                    Label("Guardar el QR", systemImage: "square.and.arrow.down")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Color.brandTeal)
                }

                VStack(spacing: 6) {
                    Text("¿No puedes escanearlo? Escribe este código:")
                        .font(.caption.italic())
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    Text(setup.secret)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color.iconTile))
                }
            } else if session.errorMessage != nil {
                // Si el backend falló, no tiene sentido dejar el indicador
                // girando: se ofrece reintentar.
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title)
                        .foregroundStyle(.secondary)

                    Text("No se pudo generar tu código")
                        .font(.subheadline.weight(.semibold))
                        .multilineTextAlignment(.center)

                    Button("Reintentar") {
                        Task { await session.loadSetup() }
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandTeal)
                }
                .frame(height: 210)
            } else {
                ProgressView("Generando tu código…")
                    .font(.caption.italic())
                    .frame(height: 210)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    // MARK: - Paso 2 · el primer código

    private var codigoCard: some View {
        VStack(spacing: 14) {
            Text("Escribe el código que aparece en tu autenticador")
                .font(.footnote.italic())
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            CodeInputView(code: $code)

            Button(action: activar) {
                Group {
                    if session.isWorking {
                        ProgressView()
                            .tint(Color.onBrand)
                    } else {
                        Text("Activar verificación en dos pasos")
                    }
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.onBrand)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color.brand))
            }
            .disabled(!puedeActivar)
            .opacity(puedeActivar || session.isWorking ? 1 : 0.6)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Paso 3 · los códigos de respaldo

    private var respaldoCard: some View {
        VStack(spacing: 10) {
            ForEach(session.backupCodes, id: \.self) { respaldo in
                Text(respaldo)
                    .font(.system(.subheadline, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.iconTile))
            }

            ShareLink(item: session.backupCodes.joined(separator: "\n")) {
                Label("Guardar los códigos", systemImage: "square.and.arrow.down")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.brandTeal)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(18)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.cardBackground))
        .shadow(color: .black.opacity(0.04), radius: 10, y: 3)
    }

    private var entrarButton: some View {
        Button {
            Task { await session.finishSetup() }
        } label: {
            Group {
                if session.isWorking {
                    ProgressView()
                        .tint(Color.onBrand)
                } else {
                    Text("Ya los guardé, entrar")
                }
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.onBrand)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(RoundedRectangle(cornerRadius: 16).fill(Color.brand))
        }
        .disabled(session.isWorking)
    }

    // MARK: - Acciones

    private var puedeActivar: Bool {
        !session.isWorking && session.setup != nil && code.count == 6
    }

    private func activar() {
        guard puedeActivar else { return }
        Task {
            await session.confirmSetup(code)
            // Si el código no era correcto, se limpia para escribir el siguiente.
            if session.errorMessage != nil {
                code = ""
            }
        }
    }
}

private extension TotpSetup {
    /// El backend manda la imagen como "data:image/png;base64,…".
    var qrImagen: Image? {
        guard
            let coma = qrCode.firstIndex(of: ","),
            let datos = Data(
                base64Encoded: String(qrCode[qrCode.index(after: coma)...])
            ),
            let imagen = UIImage(data: datos)
        else {
            return nil
        }
        return Image(uiImage: imagen)
    }
}

#Preview("Configurar el autenticador") {
    TotpSetupView()
        .environment(SessionStore(api: .shared))
}
