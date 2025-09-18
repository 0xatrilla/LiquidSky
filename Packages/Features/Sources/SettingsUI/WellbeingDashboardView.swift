import SwiftUI
import Models

struct WellbeingDashboardView: View {
  @State private var wellbeingService = DigitalWellbeingService.shared
  @State private var insights: [WellbeingInsight] = []
  @State private var actions: [WellbeingAction] = []
  @State private var isLoading = false
  @State private var showingSettings = false
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          // Header
          headerView
          
          // Usage Overview
          usageOverviewCard
          
          // Insights
          if !insights.isEmpty {
            insightsCard
          }
          
          // Actions
          if !actions.isEmpty {
            actionsCard
          }
          
          // Settings
          settingsCard
        }
        .padding()
      }
      .navigationTitle("Digital Wellbeing")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Settings") {
            showingSettings = true
          }
        }
      }
      .sheet(isPresented: $showingSettings) {
        WellbeingSettingsView()
      }
      .task {
        await loadWellbeingData()
      }
      .refreshable {
        await loadWellbeingData()
      }
    }
  }
  
  // MARK: - Header View
  
  private var headerView: some View {
    VStack(spacing: 12) {
      Image(systemName: "heart.fill")
        .font(.system(size: 48))
        .foregroundColor(.pink)
      
      Text("Your Digital Wellbeing")
        .font(.title2)
        .fontWeight(.bold)
      
      Text("Stay mindful of your social media usage")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(16)
  }
  
  // MARK: - Usage Overview Card
  
  private var usageOverviewCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "clock")
          .foregroundColor(.blue)
        Text("Today's Usage")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        HStack {
          VStack(alignment: .leading) {
            Text("Screen Time")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text(formatTime(wellbeingService.dailyUsageTime))
              .font(.title2)
              .fontWeight(.bold)
              .foregroundColor(usageColor)
          }
          
          Spacer()
          
          VStack(alignment: .trailing) {
            Text("Sessions")
              .font(.subheadline)
              .foregroundColor(.secondary)
            Text("\(wellbeingService.sessionCount)")
              .font(.title2)
              .fontWeight(.bold)
          }
        }
        
        // Progress bar
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Daily Limit")
              .font(.caption)
              .foregroundColor(.secondary)
            Spacer()
            Text("\(Int(wellbeingService.dailyUsageTime / wellbeingService.dailyTimeLimit * 100))%")
              .font(.caption)
              .fontWeight(.medium)
          }
          
          ProgressView(value: wellbeingService.dailyUsageTime, total: wellbeingService.dailyTimeLimit)
            .progressViewStyle(LinearProgressViewStyle(tint: usageColor))
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Insights Card
  
  private var insightsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "lightbulb")
          .foregroundColor(.orange)
        Text("AI Insights")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        ForEach(insights.prefix(3)) { insight in
          WellbeingInsightRow(insight: insight)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Actions Card
  
  private var actionsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "hand.raised")
          .foregroundColor(.green)
        Text("Suggested Actions")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        ForEach(actions.prefix(3)) { action in
          WellbeingActionRow(action: action)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Settings Card
  
  private var settingsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "gearshape")
          .foregroundColor(.gray)
        Text("Wellbeing Settings")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        HStack {
          Text("Daily Time Limit")
            .font(.subheadline)
          Spacer()
          Text(formatTime(wellbeingService.dailyTimeLimit))
            .font(.subheadline)
            .fontWeight(.medium)
        }
        
        HStack {
          Text("Break Reminders")
            .font(.subheadline)
          Spacer()
          Toggle("", isOn: $wellbeingService.breakRemindersEnabled)
        }
        
        HStack {
          Text("AI Insights")
            .font(.subheadline)
          Spacer()
          Toggle("", isOn: $wellbeingService.wellbeingInsightsEnabled)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Helper Methods
  
  private func loadWellbeingData() async {
    isLoading = true
    defer { isLoading = false }
    
    insights = await wellbeingService.generateWellbeingInsights()
    actions = await wellbeingService.suggestWellbeingActions()
  }
  
  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
  
  private var usageColor: Color {
    let percentage = wellbeingService.dailyUsageTime / wellbeingService.dailyTimeLimit
    if percentage > 1.0 {
      return .red
    } else if percentage > 0.8 {
      return .orange
    } else {
      return .green
    }
  }
}

// MARK: - Supporting Views

struct WellbeingInsightRow: View {
  let insight: WellbeingInsight
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: insight.severity.icon)
        .foregroundColor(insight.severity.color)
        .font(.title3)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(insight.title)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(insight.message)
          .font(.caption)
          .foregroundColor(.secondary)
        
        if !insight.suggestion.isEmpty {
          Text(insight.suggestion)
            .font(.caption)
            .foregroundColor(.blue)
        }
      }
      
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

struct WellbeingActionRow: View {
  let action: WellbeingAction
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: action.actionType.icon)
        .foregroundColor(action.priority.color)
        .font(.title3)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(action.title)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(action.description)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      Spacer()
      
      Button("Do It") {
        // Handle action
      }
      .font(.caption)
      .buttonStyle(.bordered)
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Extensions

extension WellbeingInsight.Severity {
  var icon: String {
    switch self {
    case .info: return "info.circle"
    case .warning: return "exclamationmark.triangle"
    case .success: return "checkmark.circle"
    }
  }
  
  var color: Color {
    switch self {
    case .info: return .blue
    case .warning: return .orange
    case .success: return .green
    }
  }
}

extension WellbeingAction.ActionType {
  var icon: String {
    switch self {
    case .timer: return "timer"
    case .focusMode: return "moon"
    case .curateFeed: return "person.2"
    case .break: return "pause.circle"
    case .settings: return "gearshape"
    }
  }
}

extension WellbeingAction.Priority {
  var color: Color {
    switch self {
    case .low: return .gray
    case .medium: return .orange
    case .high: return .red
    }
  }
}

#Preview {
  WellbeingDashboardView()
}
