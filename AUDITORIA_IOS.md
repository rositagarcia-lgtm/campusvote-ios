# Auditoría funcional y técnica de CampusVote iOS

**Corte:** 22 de octubre de 2026 · **Repositorio:** `C:\campusvote-ios` · **Rama revisada:** `develop` (`92c1e23`)
**Alcance:** lectura del proyecto nativo iOS y verificación estática local. Este documento reúne todos los módulos en un solo archivo. Las rutas enlazadas son relativas a este informe. No se ejecutó la app ni se compiló con Xcode en este entorno Windows.

## 1. Visión general

`CampusVoteJurado` es la app SwiftUI para personas con rol `JURY` y docentes `TEACHER` asignados a ferias. Permite iniciar sesión, consultar ferias y proyectos autorizados, valorar proyectos con 1–5 estrellas y un comentario, ver el avance personal y gestionar el perfil. El proyecto exige iOS 17, usa el identificador `pe.campusvote.CampusVoteJurado` y consume un backend HTTPS bajo `/api`. La app contiene un único target de aplicación; no se identificó un target de pruebas XCTest en `project.pbxproj`.

| Capa | Responsabilidad | Entrada principal |
|---|---|---|
| App y navegación | Estados de sesión, onboarding y cuatro pestañas | [CampusVoteJuradoApp.swift](CampusVoteJurado/App/CampusVoteJuradoApp.swift), [RootView.swift](CampusVoteJurado/App/RootView.swift) |
| Estado | Sesión, ferias, proyectos y reseñas observables | [Stores](CampusVoteJurado/Stores) |
| Red | Endpoints, transporte, decodificación, refresh y errores | [Networking](CampusVoteJurado/Core/Networking) |
| Persistencia | Tokens, usuario y marca institucional | [Storage](CampusVoteJurado/Core/Storage) |
| Interfaz | Autenticación, ferias, catálogo, detalle, avance y perfil | [Features](CampusVoteJurado/Features) |
| Recursos | Idiomas, colores, imágenes y configuración Xcode | [Localizable.xcstrings](CampusVoteJurado/Localizable.xcstrings), [Assets.xcassets](CampusVoteJurado/Assets.xcassets), [project.pbxproj](CampusVoteJurado.xcodeproj/project.pbxproj) |

Flujo principal: `App` crea los stores → `RootView` restaura sesión → login/OTP/cambio de contraseña si corresponde → onboarding por usuario → `MainTabView` → feria asignada → lista protegida de proyectos → detalle → lectura de reseña propia → guardado de estrellas y comentario → actualización del avance.

## 2. Arranque, navegación y primer uso

**Archivos:** [CampusVoteJuradoApp.swift](CampusVoteJurado/App/CampusVoteJuradoApp.swift), [RootView.swift](CampusVoteJurado/App/RootView.swift), [MainTabView.swift](CampusVoteJurado/App/MainTabView.swift), [TabBarVisibility.swift](CampusVoteJurado/App/TabBarVisibility.swift), [SplashView.swift](CampusVoteJurado/Features/Auth/Splash/SplashView.swift), [JuryOnboardingView.swift](CampusVoteJurado/Features/Auth/Onboarding/JuryOnboardingView.swift).

- `CampusVoteJuradoApp` comparte `SessionStore`, `FairsStore` y `ProjectsStore` por el entorno SwiftUI. Al pasar a `signedOut` limpia los datos de ferias y proyectos y restablece la barra de pestañas. Lee apariencia, idioma y tamaño de texto desde `AppStorage`.
- `RootView` mantiene el splash al menos 2,2 segundos mientras llama a `restore()`. Después representa una de cinco fases: comprobación, fuera de sesión, OTP, cambio obligatorio de contraseña o sesión iniciada. La vista autenticada se identifica con `user.id`, de modo que el árbol visual se reinicia al cambiar de cuenta.
- `SignedInExperience` guarda `campusvote.onboarding.v1.<user.id>`. El onboarding tiene tres páginas sobre uso del panel, reseñas y visibilidad del comentario; se marca como visto al pulsar «Saltar» o «Empezar». Incluye foco VoiceOver, desplazamiento para texto amplio y reducción de movimiento.
- `MainTabView` presenta Ferias, Avance, Asignados y Perfil. La barra inferior es propia, mide su altura y puede ocultarse desde pantallas superpuestas.

## 3. Autenticación, permisos y ciclo de sesión

**Archivos:** [SessionStore.swift](CampusVoteJurado/Stores/Session/SessionStore.swift), [SessionStore+Auth.swift](CampusVoteJurado/Stores/Session/SessionStore+Auth.swift), [JuryAccessType.swift](CampusVoteJurado/Stores/Session/JuryAccessType.swift), [LoginView.swift](CampusVoteJurado/Features/Auth/Login/LoginView.swift), [TotpView.swift](CampusVoteJurado/Features/Auth/Otp/TotpView.swift), [ChangePasswordView.swift](CampusVoteJurado/Features/Auth/Password/ChangePasswordView.swift), [User.swift](CampusVoteJurado/Models/User.swift).

1. **Ingreso externo:** correo normalizado a minúsculas + contraseña → `POST auth/login`. Si el backend pide verificación, la respuesta aporta un token temporal y se abre OTP.
2. **Docente interno:** `POST auth/email/request` solicita un código; `POST auth/email/login-verify` envía seis dígitos con el token temporal. `POST auth/email/resend` permite reenviar. La pantalla de OTP puede cancelar y volver al login.
3. **Autorización local tras login:** `finish()` exige access token, refresh token y usuario. Acepta únicamente roles de jurado/docente y comprueba que la primera página de `/fairs/my-assignments` contenga al menos una asignación. Sin asignaciones muestra un error específico.
4. **Contraseña temporal:** si `mustChangePassword` está activo, la fase obliga a `POST users/me/password` antes del panel; al responder con éxito actualiza la copia del usuario.
5. **Restauración:** lee token del Keychain y usuario cacheado para presentar la sesión; valida luego con `GET auth/me` y la asignación. Ante un fallo transitorio conserva la sesión cacheada para que cada pantalla reintente; ante rechazo de sesión elimina tokens y cache. Una generación de sesión evita que respuestas antiguas cambien la sesión nueva.
6. **Salida:** captura los tokens, limpia estado local inmediatamente y después intenta `POST auth/logout`. La app descarta los stores al cambiar a `signedOut`.

**Límite de seguridad:** los controles de rol y fase en SwiftUI son una ayuda de interfaz; los endpoints protegidos deben mantener la autorización definitiva en el servidor. Este informe no ejecutó pruebas de permisos contra el backend desplegado.

## 4. Red, contrato API y manejo de errores

**Archivos:** [APIConfig.swift](CampusVoteJurado/Core/Networking/APIConfig.swift), [Endpoint.swift](CampusVoteJurado/Core/Networking/Endpoint.swift), [APIClient.swift](CampusVoteJurado/Core/Networking/APIClient.swift), [APIClient+Assignments.swift](CampusVoteJurado/Core/Networking/APIClient+Assignments.swift), [APIClient+Errors.swift](CampusVoteJurado/Core/Networking/APIClient+Errors.swift), [APITransport.swift](CampusVoteJurado/Core/Networking/APITransport.swift), [RefreshCoordinator.swift](CampusVoteJurado/Core/Networking/RefreshCoordinator.swift), [Pagination.swift](CampusVoteJurado/Core/Networking/Pagination.swift), [JSONCoding.swift](CampusVoteJurado/Core/Networking/JSONCoding.swift), [APIError.swift](CampusVoteJurado/Core/Networking/APIError.swift).

La URL de producción está fijada en `https://campusvote-rg13.onrender.com/api`. `APIClient` usa una sesión URLSession efímera, cuerpo y aceptación JSON, `Accept-Language` ES/EN y Bearer del Keychain o token temporal explícito. Espera sobres `{success,message,data}`; en páginas acepta `pagination` o `meta.pagination`. `allAssignments()` recorre todas las páginas de 100 resultados y elimina IDs duplicados.

Ante HTTP 401, el cliente primero detecta si otra petición ya renovó el access token; si hace falta, `RefreshCoordinator` comparte una única renovación por refresh token y reintenta la operación una vez. Solo un rechazo de tokens invalida la sesión; un fallo de red, 429 o 5xx conserva el estado. Los errores de contenido 403 se muestran sin cerrar sesión. `APIClient+Errors` interpreta códigos/mensajes de error anidados o planos y aporta mensajes de respaldo.

| Método y ruta relativa a `/api` | Uso en iOS |
|---|---|
| `POST auth/login`, `POST auth/email/request`, `POST auth/email/login-verify`, `POST auth/email/resend` | Acceso con contraseña o código de correo. |
| `GET auth/me`, `POST auth/refresh`, `POST auth/logout` | Revalidar, renovar y cerrar sesión. El refresh y logout envían `refreshToken`. |
| `POST users/me/password`, `GET/PUT users/me` | Cambio de contraseña y lectura/edición de nombres del perfil. |
| `GET organizations/:id` | Marca de la institución del usuario autenticado. |
| `GET fairs/my-assignments?page=N&limit=100` | Validación inicial y lista completa de ferias propias. |
| `GET fairs/my-assignments/:fairId` | Revalidar fase y permisos antes del detalle. |
| `GET fairs/my-projects` | Proyectos de categorías asignadas entre ferias para «Asignados». |
| `GET fairs/:fairId/review-projects[?scope=all]` | Catálogo de evaluación; `all` solo se ofrece en LIVE. |
| `GET fairs/:fairId/projects/:projectId` | Ficha protegida, integrantes y multimedia. |
| `GET/PUT fairs/:fairId/projects/:projectId/rating` | Leer y guardar la reseña propia. `PUT` envía `{rating,comment}`. |

El contrato de esta tabla se extrajo de la app; la compatibilidad extremo a extremo requiere un entorno de integración con cuentas de prueba y fases reales.

## 5. Persistencia, privacidad y marca institucional

**Archivos:** [KeychainStore.swift](CampusVoteJurado/Core/Storage/KeychainStore.swift), [SessionArchive.swift](CampusVoteJurado/Core/Storage/SessionArchive.swift), [BrandArchive.swift](CampusVoteJurado/Core/Storage/BrandArchive.swift), [InstitutionBrandState.swift](CampusVoteJurado/Core/DesignSystem/InstitutionBrandState.swift), [OrganizationHeader.swift](CampusVoteJurado/Core/DesignSystem/OrganizationHeader.swift), [Colors.swift](CampusVoteJurado/Core/DesignSystem/Colors.swift).

- Los access y refresh tokens se guardan en Keychain, servicio `com.campusvote.jurado`, con accesibilidad «después del primer desbloqueo, solo en este dispositivo». `SessionArchive` guarda el usuario serializado en `UserDefaults` para restauración visual rápida; al cerrar sesión se borra.
- `BrandArchive` separa la marca por usuario y organización. Al entrar aplica la copia local y después actualiza con `GET organizations/:id`; si no hay organización o falla la carga utiliza la marca CampusVote. `InstitutionAppearance`, `OrganizationHeader` y los colores del sistema de diseño propagan nombre, logo y acento a las pantallas autenticadas.
- El onboarding separa su estado por ID de usuario. El avatar local también se separa por usuario y se elimina al cerrar o expirar la sesión, según la corrección H1.

## 6. Ferias y fases de evaluación

**Archivos:** [FairsStore.swift](CampusVoteJurado/Stores/FairsStore.swift), [Fair.swift](CampusVoteJurado/Models/Fair.swift), [ReviewAccess.swift](CampusVoteJurado/Models/ReviewAccess.swift), [FairListView.swift](CampusVoteJurado/Features/Fairs/FairListView.swift), [FairsSectionView.swift](CampusVoteJurado/Features/Fairs/FairsSectionView.swift), [FairRowView.swift](CampusVoteJurado/Features/Fairs/FairRowView.swift), [FairReviewNotice.swift](CampusVoteJurado/Features/Fairs/FairReviewNotice.swift).

`FairsStore` descarga todas las asignaciones, clasifica ferias activas (`LIVE`), programadas y cerradas (`ENDED`), y descarta respuestas obsoletas con un identificador de solicitud. La pantalla «Ferias» presenta esas tres secciones, estados de carga/error/vacío, reintento y actualización manual. Una feria programada solo abre su catálogo cuando `allowsBrowsing` es verdadero.

| Fase | Catálogo | Guardar valoración | Tratamiento |
|---|---|---|---|
| `BEFORE_PREVIEW` | Cerrado | No | Aviso hasta el fin de inscripción. |
| `PREVIEW` | Lectura | No | Aviso de fecha de apertura si existe. |
| `LIVE` | Lectura; categorías propias o toda la feria | Sí, si `can_review != false` | Muestra formulario y QR. |
| `ENDED` | Lectura | No | Feria cerrada; sin formulario. |

`ReviewAccess` traduce estados anteriores (`OPEN`→`LIVE`, `CLOSED`→`ENDED`); una fase desconocida se trata de forma restrictiva como `BEFORE_PREVIEW`. El detalle vuelve a consultar la asignación antes de cargar contenido, por lo que no depende solo de una fase cacheada.

## 7. Catálogo, asignados y búsqueda por QR

**Archivos:** [ProjectsStore.swift](CampusVoteJurado/Stores/ProjectsStore.swift), [ProjectListView.swift](CampusVoteJurado/Features/Projects/List/ProjectListView.swift), [ProjectListFilters.swift](CampusVoteJurado/Features/Projects/List/ProjectListFilters.swift), [ProjectListFilterSheet.swift](CampusVoteJurado/Features/Projects/List/ProjectListFilterSheet.swift), [ProjectsViewModel.swift](CampusVoteJurado/Features/Projects/List/ProjectsViewModel.swift), [MyProjectsView.swift](CampusVoteJurado/Features/Projects/Assigned/MyProjectsView.swift), [QRScannerView.swift](CampusVoteJurado/Features/Projects/Catalog/QRScannerView.swift), [QRCodePayload.swift](CampusVoteJurado/Features/Projects/Catalog/QRCodePayload.swift), [ReviewProject.swift](CampusVoteJurado/Models/ReviewProject.swift).

`ProjectsStore.load(fairId:scope:)` carga `review-projects`, resumen y categorías; conserva el alcance efectivo devuelto por el servidor. La pantalla filtra localmente por texto (nombre/categoría), categoría y estado pendiente/con reseña. En LIVE ofrece «Mis categorías» y «Toda la feria»; al salir de LIVE vuelve al alcance asignado. Recarga al reactivar la app o al deslizar y evita aplicar respuestas tardías tras cambiar de feria o cerrar sesión.

«Asignados» usa `GET fairs/my-projects` para reunir los proyectos de categorías propias; la interfaz también permite explorar ferias navegables. El QR aparece solo cuando se puede evaluar. El analizador acepta identificadores en texto, JSON o URL, verifica que la feria del código coincida cuando esté presente y abre el detalle protegido con el ID extraído; no navega a la URL incluida en el QR.

## 8. Ficha, multimedia y reseñas

**Archivos:** [ProjectDetailView.swift](CampusVoteJurado/Features/Projects/Detail/ProjectDetailView.swift), [ProjectDetailView+Loading.swift](CampusVoteJurado/Features/Projects/Detail/ProjectDetailView+Loading.swift), [ProjectReviewCard.swift](CampusVoteJurado/Features/Projects/Detail/ProjectReviewCard.swift), [ProjectsStore+Reviews.swift](CampusVoteJurado/Stores/ProjectsStore+Reviews.swift), [ProjectDetail.swift](CampusVoteJurado/Models/Project/ProjectDetail.swift), [Review.swift](CampusVoteJurado/Models/Review.swift), [ProjectMembersCard.swift](CampusVoteJurado/Features/Projects/Detail/ProjectMembersCard.swift), [ProjectMediaLinks.swift](CampusVoteJurado/Features/Projects/Detail/ProjectMediaLinks.swift), [ProjectGalleryBanner.swift](CampusVoteJurado/Features/Projects/Detail/ProjectGalleryBanner.swift), [PhotoViewer.swift](CampusVoteJurado/Features/Projects/Detail/PhotoViewer.swift).

El detalle consulta primero la asignación de esa feria, comprueba que ya se puede navegar y pide la ficha protegida. Construye portada y galería sin duplicar URLs ni usar el logo como foto de proyecto, muestra integrantes y enlaces, y mantiene un resaltado local de aspectos por usuario/proyecto. En LIVE pide la reseña del usuario antes de habilitar «Guardar»; un error en esa lectura deja el botón deshabilitado y permite reintento, evitando sobrescribir una reseña desconocida.

`saveRating()` valida estrellas de 1 a 5 y comentario recortado de 10 a 1000 **unidades UTF-16**, coherente con una longitud JavaScript. Envía `PUT rating` y actualiza las listas y contadores de catálogo y asignados. Si el backend responde `REVIEW_NOT_OPEN_YET` o `REVIEW_CLOSED`, el store ajusta la fase y presenta el error. No hay voto, like ni rúbrica enviada desde esta app.

## 9. Avance personal

**Archivos:** [MyProgressView.swift](CampusVoteJurado/Features/Evaluation/MyProgressView.swift), [MyProgressSummaryCard.swift](CampusVoteJurado/Features/Evaluation/MyProgressSummaryCard.swift), [PendingProjectCard.swift](CampusVoteJurado/Features/Evaluation/PendingProjectCard.swift), [RatedProjectCard.swift](CampusVoteJurado/Features/Evaluation/RatedProjectCard.swift).

«Avance» opera sobre ferias activas y el catálogo de categorías asignadas. Permite elegir feria, separa pendientes y valorados, calcula porcentaje `valorados/total` y media local de las estrellas propias; cada tarjeta abre el detalle. Incluye carga, error con reintento, vacío y actualización manual. La media mostrada es personal y calculada en el dispositivo, no una calificación global del proyecto.

## 10. Perfil, cuenta y preferencias

**Archivos:** [ProfileView.swift](CampusVoteJurado/Features/Auth/Profile/ProfileView.swift), [ProfileModels.swift](CampusVoteJurado/Features/Auth/Profile/ProfileModels.swift), [ProfileHeaderView.swift](CampusVoteJurado/Features/Auth/Profile/ProfileHeaderView.swift), [EditProfileSheet.swift](CampusVoteJurado/Features/Auth/Profile/EditProfileSheet.swift), [ChangePasswordSheet.swift](CampusVoteJurado/Features/Auth/Profile/ChangePasswordSheet.swift), [ProfileAvatarStore.swift](CampusVoteJurado/Features/Auth/Profile/ProfileAvatarStore.swift), [PreferencesView.swift](CampusVoteJurado/Features/Auth/Preferences/PreferencesView.swift).

El perfil carga `GET users/me`, usa el usuario de sesión como respaldo si falla y enseña feria/progreso, institución y ajustes. `EditProfileSheet` modifica nombres con `PUT users/me`; documento y correo son de solo lectura. La hoja de seguridad cambia contraseña. Cámara y fototeca permiten elegir un avatar **local**, ahora separado por ID de usuario; el JPEG no se envía al backend y tiene prioridad sobre el avatar remoto en el encabezado. Borrar el avatar elimina el archivo y oculta el remoto mediante una preferencia local de esa cuenta. El cierre de sesión elimina su avatar local.

Preferencias persiste aspecto claro/oscuro, texto normal/pequeño/grande e idioma español/inglés. La app aplica estas opciones a la escena; la localización depende del catálogo `Localizable.xcstrings` y de `L10n`.

## 11. Internacionalización, diseño y accesibilidad

**Archivos:** [L10n.swift](CampusVoteJurado/Core/Localization/L10n.swift), [Localizable.xcstrings](CampusVoteJurado/Localizable.xcstrings), [Colors.swift](CampusVoteJurado/Core/DesignSystem/Colors.swift), [OrganizationHeader.swift](CampusVoteJurado/Core/DesignSystem/OrganizationHeader.swift), [PremiumSurface.swift](CampusVoteJurado/Core/DesignSystem/PremiumSurface.swift), [ErrorBanner.swift](CampusVoteJurado/Core/DesignSystem/ErrorBanner.swift), [Assets.xcassets](CampusVoteJurado/Assets.xcassets).

Se contabilizan 339 claves traducidas ES/EN por el verificador. La barra y varias acciones aseguran áreas táctiles de 44 pt; onboarding y otros componentes incluyen etiquetas/accesibilidad. `Colors` adapta la marca institucional y define fondos/superficies; `AsyncImage` tiene respaldos locales. La revisión estática no confirma por sí sola el aspecto con Dynamic Type extremo, VoiceOver, contraste ni todas las rutas de idiomas; requieren prueba visual en iPhone.

## 12. Hallazgos y mejoras priorizadas

| ID / prioridad | Evidencia y efecto | Acción recomendada |
|---|---|---|
| **H1 · Corregido en código · avatar entre cuentas** | [ProfileAvatarStore.swift](CampusVoteJurado/Features/Auth/Profile/ProfileAvatarStore.swift) usa un nombre de archivo derivado del ID de usuario y una preferencia separada. El archivo compartido anterior se descarta sin asignarlo a otra cuenta; [SessionStore.swift](CampusVoteJurado/Stores/Session/SessionStore.swift) elimina el avatar al salir o expirar la sesión. | Falta confirmar A→B→A en un iPhone con Xcode. |
| **H2 · Baja · configuración de servidor fija** | [APIConfig.swift](CampusVoteJurado/Core/Networking/APIConfig.swift) contiene una URL de producción en el código y un comentario de simulador con `/ap` que no coincide con `/api`. Esto dificulta pruebas contra staging/local y puede inducir una configuración equivocada. | Definir URL por configuración de build (`xcconfig`/Info.plist) y corregir el comentario con una URL local real. |
| **H3 · Media · cobertura automatizada ausente** | [project.pbxproj](CampusVoteJurado.xcodeproj/project.pbxproj) declara solo el target de app. El [verificador](scripts/verify_project.py) comprueba registro, estructura, traducciones y delimitadores, pero no compila ni ejecuta lógica de sesión, fases, QR o validación. | Añadir target XCTest y pruebas para `ReviewAccess`, `QRCodePayload`, refresh concurrente, sesión por cuenta y validación de reseñas; ejecutar build/UI smoke test en CI macOS. |

H1 se corrigió en el código durante esta revisión; H2 y H3 permanecen como mejoras. La corrección de H1 aún requiere compilación y prueba en dispositivo.

## 13. Inventario de archivos Swift por módulo

El inventario siguiente cubre los **94 Swift** del target. Cada nombre apunta al archivo real; se agrupan auxiliares visuales bajo la lógica del módulo explicada arriba.

| Módulo | Archivos y función |
|---|---|
| App | [CampusVoteJuradoApp.swift](CampusVoteJurado/App/CampusVoteJuradoApp.swift) (inyección y preferencias), [RootView.swift](CampusVoteJurado/App/RootView.swift) (fases), [MainTabView.swift](CampusVoteJurado/App/MainTabView.swift) (pestañas), [TabBarVisibility.swift](CampusVoteJurado/App/TabBarVisibility.swift) (ocultación). |
| Auth: acceso | [LoginView.swift](CampusVoteJurado/Features/Auth/Login/LoginView.swift), [LoginHeader.swift](CampusVoteJurado/Features/Auth/Login/LoginHeader.swift), [LoginFieldRow.swift](CampusVoteJurado/Features/Auth/Login/LoginFieldRow.swift), [LoginAccessTypeSelector.swift](CampusVoteJurado/Features/Auth/Login/LoginAccessTypeSelector.swift) (formulario y tipo de acceso); [TotpView.swift](CampusVoteJurado/Features/Auth/Otp/TotpView.swift), [CodeInputView.swift](CampusVoteJurado/Features/Auth/Otp/CodeInputView.swift) (OTP); [ChangePasswordView.swift](CampusVoteJurado/Features/Auth/Password/ChangePasswordView.swift) (cambio obligatorio); [SplashView.swift](CampusVoteJurado/Features/Auth/Splash/SplashView.swift) (carga); [JuryOnboardingView.swift](CampusVoteJurado/Features/Auth/Onboarding/JuryOnboardingView.swift) (primer uso). |
| Auth: perfil | [ProfileView.swift](CampusVoteJurado/Features/Auth/Profile/ProfileView.swift), [ProfileView+Presentation.swift](CampusVoteJurado/Features/Auth/Profile/ProfileView+Presentation.swift), [ProfileModels.swift](CampusVoteJurado/Features/Auth/Profile/ProfileModels.swift), [ProfileHeaderView.swift](CampusVoteJurado/Features/Auth/Profile/ProfileHeaderView.swift), [ProfileDashboardViews.swift](CampusVoteJurado/Features/Auth/Profile/ProfileDashboardViews.swift), [ProfileSettingsViews.swift](CampusVoteJurado/Features/Auth/Profile/ProfileSettingsViews.swift), [ProfileSheetComponents.swift](CampusVoteJurado/Features/Auth/Profile/ProfileSheetComponents.swift) (datos, cabecera y tarjetas); [EditProfileSheet.swift](CampusVoteJurado/Features/Auth/Profile/EditProfileSheet.swift), [ChangePasswordSheet.swift](CampusVoteJurado/Features/Auth/Profile/ChangePasswordSheet.swift), [InstitutionSheet.swift](CampusVoteJurado/Features/Auth/Profile/InstitutionSheet.swift) (hojas); [ProfileAvatarStore.swift](CampusVoteJurado/Features/Auth/Profile/ProfileAvatarStore.swift), [PhotoSourceSheet.swift](CampusVoteJurado/Features/Auth/Profile/PhotoSourceSheet.swift), [CameraPicker.swift](CampusVoteJurado/Features/Auth/Profile/CameraPicker.swift) (foto). |
| Preferencias | [PreferencesView.swift](CampusVoteJurado/Features/Auth/Preferences/PreferencesView.swift) (apariencia, texto e idioma). |
| Ferias | [FairListView.swift](CampusVoteJurado/Features/Fairs/FairListView.swift), [FairListHeaderView.swift](CampusVoteJurado/Features/Fairs/FairListHeaderView.swift), [FairsSectionView.swift](CampusVoteJurado/Features/Fairs/FairsSectionView.swift), [FairRowView.swift](CampusVoteJurado/Features/Fairs/FairRowView.swift), [FairReviewNotice.swift](CampusVoteJurado/Features/Fairs/FairReviewNotice.swift) (listado, filas y fase). |
| Proyectos: catálogo | [ProjectListView.swift](CampusVoteJurado/Features/Projects/List/ProjectListView.swift), [ProjectsViewModel.swift](CampusVoteJurado/Features/Projects/List/ProjectsViewModel.swift), [ProjectListFilters.swift](CampusVoteJurado/Features/Projects/List/ProjectListFilters.swift), [ProjectListFilterSheet.swift](CampusVoteJurado/Features/Projects/List/ProjectListFilterSheet.swift), [ProjectCoverCard.swift](CampusVoteJurado/Features/Projects/List/ProjectCoverCard.swift) (búsqueda y tarjetas); [QRScannerView.swift](CampusVoteJurado/Features/Projects/Catalog/QRScannerView.swift), [QRCodePayload.swift](CampusVoteJurado/Features/Projects/Catalog/QRCodePayload.swift) (escaneo y parseo). |
| Proyectos: asignados | [MyProjectsView.swift](CampusVoteJurado/Features/Projects/Assigned/MyProjectsView.swift), [AssignedSummaryCard.swift](CampusVoteJurado/Features/Projects/Assigned/AssignedSummaryCard.swift), [AssignedProjectsListView.swift](CampusVoteJurado/Features/Projects/Assigned/AssignedProjectsListView.swift), [AssignedProjectRow.swift](CampusVoteJurado/Features/Projects/Assigned/AssignedProjectRow.swift) (resumen/lista). |
| Proyectos: detalle | [ProjectDetailView.swift](CampusVoteJurado/Features/Projects/Detail/ProjectDetailView.swift), [ProjectDetailView+Loading.swift](CampusVoteJurado/Features/Projects/Detail/ProjectDetailView+Loading.swift), [ProjectDetailHeader.swift](CampusVoteJurado/Features/Projects/Detail/ProjectDetailHeader.swift), [ProjectReviewCard.swift](CampusVoteJurado/Features/Projects/Detail/ProjectReviewCard.swift), [ProjectMembersCard.swift](CampusVoteJurado/Features/Projects/Detail/ProjectMembersCard.swift), [ProjectMediaLinks.swift](CampusVoteJurado/Features/Projects/Detail/ProjectMediaLinks.swift), [ProjectGalleryBanner.swift](CampusVoteJurado/Features/Projects/Detail/ProjectGalleryBanner.swift), [PhotoViewer.swift](CampusVoteJurado/Features/Projects/Detail/PhotoViewer.swift), [ChipFlow.swift](CampusVoteJurado/Features/Projects/Detail/ChipFlow.swift) (ficha y multimedia). |
| Evaluación | [MyProgressView.swift](CampusVoteJurado/Features/Evaluation/MyProgressView.swift), [MyProgressSummaryCard.swift](CampusVoteJurado/Features/Evaluation/MyProgressSummaryCard.swift), [PendingProjectCard.swift](CampusVoteJurado/Features/Evaluation/PendingProjectCard.swift), [RatedProjectCard.swift](CampusVoteJurado/Features/Evaluation/RatedProjectCard.swift) (avance). |
| Stores | [SessionStore.swift](CampusVoteJurado/Stores/Session/SessionStore.swift), [SessionStore+Auth.swift](CampusVoteJurado/Stores/Session/SessionStore+Auth.swift), [JuryAccessType.swift](CampusVoteJurado/Stores/Session/JuryAccessType.swift) (sesión); [FairsStore.swift](CampusVoteJurado/Stores/FairsStore.swift) (ferias); [ProjectsStore.swift](CampusVoteJurado/Stores/ProjectsStore.swift), [ProjectsStore+Reviews.swift](CampusVoteJurado/Stores/ProjectsStore+Reviews.swift) (proyectos/reseñas). |
| Modelos | [User.swift](CampusVoteJurado/Models/User.swift), [Fair.swift](CampusVoteJurado/Models/Fair.swift), [ReviewAccess.swift](CampusVoteJurado/Models/ReviewAccess.swift), [ReviewProject.swift](CampusVoteJurado/Models/ReviewProject.swift), [Review.swift](CampusVoteJurado/Models/Review.swift), [Project.swift](CampusVoteJurado/Models/Project/Project.swift), [ProjectDetail.swift](CampusVoteJurado/Models/Project/ProjectDetail.swift), [ProjectTaxonomy.swift](CampusVoteJurado/Models/Project/ProjectTaxonomy.swift) (decodificación y dominio). |
| Networking | [APIConfig.swift](CampusVoteJurado/Core/Networking/APIConfig.swift), [Endpoint.swift](CampusVoteJurado/Core/Networking/Endpoint.swift), [APIClient.swift](CampusVoteJurado/Core/Networking/APIClient.swift), [APIClient+Assignments.swift](CampusVoteJurado/Core/Networking/APIClient+Assignments.swift), [APIClient+Errors.swift](CampusVoteJurado/Core/Networking/APIClient+Errors.swift), [APITransport.swift](CampusVoteJurado/Core/Networking/APITransport.swift), [APIError.swift](CampusVoteJurado/Core/Networking/APIError.swift), [RefreshCoordinator.swift](CampusVoteJurado/Core/Networking/RefreshCoordinator.swift), [Pagination.swift](CampusVoteJurado/Core/Networking/Pagination.swift), [JSONCoding.swift](CampusVoteJurado/Core/Networking/JSONCoding.swift), [SessionNotifications.swift](CampusVoteJurado/Core/Networking/SessionNotifications.swift) (HTTP y sesión). |
| Persistencia | [KeychainStore.swift](CampusVoteJurado/Core/Storage/KeychainStore.swift), [SessionArchive.swift](CampusVoteJurado/Core/Storage/SessionArchive.swift), [BrandArchive.swift](CampusVoteJurado/Core/Storage/BrandArchive.swift) (tokens y cache). |
| Diseño e idioma | [Colors.swift](CampusVoteJurado/Core/DesignSystem/Colors.swift), [Color+Hex.swift](CampusVoteJurado/Core/DesignSystem/Color+Hex.swift), [CoverImage.swift](CampusVoteJurado/Core/DesignSystem/CoverImage.swift), [ErrorBanner.swift](CampusVoteJurado/Core/DesignSystem/ErrorBanner.swift), [InstitutionBrandState.swift](CampusVoteJurado/Core/DesignSystem/InstitutionBrandState.swift), [OrganizationHeader.swift](CampusVoteJurado/Core/DesignSystem/OrganizationHeader.swift), [PremiumSurface.swift](CampusVoteJurado/Core/DesignSystem/PremiumSurface.swift), [TabBarItem.swift](CampusVoteJurado/Core/DesignSystem/TabBarItem.swift), [TabSegmentButton.swift](CampusVoteJurado/Core/DesignSystem/TabSegmentButton.swift) (componentes); [L10n.swift](CampusVoteJurado/Core/Localization/L10n.swift) (traducción). |

## 14. Verificación y escenarios pendientes

`python scripts/verify_project.py` terminó correctamente: **94 Swift** registrados exactamente una vez en grupo, referencia, build y Sources; IDs Xcode únicos; rutas existentes; máximo **245/250 líneas** por Swift; delimitadores balanceados; **339 traducciones ES/EN**; bundle, iOS 17 y permiso de cámara comprobados. Esta es una verificación estructural, no un compilador Swift. En este Windows no se dispone de `xcodebuild` ni de un simulador iOS.

Para cerrar la validación funcional en macOS/iPhone: compilar el `.xcodeproj`; recorrer login externo y OTP docente, rechazo por rol y falta de asignaciones; probar las cuatro fases de feria, cambio de alcance, QR de otra feria, red intermitente y refresh concurrente; guardar/editar reseña con emojis y límites; cambiar entre dos cuentas y verificar avatar, marca, onboarding y limpieza de datos; revisar español/inglés, VoiceOver, modo oscuro y texto grande. Priorizar la prueba A→B del avatar por H1.
