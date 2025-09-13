import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct GlassEffectContainer<Content: View>: View {
  let content: Content
  let spacing: CGFloat
  let morphingEnabled: Bool

  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var containerID = UUID().uuidString

  init(
    spacing: CGFloat = 16.0,
    morphingEnabled: Bool = true,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.spacing = spacing
    self.morphingEnabled = morphingEnabled
  }

  var body: some View {
    content
      .onAppear {
        glassEffectManager.registerEffect(id: containerID, interactive: morphingEnabled)
      }
      .onDisappear {
        glassEffectManager.unregisterEffect(id: containerID)
      }
  }
}

// MARK: - Glass Effect Transition Coordinator

@available(iPadOS 26.0, *)
struct GlassTransitionCoordinator: View {
  let sourceID: String
  let destinationID: String
  let transition: GlassEffectTransition
  let isActive: Bool

  @Environment(\.glassEffectManager) var glassEffectManager
  @Namespace private var transitionNamespace

  var body: some View {
    EmptyView()
      .onAppear {
        if isActive {
          glassEffectManager.setTransition(transition, for: sourceID)
        }
      }
  }
}

// MARK: - Morphing Glass Container

@available(iPadOS 26.0, *)
struct MorphingGlassContainer<Content: View>: View {
  let content: Content
  let spacing: CGFloat
  let morphThreshold: CGFloat

  @State private var activeEffects: Set<String> = []
  @Namespace private var morphingNamespace

  init(
    spacing: CGFloat = 20.0,
    morphThreshold: CGFloat = 40.0,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.spacing = spacing
    self.morphThreshold = morphThreshold
  }

  var body: some View {
    GlassEffectContainer(spacing: spacing) {
      content
        .environment(\.glassEffectNamespace, morphingNamespace)
        .environment(\.glassEffectSpacing, spacing)
    }
  }
}

// MARK: - Glass Effect Modifiers

@available(iPadOS 26.0, *)
extension View {
  func glassEffectID(_ id: String, in namespace: Namespace.ID) -> some View {
    self.modifier(GlassEffectIDModifier(id: id, namespace: namespace))
  }

  func glassEffectTransition(_ transition: GlassEffectTransition) -> some View {
    self.modifier(GlassEffectTransitionModifier(transition: transition))
  }

  func glassEffectUnion(id: String, namespace: Namespace.ID) -> some View {
    self.modifier(GlassEffectUnionModifier(id: id, namespace: namespace))
  }
}

@available(iPadOS 26.0, *)
struct GlassEffectIDModifier: ViewModifier {
  let id: String
  let namespace: Namespace.ID

  func body(content: Content) -> some View {
    content
      .matchedGeometryEffect(id: id, in: namespace)
  }
}

@available(iPadOS 26.0, *)
struct GlassEffectTransitionModifier: ViewModifier {
  let transition: GlassEffectTransition

  func body(content: Content) -> some View {
    content
      .transition(swiftUITransition)
  }

  private var swiftUITransition: AnyTransition {
    switch transition {
    case .matchedGeometry:
      return .asymmetric(
        insertion: .scale.combined(with: .opacity),
        removal: .scale.combined(with: .opacity)
      )
    case .materialize:
      return .asymmetric(
        insertion: .scale(scale: 0.8).combined(with: .opacity),
        removal: .scale(scale: 1.2).combined(with: .opacity)
      )
    }
  }
}

@available(iPadOS 26.0, *)
struct GlassEffectUnionModifier: ViewModifier {
  let id: String
  let namespace: Namespace.ID

  func body(content: Content) -> some View {
    content
      .matchedGeometryEffect(id: id, in: namespace, properties: .frame)
  }
}

// MARK: - Glass Effect Transition Types

@available(iPadOS 26.0, *)
enum GlassEffectTransition {
  case matchedGeometry
  case materialize
}

// MARK: - Environment Keys

@available(iPadOS 26.0, *)
struct GlassEffectNamespaceKey: EnvironmentKey {
  static let defaultValue: Namespace.ID? = nil
}

@available(iPadOS 26.0, *)
struct GlassEffectSpacingKey: EnvironmentKey {
  static let defaultValue: CGFloat = 16.0
}

@available(iPadOS 26.0, *)
extension EnvironmentValues {
  var glassEffectNamespace: Namespace.ID? {
    get { self[GlassEffectNamespaceKey.self] }
    set { self[GlassEffectNamespaceKey.self] = newValue }
  }

  var glassEffectSpacing: CGFloat {
    get { self[GlassEffectSpacingKey.self] }
    set { self[GlassEffectSpacingKey.self] = newValue }
  }
}

// MARK: - Performance Optimized Glass Container

@available(iPadOS 26.0, *)
struct OptimizedGlassContainer<Content: View>: View {
  let content: Content
  let spacing: CGFloat

  @Environment(\.glassEffectManager) var glassEffectManager
  @State private var useSimplifiedEffects = false

  init(
    spacing: CGFloat = 16.0,
    @ViewBuilder content: () -> Content
  ) {
    self.content = content()
    self.spacing = spacing
  }

  var body: some View {
    Group {
      if useSimplifiedEffects {
        // Fallback to simpler effects when performance is poor
        content
          .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
      } else {
        GlassEffectContainer(spacing: spacing) {
          content
        }
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: .optimizeGlassEffects)) { _ in
      withAnimation(.smooth(duration: 0.3)) {
        useSimplifiedEffects = true
      }

      // Reset after performance improves
      DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
        withAnimation(.smooth(duration: 0.3)) {
          useSimplifiedEffects = false
        }
      }
    }
    .onAppear {
      useSimplifiedEffects = glassEffectManager.shouldUseSimplifiedEffects()
    }
  }
}

// MARK: - Glass Effect Preview Helpers

@available(iPadOS 26.0, *)
struct GlassEffectPreview: View {
  @State private var showSecondElement = false
  @Namespace private var glassNamespace

  var body: some View {
    VStack(spacing: 20) {
      GlassEffectContainer(spacing: 30.0) {
        HStack(spacing: 30.0) {
          Rectangle()
            .fill(.blue)
            .frame(width: 100, height: 100)
            .background {
              if #available(iOS 26.0, *) {
                Rectangle()
                  .glassEffect(.regular.interactive())
              }
            }
            .glassEffectID("first", in: glassNamespace)

          if showSecondElement {
            Rectangle()
              .fill(.green)
              .frame(width: 100, height: 100)
              .background {
                if #available(iOS 26.0, *) {
                  Rectangle()
                    .glassEffect(.regular.interactive())
                }
              }
              .glassEffectID("second", in: glassNamespace)
              .glassEffectTransition(.matchedGeometry)
          }
        }
      }

      Button("Toggle Second Element") {
        withAnimation(.smooth(duration: 0.5)) {
          showSecondElement.toggle()
        }
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
  }
}

#Preview {
  if #available(iPadOS 26.0, *) {
    GlassEffectPreview()
      .environment(LiquidGlassEffectManager())
  } else {
    Text("iPadOS 26.0 required")
  }
}
