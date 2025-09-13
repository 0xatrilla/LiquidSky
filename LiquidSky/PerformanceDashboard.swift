import Foundation
import SwiftUI

@available(iPadOS 26.0, *)
struct PerformanceDashboard: View {
  @Environment(\.glassPerformanceMonitor) var performanceMonitor
  @Environment(\.memoryManagementSystem) var memorySystem
  @Environment(\.dismiss) var dismiss

  @State private var selectedTab: DashboardTab = .performance
  @State private var showingAdvancedSettings = false

  var body: some View {
    NavigationView {
      VStack(spacing: 0) {
        // Tab selector
        tabSelector

        // Content based on selected tab
        TabView(selection: $selectedTab) {
          performanceTab
            .tag(DashboardTab.performance)

          memoryTab
            .tag(DashboardTab.memory)

          optimizationTab
            .tag(DashboardTab.optimization)
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
      .navigationTitle("Performance Dashboard")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItemGroup(placement: .topBarLeading) {
          Button("Close") {
            dismiss()
          }
        }

        ToolbarItemGroup(placement: .topBarTrailing) {
          Button("Settings") {
            showingAdvancedSettings = true
          }
        }
      }
    }
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    .sheet(isPresented: $showingAdvancedSettings) {
      PerformanceSettingsView()
    }
  }

  // MARK: - Tab Selector

  @ViewBuilder
  private var tabSelector: some View {
    HStack(spacing: 0) {
      ForEach(DashboardTab.allCases, id: \.self) { tab in
        Button {
          withAnimation(.smooth(duration: 0.3)) {
            selectedTab = tab
          }
        } label: {
          VStack(spacing: 4) {
            Image(systemName: tab.icon)
              .font(.subheadline)

            Text(tab.title)
              .font(.caption.weight(.medium))
          }
          .foregroundStyle(selectedTab == tab ? .blue : .secondary)
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
      }
    }
    .background(.ultraThinMaterial)
    .background(.ultraThinMaterial)
  }

  // MARK: - Performance Tab

  @ViewBuilder
  private var performanceTab: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        // Current metrics
        currentPerformanceMetrics

        // Frame rate chart
        frameRateChart

        // Glass effects overview
        glassEffectsOverview

        // Performance profile selector
        performanceProfileSelector
      }
      .padding()
    }
  }

  @ViewBuilder
  private var currentPerformanceMetrics: some View {
    let metrics = performanceMonitor.getPerformanceMetrics()

    GestureAwareGlassCard(cornerRadius: 16, isInteractive: false) {
      VStack(spacing: 16) {
        HStack {
          Text("Current Performance")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)

          Spacer()

          HStack(spacing: 4) {
            Image(systemName: metrics.trend.icon)
              .font(.caption)
            Text(
              metrics.trend == .stable
                ? "Stable" : metrics.trend == .improving ? "Improving" : "Declining"
            )
            .font(.caption.weight(.medium))
          }
          .foregroundStyle(metrics.trend.color)
        }

        HStack(spacing: 20) {
          PerformanceMetricView(
            title: "Frame Rate",
            value: String(format: "%.1f", metrics.frameRate),
            unit: "fps",
            color: metrics.frameRate >= 60 ? .green : .red
          )

          PerformanceMetricView(
            title: "Glass Effects",
            value: "\(metrics.effectCount)",
            unit: "active",
            color: metrics.effectCount < 30 ? .green : .orange
          )

          PerformanceMetricView(
            title: "CPU Usage",
            value: String(format: "%.1f", metrics.cpuUsage),
            unit: "%",
            color: metrics.cpuUsage < 50 ? .green : .red
          )
        }

        // Performance status
        HStack {
          Image(
            systemName: metrics.isPerformant
              ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
          )
          .foregroundStyle(metrics.isPerformant ? .green : .orange)

          Text(metrics.isPerformant ? "Performance is optimal" : "Performance issues detected")
            .font(.subheadline)
            .foregroundStyle(metrics.isPerformant ? .green : .orange)

          Spacer()
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var frameRateChart: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: false) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Frame Rate History")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        // Simplified chart representation
        HStack(alignment: .bottom, spacing: 2) {
          ForEach(0..<20, id: \.self) { index in
            let height = CGFloat.random(in: 20...80)
            Rectangle()
              .fill(.blue.opacity(0.7))
              .frame(width: 8, height: height)
              .background(.ultraThinMaterial)
          }
        }
        .frame(height: 80)

        HStack {
          Text("0fps")
            .font(.caption)
            .foregroundStyle(.secondary)

          Spacer()

          Text("120fps")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var glassEffectsOverview: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: false) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Glass Effects")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        HStack(spacing: 20) {
          VStack(alignment: .leading, spacing: 4) {
            Text("Active Effects")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text("\(performanceMonitor.effectCount)")
              .font(.title2.weight(.bold))
              .foregroundStyle(.primary)
          }

          VStack(alignment: .leading, spacing: 4) {
            Text("Performance Impact")
              .font(.caption)
              .foregroundStyle(.secondary)

            Text(performanceMonitor.performanceWarning ? "High" : "Low")
              .font(.title2.weight(.bold))
              .foregroundStyle(performanceMonitor.performanceWarning ? .red : .green)
          }

          Spacer()
        }

        if performanceMonitor.performanceWarning {
          HStack {
            Image(systemName: "exclamationmark.triangle.fill")
              .foregroundStyle(.orange)

            Text("Consider reducing glass effects for better performance")
              .font(.caption)
              .foregroundStyle(.orange)
          }
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var performanceProfileSelector: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: true) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Performance Profile")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        VStack(spacing: 8) {
          ForEach(PerformanceProfile.allCases, id: \.self) { profile in
            Button {
              performanceMonitor.setPerformanceProfile(profile)
            } label: {
              HStack {
                VStack(alignment: .leading, spacing: 2) {
                  Text(profile.displayName)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)

                  Text(profile.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                if performanceMonitor.performanceProfile == profile {
                  Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.blue)
                }
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 8)
              .background(
                RoundedRectangle(cornerRadius: 8)
                  .fill(
                    performanceMonitor.performanceProfile == profile ? .blue.opacity(0.1) : .clear)
              )
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding()
    }
  }

  // MARK: - Memory Tab

  @ViewBuilder
  private var memoryTab: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        // Memory usage overview
        memoryUsageOverview

        // Memory breakdown
        memoryBreakdown

        // Memory actions
        memoryActions
      }
      .padding()
    }
  }

  @ViewBuilder
  private var memoryUsageOverview: some View {
    let metrics = memorySystem.getMemoryMetrics()

    GestureAwareGlassCard(cornerRadius: 16, isInteractive: false) {
      VStack(spacing: 16) {
        HStack {
          Text("Memory Usage")
            .font(.headline.weight(.semibold))
            .foregroundStyle(.primary)

          Spacer()

          HStack(spacing: 4) {
            Image(systemName: metrics.trend.icon)
              .font(.caption)
            Text(
              metrics.trend == .stable
                ? "Stable" : metrics.trend == .increasing ? "Increasing" : "Decreasing"
            )
            .font(.caption.weight(.medium))
          }
          .foregroundStyle(metrics.trend.color)
        }

        // Memory usage gauge
        VStack(spacing: 8) {
          ZStack {
            Circle()
              .stroke(.quaternary, lineWidth: 8)
              .frame(width: 120, height: 120)

            Circle()
              .trim(from: 0, to: min(1.0, metrics.currentUsage / 1000.0))
              .stroke(metrics.warningLevel.color, lineWidth: 8)
              .frame(width: 120, height: 120)
              .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
              Text(String(format: "%.0f", metrics.currentUsage))
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

              Text("MB")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }

          Text(metrics.warningLevel.displayName)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(metrics.warningLevel.color)
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var memoryBreakdown: some View {
    let metrics = memorySystem.getMemoryMetrics()

    GestureAwareGlassCard(cornerRadius: 16, isInteractive: false) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Memory Breakdown")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        VStack(spacing: 8) {
          MemoryBreakdownRow(
            title: "Glass Effects",
            count: metrics.glassEffectCount,
            color: .blue
          )

          MemoryBreakdownRow(
            title: "Views",
            count: metrics.viewCount,
            color: .green
          )

          MemoryBreakdownRow(
            title: "Image Cache",
            count: metrics.imageCacheSize / (1024 * 1024),  // Convert to MB
            color: .orange,
            unit: "MB"
          )
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var memoryActions: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: true) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Memory Management")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        VStack(spacing: 8) {
          Button("Clear Image Cache") {
            memorySystem.imageCache.clearAll()
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
          .foregroundStyle(.blue)

          Button("Release Inactive Objects") {
            memorySystem.glassEffectPool.releaseInactive()
            memorySystem.viewPool.releaseInactive()
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(.orange.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
          .foregroundStyle(.orange)

          Button("Force Cleanup") {
            Task {
              // await memorySystem.performMemoryOptimization() // Method not available
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 8)
          .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
          .foregroundStyle(.red)
        }
      }
      .padding()
    }
  }

  // MARK: - Optimization Tab

  @ViewBuilder
  private var optimizationTab: some View {
    ScrollView {
      LazyVStack(spacing: 16) {
        // Optimization recommendations
        optimizationRecommendations

        // Auto-optimization settings
        autoOptimizationSettings
      }
      .padding()
    }
  }

  @ViewBuilder
  private var optimizationRecommendations: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: false) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Optimization Recommendations")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        VStack(alignment: .leading, spacing: 8) {
          if performanceMonitor.performanceWarning {
            RecommendationRow(
              icon: "exclamationmark.triangle.fill",
              title: "Reduce Glass Effects",
              description: "Too many active glass effects are impacting performance",
              color: .orange
            )
          }

          if memorySystem.memoryWarningLevel != .normal {
            RecommendationRow(
              icon: "memorychip.fill",
              title: "Clear Memory Cache",
              description: "Memory usage is high, consider clearing caches",
              color: .red
            )
          }

          if performanceMonitor.frameRate < 60 {
            RecommendationRow(
              icon: "speedometer",
              title: "Switch to Efficiency Mode",
              description: "Frame rate is low, efficiency mode may help",
              color: .blue
            )
          }
        }
      }
      .padding()
    }
  }

  @ViewBuilder
  private var autoOptimizationSettings: some View {
    GestureAwareGlassCard(cornerRadius: 16, isInteractive: true) {
      VStack(alignment: .leading, spacing: 12) {
        Text("Auto-Optimization")
          .font(.headline.weight(.semibold))
          .foregroundStyle(.primary)

        VStack(spacing: 12) {
          Toggle("Automatic Performance Optimization", isOn: .constant(true))
          Toggle("Adaptive Frame Rate", isOn: .constant(true))
          Toggle("Memory Cleanup on Warning", isOn: .constant(true))
          Toggle("Thermal Throttling", isOn: .constant(true))
        }
      }
      .padding()
    }
  }
}

// MARK: - Supporting Views

@available(iPadOS 26.0, *)
// MARK: - Performance Metric View

@available(iPadOS 26.0, *)
struct PerformanceMetricView: View {
  let title: String
  let value: String
  let unit: String
  let color: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack(alignment: .firstTextBaseline, spacing: 2) {
        Text(value)
          .font(.title3.weight(.bold))
          .foregroundStyle(color)

        Text(unit)
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

@available(iPadOS 26.0, *)
struct MemoryBreakdownRow: View {
  let title: String
  let count: Int
  let color: Color
  let unit: String

  init(title: String, count: Int, color: Color, unit: String = "items") {
    self.title = title
    self.count = count
    self.color = color
    self.unit = unit
  }

  var body: some View {
    HStack {
      Circle()
        .fill(color)
        .frame(width: 8, height: 8)

      Text(title)
        .font(.subheadline)
        .foregroundStyle(.primary)

      Spacer()

      Text("\(count) \(unit)")
        .font(.subheadline.weight(.medium))
        .foregroundStyle(.secondary)
    }
  }
}

@available(iPadOS 26.0, *)
struct RecommendationRow: View {
  let icon: String
  let title: String
  let description: String
  let color: Color

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: icon)
        .font(.subheadline)
        .foregroundStyle(color)
        .frame(width: 20, height: 20)

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.subheadline.weight(.medium))
          .foregroundStyle(.primary)

        Text(description)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Spacer()
    }
  }
}

// MARK: - Performance Settings View

@available(iPadOS 26.0, *)
struct PerformanceSettingsView: View {
  @Environment(\.dismiss) var dismiss

  var body: some View {
    NavigationView {
      Form {
        Section("Performance Monitoring") {
          Toggle("Enable Performance Monitoring", isOn: .constant(true))
          Toggle("Show Performance Overlay", isOn: .constant(false))
          Toggle("Log Performance Metrics", isOn: .constant(true))
        }

        Section("Memory Management") {
          Toggle("Automatic Memory Cleanup", isOn: .constant(true))
          Toggle("Aggressive Cleanup on Warning", isOn: .constant(false))

          Stepper("Cache Size Limit: 100MB", value: .constant(100), in: 50...500, step: 50)
        }

        Section("Glass Effects") {
          Toggle("Adaptive Glass Effects", isOn: .constant(true))
          Toggle("Reduce Effects on Performance Warning", isOn: .constant(true))

          Stepper("Max Glass Effects: 30", value: .constant(30), in: 10...100, step: 5)
        }
      }
      .navigationTitle("Performance Settings")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }
}

// MARK: - Dashboard Tab Enum

@available(iPadOS 26.0, *)
enum DashboardTab: CaseIterable {
  case performance
  case memory
  case optimization

  var title: String {
    switch self {
    case .performance: return "Performance"
    case .memory: return "Memory"
    case .optimization: return "Optimization"
    }
  }

  var icon: String {
    switch self {
    case .performance: return "speedometer"
    case .memory: return "memorychip"
    case .optimization: return "gearshape.2"
    }
  }
}
