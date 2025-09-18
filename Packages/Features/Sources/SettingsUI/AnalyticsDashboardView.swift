import SwiftUI
import Models

struct AnalyticsDashboardView: View {
  @State private var analyticsService = PersonalAnalyticsService.shared
  @State private var insights: [AnalyticsInsight] = []
  @State private var trends: [AnalyticsTrend] = []
  @State private var isLoading = false
  @State private var selectedTimeframe: TimeFrame = .week
  @State private var showingDetailedView = false
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          // Header
          headerView
          
          // Timeframe Selector
          timeframeSelector
          
          // Key Metrics
          keyMetricsCard
          
          // Content Analysis
          contentAnalysisCard
          
          // Engagement Trends
          engagementTrendsCard
          
          // AI Insights
          if !insights.isEmpty {
            aiInsightsCard
          }
          
          // Detailed Analytics Button
          detailedAnalyticsButton
        }
        .padding()
      }
      .navigationTitle("Personal Analytics")
      .navigationBarTitleDisplayMode(.large)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Export") {
            exportAnalytics()
          }
        }
      }
      .task {
        await loadAnalyticsData()
      }
      .refreshable {
        await loadAnalyticsData()
      }
      .sheet(isPresented: $showingDetailedView) {
        DetailedAnalyticsView(timeframe: selectedTimeframe)
      }
    }
  }
  
  // MARK: - Header View
  
  private var headerView: some View {
    VStack(spacing: 12) {
      Image(systemName: "chart.bar.fill")
        .font(.system(size: 48))
        .foregroundColor(.blue)
      
      Text("Your Analytics")
        .font(.title2)
        .fontWeight(.bold)
      
      Text("Understand your social media patterns")
        .font(.subheadline)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(16)
  }
  
  // MARK: - Timeframe Selector
  
  private var timeframeSelector: some View {
    Picker("Timeframe", selection: $selectedTimeframe) {
      Text("Week").tag(TimeFrame.week)
      Text("Month").tag(TimeFrame.month)
      Text("Year").tag(TimeFrame.year)
    }
    .pickerStyle(.segmented)
    .onChange(of: selectedTimeframe) { _, _ in
      Task {
        await loadAnalyticsData()
      }
    }
  }
  
  // MARK: - Key Metrics Card
  
  private var keyMetricsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "chart.line.uptrend.xyaxis")
          .foregroundColor(.green)
        Text("Key Metrics")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      LazyVGrid(columns: [
        GridItem(.flexible()),
        GridItem(.flexible())
      ], spacing: 16) {
        MetricCard(
          title: "Posts Created",
          value: "\(analyticsService.totalPosts)",
          change: analyticsService.postsChange,
          icon: "square.and.pencil"
        )
        
        MetricCard(
          title: "Likes Received",
          value: "\(analyticsService.totalLikes)",
          change: analyticsService.likesChange,
          icon: "heart.fill"
        )
        
        MetricCard(
          title: "Followers",
          value: "\(analyticsService.followerCount)",
          change: analyticsService.followersChange,
          icon: "person.2.fill"
        )
        
        MetricCard(
          title: "Engagement Rate",
          value: String(format: "%.1f%%", analyticsService.engagementRate),
          change: analyticsService.engagementChange,
          icon: "chart.bar.fill"
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Content Analysis Card
  
  private var contentAnalysisCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "doc.text")
          .foregroundColor(.purple)
        Text("Content Analysis")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        ContentTypeRow(
          title: "Text Posts",
          percentage: analyticsService.textPostPercentage,
          count: analyticsService.textPostCount
        )
        
        ContentTypeRow(
          title: "Media Posts",
          percentage: analyticsService.mediaPostPercentage,
          count: analyticsService.mediaPostCount
        )
        
        ContentTypeRow(
          title: "Reposts",
          percentage: analyticsService.repostPercentage,
          count: analyticsService.repostCount
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Engagement Trends Card
  
  private var engagementTrendsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "chart.xyaxis.line")
          .foregroundColor(.orange)
        Text("Engagement Trends")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        ForEach(trends.prefix(3)) { trend in
          TrendRow(trend: trend)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - AI Insights Card
  
  private var aiInsightsCard: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "brain.head.profile")
          .foregroundColor(.pink)
        Text("AI Insights")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        ForEach(insights.prefix(3)) { insight in
          AnalyticsInsightRow(insight: insight)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Detailed Analytics Button
  
  private var detailedAnalyticsButton: some View {
    Button(action: {
      showingDetailedView = true
    }) {
      HStack {
        Image(systemName: "chart.bar.doc.horizontal")
        Text("View Detailed Analytics")
          .fontWeight(.medium)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(Color.blue)
      .foregroundColor(.white)
      .cornerRadius(12)
    }
  }
  
  // MARK: - Helper Methods
  
  private func loadAnalyticsData() async {
    isLoading = true
    defer { isLoading = false }
    
    insights = await analyticsService.generatePersonalInsights(timeframe: selectedTimeframe)
    trends = await analyticsService.analyzeEngagementTrends(timeframe: selectedTimeframe)
  }
  
  private func exportAnalytics() {
    // Implement analytics export functionality
  }
}

// MARK: - Supporting Views

struct MetricCard: View {
  let title: String
  let value: String
  let change: Double
  let icon: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Image(systemName: icon)
          .foregroundColor(.blue)
          .font(.title3)
        Spacer()
        
        if change != 0 {
          HStack(spacing: 2) {
            Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
              .font(.caption)
            Text(String(format: "%.1f%%", abs(change)))
              .font(.caption)
              .fontWeight(.medium)
          }
          .foregroundColor(change > 0 ? .green : .red)
        }
      }
      
      Text(value)
        .font(.title2)
        .fontWeight(.bold)
      
      Text(title)
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .padding()
    .background(Color(.systemGray6))
    .cornerRadius(8)
  }
}

struct ContentTypeRow: View {
  let title: String
  let percentage: Double
  let count: Int
  
  var body: some View {
    HStack {
      Text(title)
        .font(.subheadline)
      
      Spacer()
      
      VStack(alignment: .trailing, spacing: 2) {
        Text("\(count)")
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(String(format: "%.1f%%", percentage))
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      // Progress bar
      GeometryReader { geometry in
        ZStack(alignment: .leading) {
          Rectangle()
            .fill(Color(.systemGray5))
            .frame(height: 4)
            .cornerRadius(2)
          
          Rectangle()
            .fill(Color.blue)
            .frame(width: geometry.size.width * (percentage / 100), height: 4)
            .cornerRadius(2)
        }
      }
      .frame(width: 60, height: 4)
    }
  }
}

struct TrendRow: View {
  let trend: AnalyticsTrend
  
  var body: some View {
    HStack {
      Image(systemName: trend.direction.icon)
        .foregroundColor(trend.direction.color)
        .font(.title3)
      
      VStack(alignment: .leading, spacing: 2) {
        Text(trend.title)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(trend.description)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      Spacer()
      
      Text(trend.changeText)
        .font(.caption)
        .fontWeight(.medium)
        .foregroundColor(trend.direction.color)
    }
    .padding(.vertical, 4)
  }
}

struct AnalyticsInsightRow: View {
  let insight: AnalyticsInsight
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: insight.category.icon)
        .foregroundColor(insight.category.color)
        .font(.title3)
      
      VStack(alignment: .leading, spacing: 4) {
        Text(insight.title)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Text(insight.description)
          .font(.caption)
          .foregroundColor(.secondary)
        
        if let recommendation = insight.recommendation {
          Text(recommendation)
            .font(.caption)
            .foregroundColor(.blue)
        }
      }
      
      Spacer()
    }
    .padding(.vertical, 4)
  }
}

// MARK: - Extensions

extension AnalyticsTrend.Direction {
  var icon: String {
    switch self {
    case .up: return "arrow.up"
    case .down: return "arrow.down"
    case .stable: return "minus"
    }
  }
  
  var color: Color {
    switch self {
    case .up: return .green
    case .down: return .red
    case .stable: return .gray
    }
  }
}

extension AnalyticsInsight.Category {
  var icon: String {
    switch self {
    case .engagement: return "heart.fill"
    case .content: return "doc.text"
    case .timing: return "clock"
    case .audience: return "person.2"
    case .growth: return "chart.line.uptrend.xyaxis"
    }
  }
  
  var color: Color {
    switch self {
    case .engagement: return .pink
    case .content: return .purple
    case .timing: return .orange
    case .audience: return .blue
    case .growth: return .green
    }
  }
}

#Preview {
  AnalyticsDashboardView()
}
