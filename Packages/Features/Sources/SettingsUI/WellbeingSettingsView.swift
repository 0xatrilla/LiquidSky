import SwiftUI
import Models

struct WellbeingSettingsView: View {
  @State private var wellbeingService = DigitalWellbeingService.shared
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      Form {
        // Time Management
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Daily Time Limit")
              .font(.headline)
            
            HStack {
              Slider(
                value: $wellbeingService.dailyTimeLimit,
                in: 1800...28800, // 30 minutes to 8 hours
                step: 900 // 15 minute steps
              )
              
              Text(formatTime(wellbeingService.dailyTimeLimit))
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(minWidth: 60)
            }
            
            Text("Set a daily limit for app usage")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 4)
          
          Toggle("Break Reminders", isOn: $wellbeingService.breakRemindersEnabled)
          
          if wellbeingService.breakRemindersEnabled {
            VStack(alignment: .leading, spacing: 8) {
              Text("Reminder Interval")
                .font(.subheadline)
                .foregroundColor(.secondary)
              
              Picker("Interval", selection: $wellbeingService.breakReminderInterval) {
                Text("15 minutes").tag(900.0)
                Text("30 minutes").tag(1800.0)
                Text("45 minutes").tag(2700.0)
                Text("1 hour").tag(3600.0)
              }
              .pickerStyle(.segmented)
            }
            .padding(.leading, 16)
          }
        } header: {
          Text("Time Management")
        } footer: {
          Text("Help maintain a healthy balance with your social media usage")
        }
        
        // AI Features
        Section {
          Toggle("AI Insights", isOn: $wellbeingService.wellbeingInsightsEnabled)
          
          if wellbeingService.wellbeingInsightsEnabled {
            Toggle("Content Sentiment Analysis", isOn: $wellbeingService.contentSentimentAnalysisEnabled)
            Toggle("Usage Pattern Analysis", isOn: $wellbeingService.usagePatternAnalysisEnabled)
            Toggle("Wellbeing Suggestions", isOn: $wellbeingService.wellbeingSuggestionsEnabled)
          }
        } header: {
          Text("AI-Powered Features")
        } footer: {
          Text("Use Apple Intelligence to provide personalized wellbeing insights and recommendations")
        }
        
        // Notifications
        Section {
          Toggle("Wellbeing Notifications", isOn: $wellbeingService.wellbeingNotificationsEnabled)
          
          if wellbeingService.wellbeingNotificationsEnabled {
            Toggle("Daily Summary", isOn: $wellbeingService.dailySummaryEnabled)
            Toggle("Break Reminders", isOn: $wellbeingService.breakReminderNotificationsEnabled)
            Toggle("Goal Achievements", isOn: $wellbeingService.goalAchievementNotificationsEnabled)
          }
        } header: {
          Text("Notifications")
        } footer: {
          Text("Stay informed about your digital wellbeing progress")
        }
        
        // Data & Privacy
        Section {
          VStack(alignment: .leading, spacing: 8) {
            Text("Data Collection")
              .font(.subheadline)
              .fontWeight(.medium)
            
            Text("Wellbeing data is processed locally on your device using Apple Intelligence. No personal data is sent to external servers.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding(.vertical, 4)
          
          Button("Reset Wellbeing Data") {
            resetWellbeingData()
          }
          .foregroundColor(.red)
        } header: {
          Text("Data & Privacy")
        } footer: {
          Text("Your wellbeing data stays private and secure on your device")
        }
        
        // Goals
        Section {
          VStack(alignment: .leading, spacing: 12) {
            Text("Weekly Goals")
              .font(.headline)
            
            ForEach(wellbeingService.weeklyGoals.indices, id: \.self) { index in
              HStack {
                Text(wellbeingService.weeklyGoals[index].title)
                  .font(.subheadline)
                
                Spacer()
                
                Toggle("", isOn: Binding(
                  get: { wellbeingService.weeklyGoals[index].isEnabled },
                  set: { wellbeingService.weeklyGoals[index].isEnabled = $0 }
                ))
              }
            }
          }
          .padding(.vertical, 4)
        } header: {
          Text("Goals")
        } footer: {
          Text("Set weekly goals to improve your digital wellbeing habits")
        }
      }
      .navigationTitle("Wellbeing Settings")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            dismiss()
          }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Save") {
            saveSettings()
            dismiss()
          }
          .fontWeight(.semibold)
        }
      }
    }
  }
  
  // MARK: - Helper Methods
  
  private func formatTime(_ timeInterval: TimeInterval) -> String {
    let hours = Int(timeInterval) / 3600
    let minutes = Int(timeInterval) % 3600 / 60
    
    if hours > 0 {
      return "\(hours)h \(minutes)m"
    } else {
      return "\(minutes)m"
    }
  }
  
  private func saveSettings() {
    // Settings are automatically saved through @State bindings
    // Additional persistence logic can be added here if needed
  }
  
  private func resetWellbeingData() {
    wellbeingService.resetWellbeingData()
  }
}

#Preview {
  WellbeingSettingsView()
}
