# CampusVote Jurado · base del proyecto iOS

Código base de la app del jurado en SwiftUI: capa de red, modelos, sesión y las 7
pantallas en una versión simple y funcional. Falta aplicarle el diseño (Stitch).

> Este código se escribió en Windows, sin Xcode, a partir de las respuestas reales
> del backend. Puede que Xcode pida algún ajuste menor la primera vez que compile.

## Requisitos

- Mac con **Xcode 15 o superior** (la app usa `@Observable`, que exige iOS 17).
- Internet: la app se conecta al backend en Render.
- Una cuenta demo: `jurado1@demo.campusvote.edu.pe` con la contraseña de `DEMO_PASSWORD`.

## Abrir el proyecto

1. Descomprime el paquete en la Mac.
2. Doble clic en **`CampusVoteJurado.xcodeproj`**: se abre en Xcode con todas las
   carpetas y archivos ya incluidos.
3. Arriba, elige un simulador de iPhone (por ejemplo, *iPhone 15*) y presiona **⌘R**.
4. Entra con `jurado1@demo.campusvote.edu.pe`.

Abrir solo la carpeta no sirve: Xcode necesita el `.xcodeproj` para compilar y ejecutar.
El proyecto usa Swift 5 e iOS 17 como mínimo. Para instalarlo en un iPhone físico,
elige tu Apple ID en **Signing & Capabilities → Team**.

## Plan B: crear el proyecto a mano

Solo si Xcode no abre el `.xcodeproj` (por ejemplo, con una versión muy antigua).
Xcode no genera las carpetas como Laravel: la plantilla solo trae el archivo de
arranque, una vista de ejemplo y los recursos. Las carpetas de este paquete se
copian encima.

1. Xcode → **File → New → Project… → iOS → App → Next**.
2. Completa así:
   - **Product Name:** `CampusVoteJurado`
   - **Team:** None (para el simulador no hace falta)
   - **Organization Identifier:** `pe.campusvote`
   - **Interface:** SwiftUI · **Language:** Swift · **Storage:** None
3. Guárdalo y marca **Create Git repository on my Mac**.
4. En el navegador de Xcode (panel izquierdo) borra `ContentView.swift` y
   `CampusVoteJuradoApp.swift` → **Move to Trash**. Los reemplazan los de este paquete.
5. En Finder, copia las carpetas `App`, `Models`, `Networking`, `Stores`, `Features`
   y `Components` dentro de la carpeta `CampusVoteJurado` del proyecto (la que tiene
   `Assets.xcassets`).
   - **Xcode 16 o superior:** aparecen solas en el navegador.
   - **Xcode 15:** arrástralas al navegador de Xcode y marca **Copy items if needed**,
     **Create groups** y el target `CampusVoteJurado`.
6. Clic en el proyecto → target **CampusVoteJurado → General → Minimum Deployments:
   iOS 17.0**.
7. Revisa la URL del backend en `Networking/APIConfig.swift`.
8. Elige un simulador de iPhone y presiona **⌘R**. Entra con `jurado1`.

## Si no compila

| Mensaje de Xcode | Qué hacer |
|---|---|
| `Invalid redeclaration of 'CampusVoteJuradoApp'` | Falta borrar el archivo de la plantilla (paso 4). |
| `Cannot find 'X' in scope` | Ese archivo no quedó en el target: selecciónalo → panel derecho → **Target Membership** → marca `CampusVoteJurado`. |
| Errores de concurrencia (`Sendable`, `actor-isolated`) | Build Settings → **Swift Language Version → Swift 5**. |
| La app no conecta | Abre la URL de `/health` en Safari: si Render está dormido, la primera respuesta tarda. |

## Estructura

```
CampusVoteJurado.xcodeproj   el proyecto de Xcode: se abre con doble clic
CampusVoteJurado/
  Assets.xcassets   color de acento (verde CampusVote) e ícono de la app
  App/          arranque, decisión login/app y rutas de navegación
  Models/       tipos Codable con la forma exacta de las respuestas
  Networking/   APIClient, rutas (Endpoint), errores, Llavero y fechas
  Stores/       estado compartido: sesión, ferias, proyectos, evaluación
  Features/     una carpeta por grupo de pantallas
  Components/   vistas reutilizables (portada, mensaje de error)
```

La regla que ordena todo: **una vista nunca llama a `APIClient`**; siempre pasa por
un store. Los stores son `@Observable` y `@MainActor`, y se comparten con
`.environment(...)` desde `CampusVoteJuradoApp`.

## Pantallas

| # | Pantalla | Archivo |
|---|---|---|
| 01 | Acceso (y código 2FA si la cuenta lo tiene) | `Features/Auth/LoginView.swift`, `TotpView.swift` |
| 02 | Mis ferias | `Features/Fairs/FairListView.swift` |
| 03 | Declaración de imparcialidad | `Features/Fairs/DeclarationView.swift` |
| 04 | Proyectos, búsqueda y filtros | `Features/Projects/ProjectListView.swift` |
| 05 | Detalle del proyecto | `Features/Projects/ProjectDetailView.swift` |
| 06 | Calificar con la rúbrica | `Features/Evaluation/EvaluateView.swift` |
| 07 | Mi avance | `Features/Evaluation/MyProgressView.swift` |

## Lo que queda para el equipo

- Aplicar el diseño de Stitch: colores de CampusVote en `Assets.xcassets` (verde
  #00695C y dorado #D4AF37), tipografía y tarjetas.
- Probar en un iPhone físico (requiere un Apple ID en **Team**).
- Ícono de la app y pantalla de arranque.
- Revisar cada pantalla con la lista «Cuándo una pantalla está lista» del plan.

Rutas, respuestas reales y reglas del backend: documento **Contrato API del Jurado**.
