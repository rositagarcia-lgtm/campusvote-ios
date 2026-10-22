# CampusVote Jurado · iOS 17

App nativa SwiftUI para jurados externos (`JURY`) y docentes asignados (`TEACHER`).
Permite consultar proyectos y guardar reseñas de 1 a 5 estrellas con un comentario.

Abre `CampusVoteJurado.xcodeproj` en una Mac con Xcode 15 o posterior. Selecciona el
target CampusVoteJurado, un dispositivo con iOS 17 o posterior y tu Team de firma.
El bundle es `pe.campusvote.CampusVoteJurado`. La URL de la API está en
`CampusVoteJurado/Core/Networking/APIConfig.swift`.

El acceso externo usa contraseña y, si corresponde, código por correo. El acceso
interno usa código por correo. Splash y login conservan CampusVote; tras entrar
se carga y guarda la marca de la organización del usuario. El onboarding se
muestra una vez por usuario.

Las ferias distinguen BEFORE_PREVIEW, PREVIEW, LIVE y ENDED. Durante PREVIEW se
consulta la categoría asignada. Durante LIVE existe el filtro «Mis categorías /
Toda la feria» y el escáner QR. Durante ENDED se consulta en lectura. Las rutas
protegidas del backend siempre deciden los permisos efectivos.

El [informe de auditoría](AUDITORIA_IOS.md) contiene el contrato revisado, los
cambios, las dependencias pendientes del backend y la prueba paso a paso en iPhone.

La validación disponible en Windows es:

```powershell
python scripts/verify_project.py
git diff --check
```

El script valida las referencias y Sources del pbxproj, los IDs, las rutas, el
máximo de 250 líneas por Swift, delimitadores, traducciones y configuración.
No compila Swift ni reemplaza las pruebas en Xcode.

Las carpetas de este proyecto no se sincronizan: cada Swift nuevo debe añadirse
en PBXFileReference, PBXBuildFile, el PBXGroup de su carpeta y PBXSourcesBuildPhase.
Conserva `objectVersion = 56` y usa identificadores únicos de 24 hexadecimales.
