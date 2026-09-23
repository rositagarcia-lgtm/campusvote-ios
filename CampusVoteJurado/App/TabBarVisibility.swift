import Foundation
import Observation

/// Permite que una pantalla concreta esconda la barra inferior.
///
/// La barra vive en MainTabView, fuera de la navegación, así que no puede
/// enterarse sola de dónde está el jurado. Las pantallas que deben verse sin
/// distracciones —la declaración de conflicto de interés, por ejemplo— la
/// esconden al aparecer y la devuelven al salir.
@Observable
@MainActor
final class TabBarVisibility {
    var isHidden = false
}
