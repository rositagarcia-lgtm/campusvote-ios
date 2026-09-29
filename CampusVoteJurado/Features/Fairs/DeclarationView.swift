import SwiftUI

struct DeclarationView: View {
    @Environment(SessionStore.self) private var session
    @Environment(FairsStore.self) private var fairsStore
    @Environment(TabBarVisibility.self) private var tabBar
    @State private var viewModel: DeclarationViewModel
    var onSigned: () -> Void
    var onBack: () -> Void

    init(
        fairId: String,
        onSigned: @escaping () -> Void,
        onBack: @escaping () -> Void = {}
    ) {
        _viewModel = State(initialValue: DeclarationViewModel(fairId: fairId))
        self.onSigned = onSigned
        self.onBack = onBack
    }

    private var fair: Fair? {
        (fairsStore.activeFairs + fairsStore.closedFairs)
            .first { $0.fair.id == viewModel.fairId }?
            .fair
    }

    private var contexto: String {
        let org = InstitutionAppearance.name ?? fair?.organizationName
        let site = fair?.siteName
        return [org, site]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if !contexto.isEmpty {
                        Text(contexto)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    Image("banner_principal")
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Label("Requisito obligatorio previo a la evaluación", systemImage: "checkmark.seal")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Color.brand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))

                    Text(viewModel.statementText)
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.08)))

                    HStack(alignment: .center, spacing: 12) {
                        Image(systemName: "person.text.rectangle")
                            .font(.body)
                            .foregroundStyle(Color.brand)
                            .frame(width: 40, height: 40)
                            .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.12)))

                        VStack(alignment: .leading, spacing: 2) {
                            Text("IDENTIDAD DEL JURADO")
                                .font(.caption2.weight(.bold))
                                .tracking(0.4)
                                .foregroundStyle(.secondary)
                            Text(viewModel.jurorName)
                                .font(.subheadline.weight(.semibold))
                            Text(detalleJurado)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.brand.opacity(0.08)))

                    Button {
                        guard viewModel.signedAtDate == nil else { return }
                        viewModel.isToggled.toggle()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: viewModel.isToggled ? "checkmark.square.fill" : "square")
                                .font(.title3)
                                .foregroundStyle(viewModel.isToggled ? Color.brand : Color.secondary)
                            Text("Acepto los términos de la declaración de imparcialidad y ética académica.")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(viewModel.signedAtDate != nil)

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }
        }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            VStack(spacing: 8) {
                Button {
                    Task { @MainActor in
                        let success = await viewModel.submitDeclaration()
                        if success {
                            onSigned()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isSigning {
                            ProgressView()
                                .tint(Color.onBrand)
                        } else {
                            Image(systemName: "signature")
                            Text(viewModel.signedAtDate != nil ? "Continuar" : "Firmar y acceder a la evaluación")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .foregroundStyle(Color.onBrand)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(viewModel.isToggled ? Color.brand : Color.brand.opacity(0.35))
                    )
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.isToggled || viewModel.isSigning)

                if let signedDate = viewModel.signedAtDate {
                    Text("Firmada \(signedDate)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("La firma queda registrada con fecha y hora.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 10)
            .padding(.bottom, 8)
            .background(Color.appBackground)
        }
        .task {
            if case .signedIn(let user) = session.phase {
                viewModel.jurorName = user.fullName
            }
            await viewModel.fetchDeclarationStatus()
            if viewModel.navigateToProjects {
                onSigned()
            }
        }
        .onAppear { tabBar.isHidden = true }
        .onDisappear { tabBar.isHidden = false }
    }

    private var header: some View {
        VStack(spacing: 0) {
            ZStack {
                Text("Declaración")
                    .font(.headline)
                    .foregroundStyle(Color.onBrand)

                HStack {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(Color.onBrand)
                            .frame(width: 28, height: 28, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    Spacer(minLength: 0)
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Rectangle()
                .fill(Color.onBrand.opacity(0.35))
                .frame(height: 0.5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.brand.ignoresSafeArea(edges: .top))
    }

    private var detalleJurado: String {
        if let code = viewModel.institutionalId, !code.isEmpty {
            return "Código \(code) · Jurado calificador"
        }
        return "Jurado calificador"
    }
}
