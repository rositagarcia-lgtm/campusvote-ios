import PhotosUI
import SwiftUI
import UIKit

struct ProfileView: View {
    @Environment(\.locale) var locale
    @Environment(SessionStore.self) var session
    @Environment(FairsStore.self) var fairsStore
    @Environment(ProjectsStore.self) var projectsStore
    @Environment(TabBarVisibility.self) private var tabBar

    @State var profile: JuryProfile?
    @State private var localAvatar: UIImage?
    @State private var isLoading = false
    @State private var isLoggingOut = false
    @State private var errorMessage: String?
    @State private var showPhotoMenu = false
    @State private var showInstitution = false
    @State private var showLibrary = false
    @State private var showCamera = false
    @State private var photoItem: PhotosPickerItem?
    @State private var showEdit = false
    @State private var showPassword = false
    @State private var showPreferences = false
    @State private var avatarHidden = ProfileAvatarStore.isHidden

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ProfileHeaderView(
                    greetingName: greetingName,
                    localAvatar: localAvatar,
                    avatarURL: avatarHidden ? nil : profile?.avatarURL,
                    initials: initials,
                    onAvatarTap: { showPhotoMenu = true }
                )

                if let errorMessage {
                    ErrorBanner(message: errorMessage)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                ProfileFairCard(
                    fairName: activeFair?.name,
                    fairDate: activeFairDate,
                    pendingLine: pendingLine
                )

                ProfileShortcutView(
                    isEnabled: profile != nil,
                    onTap: { showEdit = true }
                )

                ProfileProgressCard(
                    rated: projectsStore.summary.rated,
                    total: projectsStore.summary.total,
                    progressValue: progressValue,
                    rubricLine: rubricLine
                )

                ProfileSettingsCard(
                    onPassword: { showPassword = true },
                    onPreferences: { showPreferences = true }
                )

                ProfileLogoutButton(
                    isLoggingOut: isLoggingOut,
                    action: logout
                )
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 28)
        }
        .safeAreaInset(edge: .top, spacing: 0) { OrganizationHeader(title: "Perfil") }
        .background(Color.appBackground.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .navigationDestination(isPresented: $showPreferences) {
            PreferencesView()
        }
        .task { await reload() }
        .onChange(of: showPhotoMenu) { _, _ in syncTabBar() }
        .onChange(of: showInstitution) { _, _ in syncTabBar() }
        .onChange(of: showPreferences) { _, _ in syncTabBar() }
        .onDisappear {
            if !showPreferences { tabBar.isHidden = false }
        }
        .overlay {
            if showPhotoMenu {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showPhotoMenu = false }

                    PhotoSourceSheet(
                        avatar: localAvatar,
                        avatarURL: avatarHidden ? nil : profile?.avatarURL,
                        initials: initials,
                        onClose: { showPhotoMenu = false },
                        onCamera: {
                            showPhotoMenu = false
                            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                showCamera = true
                            }
                        },
                        onGallery: {
                            showPhotoMenu = false
                            showLibrary = true
                        },
                        onDelete: {
                            showPhotoMenu = false
                            deleteAvatar()
                        }
                    )
                }
                .ignoresSafeArea()
            }
        }
        .overlay {
            if showInstitution {
                ZStack(alignment: .bottom) {
                    Color.black.opacity(0.35)
                        .ignoresSafeArea()
                        .onTapGesture { showInstitution = false }

                    InstitutionSheet(
                        code: institutionCode,
                        name: institutionName,
                        site: institutionSite,
                        badge: institutionBadge,
                        onClose: { showInstitution = false }
                    )
                }
                .ignoresSafeArea()
            }
        }
        .photosPicker(isPresented: $showLibrary, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await applyLibraryPhoto(item) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                storeAvatar(image)
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showEdit) {
            if let profile {
                EditProfileSheet(profile: profile) { updated in
                    self.profile = updated
                }
                .juryBottomSheet(background: Color.appBackground)
            }
        }
        .sheet(isPresented: $showPassword) {
            ChangePasswordSheet()
                .juryBottomSheet(background: Color.appBackground)
        }
    }

    private func syncTabBar() {
        tabBar.isHidden = showPhotoMenu || showInstitution || showPreferences
    }

    @MainActor
    private func reload() async {
        if profile == nil, let user = signedInUser {
            profile = JuryProfile(user: user)
        }
        await load()
        if fairsStore.activeFairs.isEmpty && fairsStore.closedFairs.isEmpty {
            await fairsStore.fetchMyAssignments()
        }
        if let fairId = activeFair?.id {
            await projectsStore.load(fairId: fairId)
        }
    }

    @MainActor
    private func load() async {
        isLoading = profile == nil
        errorMessage = nil
        defer { isLoading = false }
        localAvatar = ProfileAvatarStore.load()
        avatarHidden = ProfileAvatarStore.isHidden
        do {
            profile = try await APIClient.shared.send(
                Endpoint(path: "users/me", method: "GET"),
                as: JuryProfile.self
            )
        } catch {
            if let user = signedInUser {
                profile = JuryProfile(user: user)
            }
            errorMessage = error.userMessage
        }
    }

    private func applyLibraryPhoto(_ item: PhotosPickerItem) async {
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        storeAvatar(image)
    }

    private func storeAvatar(_ image: UIImage) {
        localAvatar = image
        avatarHidden = false
        ProfileAvatarStore.save(image)
    }

    private func deleteAvatar() {
        localAvatar = nil
        avatarHidden = true
        ProfileAvatarStore.delete()
    }

    private func logout() {
        isLoggingOut = true
        Task { await session.logout() }
    }
}
