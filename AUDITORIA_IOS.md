# Auditoría de CampusVote Jurado

Revisión del código local de `C:\campusvote` y de la app. El backend se actualizó
en paralelo durante la tarea y se releyeron los archivos de reseñas al terminar.
No se modificó el backend. No se compiló Swift, no se hicieron commit ni push.

## Hallazgos y arreglos

Las rutas de esta tabla son relativas a `/api`. Los números indican la ubicación
del arreglo en la versión entregada.

| Archivo:línea | Hallazgo → arreglo |
|---|---|
| `Core/Networking/Endpoint.swift:110`, `APIClient+Assignments.swift:4`, `Stores/FairsStore.swift:49` | `/fairs/my-assignments` usa `meta.pagination`; antes se perdían las páginas posteriores a la primera. Ahora recorre las páginas con límite 100 y elimina duplicados. La validación de acceso solo necesita comprobar la primera página. |
| `Core/Networking/APIClient+Errors.swift:4`, `APIError.swift:18` | Se conservan código y mensaje tanto en `{success:false,message,code}` como en `{success:false,error:{code,message}}`. Hay mensajes de respaldo en español para 401/403/404/409/429. `REVIEW_NOT_OPEN_YET` muestra «Podrás calificar cuando empiece la feria». |
| `Core/Networking/APIClient.swift:128`, `RefreshCoordinator.swift:8` | El 401 intenta renovar una vez; reutiliza un token que otra petición ya renovó. La renovación concurrente se agrupa por refresh token y una respuesta de una sesión anterior no debe invalidar la nueva. Un 403 de contenido no cierra la sesión. Fallos de red/429/5xx conservan los tokens. |
| `Core/Networking/Endpoint.swift:127`, `Features/Projects/List/ProjectListView.swift:49` | La exploración usa `review-projects` con alcance de categorías por defecto y `scope=all` en LIVE. Se retiraron el catálogo genérico y las fichas públicas de la app. El alcance efectivo `mine/all` devuelto por el servidor se respeta. |
| `Models/Fair.swift:11`, `Models/ReviewAccess.swift:16`, `Models/ReviewProject.swift:4` | Se leen fase, fecha de apertura y permiso, tanto en la feria asignada como en la lista y sus proyectos. Si faltan, OPEN equivale a LIVE; CLOSED equivale a ENDED. Una fase desconocida mantiene lectura restringida. |
| `Features/Projects/Detail/ProjectDetailView+Loading.swift:42` | Antes solo se bloqueaba al guardar si la feria estaba cerrada. Ahora se consulta la asignación, se muestra el aviso de fase y se omite el formulario fuera de LIVE. Un fallo al leer la reseña existente deja el guardado deshabilitado y ofrece reintento. |
| `Stores/ProjectsStore+Reviews.swift:4`, `Features/Projects/Detail/ProjectReviewCard.swift:177` | El comentario mantiene el rango 10–1000 en unidades UTF-16, igual que `.length`/Zod en JavaScript, incluso con emojis. Se bloquea la edición durante el envío y se reacciona a `REVIEW_NOT_OPEN_YET`/`REVIEW_CLOSED`. |
| `Stores/ProjectsStore.swift:127`, `Stores/ProjectsStore+Reviews.swift:21`, `Stores/Session/SessionStore.swift:186` | Se invalida el estado pendiente al salir y se descartan respuestas tardías de proyectos. El cierre local de sesión y la vuelta a CampusVote son inmediatos; la revocación HTTP se intenta con los tokens capturados. |
| `Stores/Session/SessionStore+Auth.swift:59`, `Core/Storage/BrandArchive.swift:3` | La marca se guarda por usuario y organización. Restauración inmediata desde caché y actualización silenciosa. Sin organización o ante fallo de marca se usa CampusVote. La ausencia de organización ya no produce un error local de decodificación al iniciar sesión. |
| `Core/DesignSystem/Colors.swift:31`, `OrganizationHeader.swift:3` | Se reutiliza `apply(_:)`: acentos claros oscurecidos, adaptación para modo oscuro, texto sobre marca elegido por contraste y logo remoto con respaldo `logo_campusvote`. El nombre y logo aparecen en Ferias, Avance, Asignados, Perfil y onboarding. |
| `Features/Auth/Onboarding/JuryOnboardingView.swift:3`, `App/RootView.swift:32` | Onboarding de tres páginas, persistido por ID real de usuario. Saltar y Empezar marcan la introducción como vista; el cambio obligatorio de contraseña ocurre antes. Español e inglés mediante L10n y el catálogo existente. |
| `Features/Projects/Catalog/QRCodePayload.swift:8` | Se extrae el ID de `project`/`projectId`, del último segmento numérico/UUID o de texto/JSON. Un QR de otra feria se rechaza. El ID se envía al detalle protegido, sin abrir la URL del QR. |
| `Features/Projects/Detail/ProjectMembersCard.swift:3` | Los integrantes, ya incluidos por el detalle protegido, se muestran junto a la descripción. Se añadieron avisos de fase, superficies comunes, etiquetas VoiceOver, botones de al menos 44 pt y ajuste del flujo de chips a Dynamic Type. |

## Contrato verificado

| Método y ruta | Cuerpo / respuesta `data` |
|---|---|
| `POST auth/login` | `{email,password}` → AuthResult; puede requerir OTP de correo. |
| `POST auth/email/request` | `{email}` → `requiresEmailOtp`, `tempToken`, `email`. |
| `POST auth/email/login-verify` | `{code}`, Bearer temporal → tokens y usuario. |
| `POST auth/email/resend` | Bearer temporal, sin cuerpo → confirmación. |
| `POST auth/refresh` | `{refreshToken}` → `token`, `refreshToken` nuevos. El camelCase de este cuerpo es el contrato real. |
| `GET auth/me` | Usuario en camelCase; el modelo también acepta snake_case del login. El ID es obligatorio para mantener caché y onboarding estables. |
| `POST auth/logout` | `{refreshToken}`, Bearer de la sesión que se cierra → `{loggedOut:true}`. |
| `POST users/me/password` | `{current_password,new_password}` → confirmación. |
| `GET organizations/:id` | Miembros de la organización pueden consultar su marca. Se aceptan colores camelCase o snake_case, y `logo` o `logo_url`. |
| `GET fairs/my-assignments?page=N&limit=100` | Arreglo de `{fair,...}`, paginación en `meta.pagination`. La ruta local es `/fairs/my-assignments`, no `/jury/my-assignments`. |
| `GET fairs/my-assignments/:fairId` | Una asignación propia con su feria y campos de fase. |
| `GET fairs/my-projects` | `{summary,projects}` sin paginación; proyectos de categorías propias, con `my_rating`/`my_comment`. |
| `GET fairs/:fairId/review-projects[?scope=all]` | `{fair_id,fair_name,scope,phase,review_opens_at,can_review,summary,projects}` sin paginación. `mine` es el alcance por defecto; `all` solo surte efecto en LIVE. |
| `GET fairs/:fairId/projects/:projectId` | Ficha protegida, miembros con `first_name`/`last_name`, imágenes, categoría y stand. Se ignora la rúbrica que pueda incluir el servidor. Ver dependencias pendientes. |
| `GET fairs/:fairId/projects/:projectId/rating` | `{rating,comment,...}` de la persona autenticada; ambos pueden ser null. |
| `PUT fairs/:fairId/projects/:projectId/rating` | `{rating:1...5,comment}` → reseña guardada. No se envían likes, votos ni rúbricas. |

También se revisaron las llamadas de perfil: `GET/PUT users/me`, con nombres
`first_name` y `last_name`, y el POST de contraseña de la hoja de seguridad.
No fue necesario cambiar su contrato.

## Privacidad confirmada en el código del backend

`fairEngagement.reviewList.service.js` y el repositorio filtran por categorías
asignadas en PREVIEW y ENDED, y por defecto durante LIVE. El alcance `all` permite
explorar toda la feria durante LIVE. La consulta de ratings usa el ID del jurado
actual. La app no consulta listados de jurados ni reseñas de otros autores.

`fairEngagement.ratings.service.js` entrega al equipo estrellas, comentario y
`created_at`, sin el nombre del autor. Para otros jurados, las reseñas pueden
estar disponibles sin autor cuando se publican resultados y dentro de la ventana
de siete días tras el cierre. Los administradores de la organización sí reciben
nombre y apellido. El tercer paso del onboarding refleja estas diferencias.

## Marca y primer uso

- Splash y login conservan el asset y colores de CampusVote, incluso si existe marca guardada.
- Dentro de la sesión se usa la organización del usuario. La caché está separada por usuario/organización; se revalida silenciosamente al restaurar.
- `AsyncImage` muestra el logo CampusVote si falta el institucional, está cargando o falla. Un color inválido vuelve al acento por defecto.
- Los acentos se ajustan para contraste sobre superficies claras y oscuras; el texto del encabezado y botones se elige para el fondo efectivo.
- Onboarding: «Tu panel de jurado», «Reseñas que ayudan» y «Quién ve tu comentario», con TabView de páginas, desplazamiento vertical para texto grande, foco VoiceOver, Saltar y Siguiente/Empezar.
- La clave es `campusvote.onboarding.v1.<userId>` y se escribe al saltar o terminar. Salir y volver a entrar no repite la introducción; otra cuenta conserva su propio estado.

## Prueba paso a paso en Xcode/iPhone

1. Ejecutar `python scripts/verify_project.py` y `git diff --check`. Abrir el `.xcodeproj` en Xcode, configurar Team y compilar para iOS 17. Confirmar bundle `pe.campusvote.CampusVoteJurado` y ausencia de archivos rojos o duplicados en Sources.
2. En una instalación limpia, comprobar splash y login CampusVote. Entrar como externo con contraseña y como docente con OTP; probar código inválido, reenvío y cambio obligatorio de contraseña cuando corresponda.
3. Con una cuenta nueva, recorrer las tres páginas con swipe y botones; comprobar Saltar y Empezar. Reingresar con esa cuenta y otra para verificar persistencia independiente. Cambiar idioma a inglés y revisar los textos.
4. Verificar nombre/logo/acento institucional en las cuatro pestañas. Probar logo inexistente, colores casi blancos e inválidos, modo claro/oscuro, organización ausente y fallo de su GET. Cerrar y abrir la app para comprobar caché; salir para comprobar vuelta inmediata a CampusVote.
5. Con más de 100 asignaciones de prueba, comprobar las páginas posteriores a la primera. Con dos jurados de categorías distintas, comprobar que cada uno recibe sus proyectos y sus propias reseñas.
6. En BEFORE_PREVIEW, comprobar que no se puede explorar la feria. En PREVIEW, abrirla desde Programadas: comprobar categoría asignada, descripción, integrantes y fecha local; no debe haber estrellas ni editor. Probar fechas ISO con y sin milisegundos y zona horaria distinta.
7. En LIVE, alternar «Mis categorías / Toda la feria». Probar búsqueda, categoría, pendientes y reseñados. Abrir un proyecto aprobado de otra categoría y guardar una reseña. Este último paso depende del ajuste de detalle indicado abajo.
8. En iPhone físico, permitir y denegar cámara. Escanear UUID, texto con ID numérico, URL con último ID, `?project=...` y `?projectId=...`. Probar QR de otra feria, ID inexistente y texto inválido. El detalle debe resolver permisos sin abrir la URL del QR. El backend actual valida UUID: un ID numérico se extrae, pero puede ser rechazado por la API.
9. Guardar, editar y reabrir una reseña de 1 y 5 estrellas. Probar comentarios de 9/10/1000/1001 unidades UTF-16, espacios y emojis. Si falla la lectura de la reseña actual, comprobar que no se puede sobrescribirla. Si falla el envío, comprobar mensaje y reintento.
10. Cambiar la feria a ENDED y actualizar: comprobar aviso «La feria terminó», lista en lectura y ausencia del formulario. Forzar 403 `REVIEW_NOT_OPEN_YET` y 409 `REVIEW_CLOSED` durante un envío para comprobar que el formulario desaparece.
11. Forzar token vencido con refresh válido: el GET/PUT debe completarse tras una renovación. Probar varias peticiones simultáneas, refresh rechazado, red caída durante refresh, 403 de contenido, 404, 409 y 429. Solo los rechazos de sesión deben expulsar; los mensajes deben conservar el texto del backend.
12. Cerrar sesión mientras hay una carga o guardado pendiente y entrar con otra cuenta: no deben reaparecer proyectos, reseñas ni marca de la cuenta anterior. Revisar también navegación de vuelta, estados vacíos y botones de reintento en Ferias, Avance, Proyectos y Detalle.
13. Activar VoiceOver, tamaños de accesibilidad de texto y Reducir movimiento. Recorrer onboarding, filtros, estrellas, editor, volver y pestañas en un iPhone pequeño; comprobar foco, lectura completa, contraste y áreas táctiles.

La cámara ya tenía `NSCameraUsageDescription` en español, generada en el
Info.plist mediante las configuraciones Debug y Release del pbxproj; se conservó.

## Dependencias y límites de verificación

- En la última lectura, `fairEvaluation.exposition.service.js:158` permite PREVIEW en el detalle, pero su llamada a `assertJuryCanOperateOnProject` sigue exigiendo categoría y rechaza CLOSED. Por ello aún no pude confirmar el detalle de otra categoría durante LIVE ni el detalle de una feria CLOSED. La app mantiene la ruta protegida y muestra el error/reintento; el backend debe ampliar la lectura o proporcionar una ficha específica de reseñas para completar esos recorridos.
- `listJuryReviewAssignments` aún filtra por la organización del actor. Un externo asignado a una feria de otra organización podría no aparecer en el resumen `/fairs/my-projects`, aunque figure en `/fairs/my-assignments` y pueda entrar por «Explorar feria». Falta confirmar si ese caso se usa en producción.
- Los campos nuevos y `scope=all` se confirmaron en el código local actualizado, no contra el servidor desplegado. Si faltan campos, la app mantiene la compatibilidad con OPEN como LIVE.
- Sin Xcode ni Swift instalado no se verificó compilación, comportamiento en dispositivo ni respuestas HTTP reales. La revisión estática incluyó tipos/modelos, imports, APIs de iOS 17, delimitadores e integridad del proyecto. Las pruebas anteriores deben ejecutarse en una Mac/iPhone.

## Archivos nuevos

- `Core/DesignSystem/Color+Hex.swift`, `InstitutionBrandState.swift`, `OrganizationHeader.swift`.
- `Core/Networking/APIClient+Assignments.swift`, `APIClient+Errors.swift`.
- `Core/Storage/BrandArchive.swift`.
- `Features/Auth/Onboarding/JuryOnboardingView.swift`.
- `Features/Fairs/FairReviewNotice.swift`.
- `Features/Projects/Detail/ProjectDetailView+Loading.swift`, `ProjectMembersCard.swift`.
- `Models/ReviewAccess.swift`, `ReviewProject.swift`.
- `Stores/ProjectsStore+Reviews.swift`.
- `scripts/verify_project.py`, este informe; README actualizado.

## Archivos modificados y retirados

- Proyecto: `CampusVoteJurado.xcodeproj/project.pbxproj`; App: `CampusVoteJuradoApp.swift`, `MainTabView.swift`, `RootView.swift`.
- Core: `DesignSystem/Colors.swift`; `Networking/APIClient.swift`, `APIError.swift`, `Endpoint.swift`, `RefreshCoordinator.swift`.
- Auth: `Login/LoginView.swift`, `LoginFieldRow.swift`, `LoginAccessTypeSelector.swift`; `Profile/ProfileView.swift`.
- Ferias: `FairListHeaderView.swift`, `FairListView.swift`, `FairRowView.swift`; Avance: `MyProgressView.swift`.
- Proyectos: `Assigned/MyProjectsView.swift`; `Catalog/QRCodePayload.swift`, `QRScannerView.swift`; `Detail/ChipFlow.swift`, `ProjectDetailHeader.swift`, `ProjectDetailView.swift`, `ProjectReviewCard.swift`; `List/ProjectCoverCard.swift`, `ProjectListView.swift`.
- Modelos: `Fair.swift`, `Review.swift`, `User.swift`; Stores: `FairsStore.swift`, `ProjectsStore.swift`, `Session/SessionStore.swift`, `SessionStore+Auth.swift`; `Localizable.xcstrings`.
- Retirados: `Stores/ProjectsCatalogStore.swift`, `Models/Project/PublicProject.swift`, `Features/Projects/Catalog/AllProjectsView.swift`, `PublicProjectView.swift`. Sus referencias también se retiraron del pbxproj.

Resultado de la validación: 94 Swift registrados exactamente una vez, IDs únicos
de 24 hexadecimales, ninguna referencia Swift inexistente, máximo 245 líneas por
Swift y 339 traducciones completas ES/EN. `git diff --check` sin errores.
