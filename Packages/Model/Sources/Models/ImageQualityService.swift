import Foundation
import Nuke
import NukeUI

// MARK: - Image Quality Service
@MainActor
@Observable
public final class ImageQualityService {
  public static let shared = ImageQualityService()

  private let settingsService = SettingsService.shared

  private init() {}

  // MARK: - Image Pipeline Configuration
  public func configureImagePipeline() {
    var configuration = ImagePipeline.Configuration()

    switch settingsService.imageQuality {
    case .low:
      configuration.dataCache = nil  // No caching for low quality
      configuration.imageCache = nil
      configuration.isProgressiveDecodingEnabled = false

    case .medium:
      // Use default caches but enable progressive decoding
      configuration.isProgressiveDecodingEnabled = true

    case .high:
      // Use default caches and enable progressive decoding
      configuration.isProgressiveDecodingEnabled = true
    }

    ImagePipeline.shared = ImagePipeline(configuration: configuration)
  }

  // MARK: - Image Loading Options
  public func getImageLoadingOptions() -> ImageRequest.Options {
    let options = ImageRequest.Options()

    // In Nuke 12.x, processors and priority are set differently
    // We'll return the base options and let the caller configure them as needed
    return options
  }

  // MARK: - Image Request Configuration
  public func configureImageRequest(_ request: inout ImageRequest, for quality: ImageQuality) {
    switch quality {
    case .low:
      // For low quality, we'll just set priority
      request.priority = .low

    case .medium:
      // For medium quality, use normal priority
      request.priority = .normal

    case .high:
      // For high quality, use high priority
      request.priority = .high
    }
  }

  // MARK: - Preload Configuration
  public func shouldPreloadImages() -> Bool {
    return settingsService.preloadImages
  }

  public func getPreloadDistance() -> Int {
    // Return how many items ahead to preload based on quality
    switch settingsService.imageQuality {
    case .low:
      return 2  // Preload fewer items for low quality
    case .medium:
      return 3  // Standard preload distance
    case .high:
      return 5  // Preload more items for high quality
    }
  }
}
