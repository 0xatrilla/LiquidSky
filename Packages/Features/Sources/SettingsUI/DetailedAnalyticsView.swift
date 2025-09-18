import SwiftUI
import Models

struct DetailedAnalyticsView: View {
  let timeframe: TimeFrame
  @State private var analyticsService = PersonalAnalyticsService.shared
  @State private var detailedData: DetailedAnalyticsData?
  @State private var isLoading = false
  @Environment(\.dismiss) private var dismiss
  
  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 20) {
          if isLoading {
            ProgressView("Loading detailed analytics...")
              .frame(maxWidth: .infinity, maxHeight: .infinity)
          } else if let data = detailedData {
            // Engagement Chart
            engagementChart(data: data)
            
            // Content Performance
            contentPerformanceSection(data: data)
            
            // Audience Insights
            audienceInsightsSection(data: data)
            
            // Time Analysis
            timeAnalysisSection(data: data)
            
            // Top Performing Posts
            topPostsSection(data: data)
          }
        }
        .padding()
      }
      .navigationTitle("Detailed Analytics")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Done") {
            dismiss()
          }
        }
      }
      .task {
        await loadDetailedData()
      }
    }
  }
  
  // MARK: - Engagement Chart
  
  private func engagementChart(data: DetailedAnalyticsData) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "chart.line.uptrend.xyaxis")
          .foregroundColor(.blue)
        Text("Engagement Over Time")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      // Placeholder for chart - in a real app, you'd use a charting library
      VStack {
        Text("📈 Chart Visualization")
          .font(.title2)
          .foregroundColor(.secondary)
        
        Text("Engagement trends for \(timeframe.rawValue)")
          .font(.caption)
          .foregroundColor(.secondary)
      }
      .frame(height: 200)
      .frame(maxWidth: .infinity)
      .background(Color(.systemGray6))
      .cornerRadius(12)
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Content Performance Section
  
  private func contentPerformanceSection(data: DetailedAnalyticsData) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "doc.text")
          .foregroundColor(.purple)
        Text("Content Performance")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        PerformanceMetricRow(
          title: "Average Likes per Post",
          value: String(format: "%.1f", data.averageLikesPerPost),
          trend: data.likesTrend
        )
        
        PerformanceMetricRow(
          title: "Average Reposts per Post",
          value: String(format: "%.1f", data.averageRepostsPerPost),
          trend: data.repostsTrend
        )
        
        PerformanceMetricRow(
          title: "Average Replies per Post",
          value: String(format: "%.1f", data.averageRepliesPerPost),
          trend: data.repliesTrend
        )
        
        PerformanceMetricRow(
          title: "Engagement Rate",
          value: String(format: "%.2f%%", data.engagementRate),
          trend: data.engagementTrend
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Audience Insights Section
  
  private func audienceInsightsSection(data: DetailedAnalyticsData) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "person.2")
          .foregroundColor(.green)
        Text("Audience Insights")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        AudienceInsightRow(
          title: "Follower Growth",
          value: "+\(data.followerGrowth)",
          description: "New followers this \(timeframe.rawValue)"
        )
        
        AudienceInsightRow(
          title: "Most Active Time",
          value: data.mostActiveTime,
          description: "Peak engagement hours"
        )
        
        AudienceInsightRow(
          title: "Top Interests",
          value: data.topInterests.joined(separator: ", "),
          description: "Based on your content"
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Time Analysis Section
  
  private func timeAnalysisSection(data: DetailedAnalyticsData) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "clock")
          .foregroundColor(.orange)
        Text("Time Analysis")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 12) {
        TimeAnalysisRow(
          title: "Most Active Day",
          value: data.mostActiveDay,
          icon: "calendar"
        )
        
        TimeAnalysisRow(
          title: "Average Post Time",
          value: data.averagePostTime,
          icon: "clock"
        )
        
        TimeAnalysisRow(
          title: "Posting Frequency",
          value: data.postingFrequency,
          icon: "repeat"
        )
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Top Posts Section
  
  private func topPostsSection(data: DetailedAnalyticsData) -> some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Image(systemName: "star.fill")
          .foregroundColor(.yellow)
        Text("Top Performing Posts")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      
      VStack(spacing: 8) {
        ForEach(data.topPosts.prefix(5)) { post in
          TopPostRow(post: post)
        }
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .cornerRadius(12)
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }
  
  // MARK: - Helper Methods
  
  private func loadDetailedData() async {
    isLoading = true
    defer { isLoading = false }
    
    detailedData = await analyticsService.getDetailedAnalytics(timeframe: timeframe)
  }
}

// MARK: - Supporting Views

struct PerformanceMetricRow: View {
  let title: String
  let value: String
  let trend: Double
  
  var body: some View {
    HStack {
      Text(title)
        .font(.subheadline)
      
      Spacer()
      
      HStack(spacing: 8) {
        Text(value)
          .font(.subheadline)
          .fontWeight(.medium)
        
        if trend != 0 {
          HStack(spacing: 2) {
            Image(systemName: trend > 0 ? "arrow.up" : "arrow.down")
              .font(.caption)
            Text(String(format: "%.1f%%", abs(trend)))
              .font(.caption)
              .fontWeight(.medium)
          }
          .foregroundColor(trend > 0 ? .green : .red)
        }
      }
    }
  }
}

struct AudienceInsightRow: View {
  let title: String
  let value: String
  let description: String
  
  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        Text(title)
          .font(.subheadline)
          .fontWeight(.medium)
        
        Spacer()
        
        Text(value)
          .font(.subheadline)
          .foregroundColor(.blue)
      }
      
      Text(description)
        .font(.caption)
        .foregroundColor(.secondary)
    }
  }
}

struct TimeAnalysisRow: View {
  let title: String
  let value: String
  let icon: String
  
  var body: some View {
    HStack {
      Image(systemName: icon)
        .foregroundColor(.orange)
        .font(.title3)
        .frame(width: 24)
      
      Text(title)
        .font(.subheadline)
      
      Spacer()
      
      Text(value)
        .font(.subheadline)
        .fontWeight(.medium)
    }
  }
}

struct TopPostRow: View {
  let post: TopPost
  
  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      // Post content preview
      VStack(alignment: .leading, spacing: 4) {
        Text(post.content)
          .font(.subheadline)
          .lineLimit(2)
        
        Text(post.date, style: .relative)
          .font(.caption)
          .foregroundColor(.secondary)
      }
      
      Spacer()
      
      // Engagement metrics
      VStack(alignment: .trailing, spacing: 2) {
        HStack(spacing: 4) {
          Image(systemName: "heart.fill")
            .font(.caption)
            .foregroundColor(.pink)
          Text("\(post.likes)")
            .font(.caption)
            .fontWeight(.medium)
        }
        
        HStack(spacing: 4) {
          Image(systemName: "repeat")
            .font(.caption)
            .foregroundColor(.blue)
          Text("\(post.reposts)")
            .font(.caption)
            .fontWeight(.medium)
        }
        
        HStack(spacing: 4) {
          Image(systemName: "bubble.left")
            .font(.caption)
            .foregroundColor(.green)
          Text("\(post.replies)")
            .font(.caption)
            .fontWeight(.medium)
        }
      }
    }
    .padding(.vertical, 4)
  }
}

#Preview {
  DetailedAnalyticsView(timeframe: .week)
}
