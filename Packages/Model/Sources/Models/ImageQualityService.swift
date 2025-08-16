import Foundation
import Models
import Nuke

// MARK: - Image Quality Service
@MainActor
@Observable
public final class ImageQualityService {
    public static let shared = ImageQualityService()
    
    private let settingsService = SettingsService.shared
    
    private init() {}
    
    // MARK: - Image Pipeline Configuration
    public func configureImagePipeline() {
        let configuration = ImagePipeline.Configuration()
        
        switch settingsService.imageQuality {
        case .low:
            configuration.dataCache = nil // No caching for low quality
            configuration.imageCache = nil
            configuration.isProgressiveDecodingEnabled = false
            configuration.isDeduplicationEnabled = false
            
        case .medium:
            configuration.dataCache = ImagePipeline.shared.configuration.dataCache
            configuration.imageCache = ImagePipeline.shared.configuration.imageCache
            configuration.isProgressiveDecodingEnabled = true
            configuration.isDeduplicationEnabled = true
            
        case .high:
            configuration.dataCache = ImagePipeline.shared.configuration.dataCache
            configuration.imageCache = ImagePipeline.shared.configuration.imageCache
            configuration.isProgressiveDecodingEnabled = true
            configuration.isDeduplicationEnabled = true
        }
        
        ImagePipeline.shared = ImagePipeline(configuration: configuration)
    }
    
    // MARK: - Image Loading Options
    public func getImageLoadingOptions() -> ImageLoadingOptions {
        var options = ImageLoadingOptions()
        
        switch settingsService.imageQuality {
        case .low:
            options.processors = [Downsample(size: CGSize(width: 300, height: 300))]
            options.priority = .low
            
        case .medium:
            options.processors = [Downsample(size: CGSize(width: 600, height: 600))]
            options.priority = .normal
            
        case .high:
            options.processors = [] // No downsampling for high quality
            options.priority = .high
        }
        
        return options
    }
    
    // MARK: - Preload Configuration
    public func shouldPreloadImages() -> Bool {
        return settingsService.preloadImages
    }
    
    public func getPreloadDistance() -> Int {
        // Return how many items ahead to preload based on quality
        switch settingsService.imageQuality {
        case .low:
            return 2 // Preload fewer items for low quality
        case .medium:
            return 3 // Standard preload distance
        case .high:
            return 5 // Preload more items for high quality
        }
    }
}

// MARK: - Downsample Processor
private struct Downsample: ImageProcessing {
    let size: CGSize
    
    func process(_ image: PlatformImage) -> PlatformImage? {
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
