import Foundation
import StoreKit

@Observable
final class InAppPurchaseService {
  nonisolated static let shared = InAppPurchaseService()

  // Product identifiers for different tip amounts
  enum TipAmount: String, CaseIterable {
    case small = "com.acxtrilla.horizon.tip.small"
    case medium = "com.acxtrilla.horizon.tip.medium"
    case large = "com.acxtrilla.horizon.tip.large"
    case custom = "com.acxtrilla.horizon.tip.custom"

    var displayName: String {
      switch self {
      case .small: return "Small Tip"
      case .medium: return "Medium Tip"
      case .large: return "Large Tip"
      case .custom: return "Custom Amount"
      }
    }

    var description: String {
      switch self {
      case .small: return "Show your appreciation with a small tip"
      case .medium: return "A generous tip to support development"
      case .large: return "A substantial tip - thank you!"
      case .custom: return "Choose your own amount"
      }
    }

    var emoji: String {
      switch self {
      case .small: return "☕️"
      case .medium: return "🍕"
      case .large: return "🎉"
      case .custom: return "💝"
      }
    }
  }

  var products: [Product] = []
  var isLoading = false
  var errorMessage: String?
  var purchaseInProgress = false
  var lastPurchaseDate: Date?

  private var updateListenerTask: Task<Void, Error>?

  private init() {
    // Start the transaction listener
    startTransactionListener()

    // Load products
    Task {
      await loadProducts()
    }
  }

  // Note: Task.detached will handle its own lifecycle
  // No need for explicit cancellation in deinit

  private func startTransactionListener() {
    updateListenerTask = Task.detached { [weak self] in
      for await result in Transaction.updates {
        await self?.handleTransactionUpdate(result)
      }
    }
  }

  // MARK: - Product Loading

  @MainActor
  func loadProducts() async {
    isLoading = true
    errorMessage = nil

    do {
      let productIdentifiers = Set(TipAmount.allCases.map { $0.rawValue })
      let storeProducts = try await Product.products(for: productIdentifiers)

      // Sort products by price
      self.products = storeProducts.sorted { $0.price < $1.price }
      print("InAppPurchaseService: Loaded \(products.count) products")
    } catch {
      errorMessage = "Failed to load products: \(error.localizedDescription)"
      print("InAppPurchaseService: Failed to load products: \(error)")
    }

    isLoading = false
  }

  // MARK: - Purchase Handling

  @MainActor
  func purchase(_ product: Product) async -> Bool {
    purchaseInProgress = true
    errorMessage = nil

    do {
      let result = try await product.purchase()

      switch result {
      case .success(let verification):
        // Handle successful purchase
        await handleSuccessfulPurchase(product: product, verification: verification)
        purchaseInProgress = false
        return true

      case .userCancelled:
        print("InAppPurchaseService: Purchase cancelled by user")
        purchaseInProgress = false
        return false

      case .pending:
        print("InAppPurchaseService: Purchase pending")
        errorMessage = "Purchase is pending approval"
        purchaseInProgress = false
        return false

      @unknown default:
        print("InAppPurchaseService: Unknown purchase result")
        errorMessage = "Unknown purchase result"
        purchaseInProgress = false
        return false
      }
    } catch {
      errorMessage = "Purchase failed: \(error.localizedDescription)"
      print("InAppPurchaseService: Purchase failed: \(error)")
      purchaseInProgress = false
      return false
    }
  }

  private func handleSuccessfulPurchase(
    product: Product, verification: VerificationResult<Transaction>
  ) async {
    do {
      let transaction = try checkVerified(verification)

      // Update UI
      lastPurchaseDate = Date()

      // Store purchase record locally
      await storePurchaseRecord(product: product, transaction: transaction)

      // Finish the transaction
      await transaction.finish()

      print("InAppPurchaseService: Purchase completed successfully: \(product.id)")

    } catch {
      errorMessage = "Failed to verify purchase: \(error.localizedDescription)"
      print("InAppPurchaseService: Purchase verification failed: \(error)")
    }
  }

  private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
    switch result {
    case .unverified:
      throw InAppPurchaseError.verificationFailed
    case .verified(let safe):
      return safe
    }
  }

  private func storePurchaseRecord(product: Product, transaction: Transaction) async {
    let defaults = UserDefaults.standard

    // Store purchase history
    var purchaseHistory = defaults.array(forKey: "tip.purchase.history") as? [[String: Any]] ?? []

    let purchaseRecord: [String: Any] = [
      "productId": product.id,
      "productName": product.displayName,
      "price": product.price,
      "currency": product.priceFormatStyle.currencyCode,
      "purchaseDate": transaction.purchaseDate,
      "transactionId": transaction.id,
    ]

    purchaseHistory.append(purchaseRecord)
    defaults.set(purchaseHistory, forKey: "tip.purchase.history")

    // Store total tips given
    let totalTips = defaults.double(forKey: "tip.total.amount")
    let newTotal = totalTips + Double(truncating: product.price as NSDecimalNumber)
    defaults.set(newTotal, forKey: "tip.total.amount")

    // Store last tip amount
    defaults.set(Double(truncating: product.price as NSDecimalNumber), forKey: "tip.last.amount")
    defaults.set(Date(), forKey: "tip.last.date")
  }

  // MARK: - Transaction Listener

  @MainActor
  private func handleTransactionUpdate(_ result: VerificationResult<Transaction>) async {
    do {
      let transaction = try checkVerified(result)

      // Handle the transaction based on its state
      switch transaction.revocationDate {
      case .none:
        // Transaction is still valid
        if transaction.isUpgraded {
          // Handle upgrade
          print("InAppPurchaseService: Transaction upgraded: \(transaction.id)")
        } else {
          // Handle new purchase - we need to find the actual product
          if let product = products.first(where: { $0.id == transaction.productID }) {
            await handleSuccessfulPurchase(product: product, verification: result)
          } else {
            // If product not found in current list, just finish the transaction
            await transaction.finish()
          }
        }
      default:
        // Transaction was revoked
        print("InAppPurchaseService: Transaction revoked: \(transaction.id)")
      }

      // Finish the transaction
      await transaction.finish()

    } catch {
      print("InAppPurchaseService: Transaction verification failed: \(error)")
    }
  }

  // MARK: - Purchase History

  func getPurchaseHistory() -> [[String: Any]] {
    let defaults = UserDefaults.standard
    return defaults.array(forKey: "tip.purchase.history") as? [[String: Any]] ?? []
  }

  func getTotalTipsAmount() -> Double {
    let defaults = UserDefaults.standard
    return defaults.double(forKey: "tip.total.amount")
  }

  func getLastTipAmount() -> Double {
    let defaults = UserDefaults.standard
    return defaults.double(forKey: "tip.last.amount")
  }

  func getLastTipDate() -> Date? {
    let defaults = UserDefaults.standard
    return defaults.object(forKey: "tip.last.date") as? Date
  }

  // MARK: - Restore Purchases

  @MainActor
  func restorePurchases() async -> Bool {
    isLoading = true
    errorMessage = nil

    do {
      try await AppStore.sync()
      print("InAppPurchaseService: Purchases restored successfully")
      isLoading = false
      return true
    } catch {
      errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
      print("InAppPurchaseService: Failed to restore purchases: \(error)")
      isLoading = false
      return false
    }
  }
}

// MARK: - Errors

enum InAppPurchaseError: LocalizedError {
  case verificationFailed
  case productNotFound
  case purchaseFailed

  var errorDescription: String? {
    switch self {
    case .verificationFailed:
      return "Purchase verification failed"
    case .productNotFound:
      return "Product not found"
    case .purchaseFailed:
      return "Purchase failed"
    }
  }
}
