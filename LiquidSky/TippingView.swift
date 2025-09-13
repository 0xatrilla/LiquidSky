import StoreKit
import SwiftUI

struct TippingView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment private var purchaseService: InAppPurchaseService

  @State private var showThankYou = false
  @State private var selectedProduct: Product?
  @State private var showPurchaseHistory = false

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          headerView
          tipOptionsView
          purchaseButtonView
        }
      }
      .navigationTitle("Support Horizon")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
    .sheet(isPresented: $showThankYou) {
      thankYouView
    }
    // .sheet(isPresented: $showPurchaseHistory) {
    //   PurchaseHistoryView()
    //     .environment(purchaseService)
    // }
  }

  private var headerView: some View {
    VStack(spacing: 16) {
      Image(systemName: "heart.fill")
        .font(.system(size: 60))
        .foregroundColor(.red)

      Text("Support Horizon")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text(
        "If you enjoy using Horizon, consider sending a tip to support continued development and improvements."
      )
      .font(.body)
      .foregroundColor(.secondary)
      .multilineTextAlignment(.center)
      .padding(.horizontal)
    }
    .padding(.top)
  }

  private var tipOptionsView: some View {
    Group {
      if purchaseService.isLoading {
        VStack(spacing: 16) {
          ProgressView()
            .scaleEffect(1.2)
          Text("Loading tip options...")
            .foregroundColor(.secondary)
        }
        .frame(height: 200)
      } else if purchaseService.products.isEmpty {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.triangle")
            .font(.system(size: 40))
            .foregroundColor(.orange)
          Text("Tip options not available")
            .font(.headline)
          Text("Please check your internet connection and try again.")
            .font(.caption)
            .foregroundColor(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(height: 200)
      } else {
        LazyVGrid(
          columns: [
            GridItem(.flexible()),
            GridItem(.flexible()),
          ], spacing: 16
        ) {
          ForEach(purchaseService.products, id: \.id) { product in
            TipOptionCard(
              product: product,
              isSelected: selectedProduct?.id == product.id,
              onTap: {
                selectedProduct = product
              }
            )
          }
        }
        .padding(.horizontal)
      }
    }
  }

  private var purchaseButtonView: some View {
    Group {
      if let selectedProduct = selectedProduct {
        VStack(spacing: 16) {
          Button(action: {
            Task {
              await purchaseTip(selectedProduct)
            }
          }) {
            HStack {
              if purchaseService.purchaseInProgress {
                ProgressView()
                  .scaleEffect(0.8)
                  .tint(.white)
              } else {
                Image(systemName: "heart.fill")
                  .font(.headline)
              }

              Text("Send \(selectedProduct.displayName)")
                .font(.headline)
                .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
              LinearGradient(
                colors: [.red, .pink],
                startPoint: .leading,
                endPoint: .trailing
              )
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
          }
          .disabled(purchaseService.purchaseInProgress)

          Text("You'll be charged \(selectedProduct.displayPrice)")
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.horizontal)
      }
    }
  }

  private var thankYouView: some View {
    VStack(spacing: 24) {
      Image(systemName: "heart.fill")
        .font(.system(size: 80))
        .foregroundColor(.red)

      Text("Thank You! 💙")
        .font(.largeTitle)
        .fontWeight(.bold)

      Text("Your tip has been received and will help support continued development of Horizon.")
        .font(.body)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)

      Button("You're Welcome!") {
        dismiss()
      }
      .buttonStyle(.borderedProminent)
      .tint(.red)
    }
    .padding()
  }

  private func purchaseTip(_ product: Product) async {
    let success = await purchaseService.purchase(product)
    if success {
      showThankYou = true
    }
  }

  private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
  }
}

// MARK: - Tip Option Card

struct TipOptionCard: View {
  let product: Product
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      VStack(spacing: 12) {
        Text(getEmoji(for: product.id))
          .font(.system(size: 32))

        Text(product.displayName)
          .font(.headline)
          .fontWeight(.semibold)

        Text(product.displayPrice)
          .font(.title3)
          .fontWeight(.bold)
          .foregroundColor(.blue)

        Text(getDescription(for: product.id))
          .font(.caption)
          .foregroundColor(.secondary)
          .multilineTextAlignment(.center)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 16)
          .fill(isSelected ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
          .overlay(
            RoundedRectangle(cornerRadius: 16)
              .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
          )
      )
    }
    .buttonStyle(PlainButtonStyle())
  }

  private func getEmoji(for productId: String) -> String {
    if productId.contains("small") { return "☕️" }
    if productId.contains("medium") { return "🍕" }
    if productId.contains("large") { return "🎉" }
    if productId.contains("custom") { return "💝" }
    return "💙"
  }

  private func getDescription(for productId: String) -> String {
    if productId.contains("small") { return "Show your appreciation" }
    if productId.contains("medium") { return "A generous tip" }
    if productId.contains("large") { return "A substantial tip" }
    if productId.contains("custom") { return "Choose your own amount" }
    return "Support development"
  }
}

// MARK: - Purchase History View

struct PurchaseHistoryView: View {
  @Environment(\.dismiss) private var dismiss
  @Environment private var purchaseService: InAppPurchaseService

  var body: some View {
    NavigationView {
      List {
        Section("Tip History") {
          let history = purchaseService.getPurchaseHistory()
          if history.isEmpty {
            Text("No tips sent yet")
              .foregroundColor(.secondary)
              .italic()
          } else {
            ForEach(Array(history.enumerated()), id: \.offset) { index, record in
              VStack(alignment: .leading, spacing: 4) {
                HStack {
                  Text(record["productName"] as? String ?? "Unknown")
                    .font(.headline)
                  Spacer()
                  if let price = record["price"] as? Double {
                    Text(formatCurrency(price))
                      .font(.headline)
                      .foregroundColor(.blue)
                  }
                }

                if let date = record["purchaseDate"] as? Date {
                  Text(date, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                if let transactionId = record["transactionId"] as? String {
                  Text("ID: \(transactionId)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                }
              }
              .padding(.vertical, 4)
            }
          }
        }

        Section("Summary") {
          HStack {
            Text("Total Tips Sent")
            Spacer()
            Text("\(purchaseService.getPurchaseHistory().count)")
              .fontWeight(.semibold)
          }

          HStack {
            Text("Total Amount")
            Spacer()
            Text(formatCurrency(purchaseService.getTotalTipsAmount()))
              .fontWeight(.semibold)
              .foregroundColor(.blue)
          }

          if let lastDate = purchaseService.getLastTipDate() {
            HStack {
              Text("Last Tip")
              Spacer()
              Text(lastDate, style: .date)
                .fontWeight(.semibold)
            }
          }
        }
      }
      .navigationTitle("Tip History")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
        }
      }
    }
  }

  private func formatCurrency(_ amount: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.locale = Locale.current
    return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
  }
}

// #Preview {
//   TippingView()
//     .environment(InAppPurchaseService.shared)
// }
