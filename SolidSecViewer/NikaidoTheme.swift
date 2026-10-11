import SwiftUI
import UIKit

/// Estilo visual compartido de Nikaido: colores, botones, tarjetas y estados vacíos.
enum NikaidoTheme {
    static let accent = Color(red: 0.38, green: 0.36, blue: 0.96)
    static let accentSoft = Color(red: 0.58, green: 0.40, blue: 0.98)

    static var gradient: LinearGradient {
        LinearGradient(
            colors: [accent, accentSoft],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func haptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
}

/// Botón redondo compacto para barras de herramientas.
struct NikaidoIconButtonStyle: ButtonStyle {
    var prominent = false

    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .semibold))
            .foregroundStyle(prominent ? Color.white : NikaidoTheme.accent)
            .frame(width: 34, height: 34)
            .background(
                Circle().fill(
                    prominent
                        ? AnyShapeStyle(NikaidoTheme.gradient)
                        : AnyShapeStyle(NikaidoTheme.accent.opacity(0.12))
                )
            )
            .scaleEffect(configuration.isPressed ? 0.92 : 1)
            .opacity(isEnabled ? 1 : 0.35)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Botón principal ancho con degradado.
struct NikaidoPrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(NikaidoTheme.gradient)
            )
            .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.4)
            .padding(.horizontal, 28)
    }
}

/// Cuadrito con ícono y color suave (carpetas, fotos, videos, etc.).
struct NikaidoIconBadge: View {
    let systemName: String
    let tint: Color
    var size: CGFloat = 42

    var body: some View {
        Image(systemName: systemName)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(
                RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                    .fill(tint.opacity(0.15))
            )
    }
}

/// Pantalla vacía amigable.
struct NikaidoEmptyState: View {
    let systemName: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(NikaidoTheme.accent.opacity(0.12))
                    .frame(width: 84, height: 84)

                Image(systemName: systemName)
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(NikaidoTheme.accent)
            }

            Text(title)
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

/// Campo de búsqueda en forma de cápsula.
struct NikaidoSearchField: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(placeholder, text: $text)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .submitLabel(.search)
                .onSubmit(onSubmit)

            if !text.isEmpty {
                Button {
                    text = ""
                    onSubmit()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .font(.subheadline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule().fill(Color(uiColor: .secondarySystemBackground))
        )
    }
}

extension View {
    /// Fondo redondeado para campos de texto.
    func nikaidoField() -> some View {
        self
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(uiColor: .secondarySystemBackground))
            )
    }
}

extension ExplorerFileItem {
    /// Color asociado al tipo de archivo.
    var nikaidoTint: Color {
        if isDirectory {
            return NikaidoTheme.accent
        }

        switch pathExtension {
        case "zip", "7z", "rar":
            return Color(red: 0.95, green: 0.62, blue: 0.15)
        case "jpg", "jpeg", "png", "gif", "webp", "heic", "heif":
            return Color(red: 0.93, green: 0.35, blue: 0.55)
        case "mp4", "mov", "m4v", "mkv", "avi", "webm", "3gp":
            return Color(red: 0.62, green: 0.35, blue: 0.92)
        case "mp3", "m4a", "aac", "wav", "flac", "ogg":
            return Color(red: 0.20, green: 0.70, blue: 0.45)
        case "pdf":
            return Color(red: 0.90, green: 0.27, blue: 0.27)
        case "txt", "md", "json", "xml", "log", "csv":
            return Color(red: 0.25, green: 0.55, blue: 0.95)
        default:
            return Color(red: 0.52, green: 0.55, blue: 0.62)
        }
    }
}
