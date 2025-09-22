import Foundation
import OSLog

/// Configuration class for storing application settings and API keys
/// This struct provides centralized access to all application configuration,
/// with secure environment variable management for production deployments.
///
/// ## Usage Examples
/// ```swift
/// // Access configuration values
/// let url = Configuration.supabaseURL
/// let key = Configuration.supabaseAnonKey
///
/// // Validate configuration at app startup
/// switch Configuration.validateConfiguration() {
/// case .success:
///     print("Configuration is valid")
/// case .failure(let error):
///     print("Configuration error: \(error.localizedDescription)")
/// }
/// ```
struct Configuration {

    // MARK: - Private Logger

    /// Logger for configuration-related events
    private static let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "app-template", category: "Configuration")

    private static let buildConfig: [String: String] = {
        #if DEBUG
        let filename = "DebugConfig"
        #else
        let filename = "ReleaseConfig"
        #endif

        let url = Bundle.main.url(forResource: filename, withExtension: "plist", subdirectory: "Config")
            ?? Bundle.main.url(forResource: filename, withExtension: "plist")

        if let url, let data = try? Data(contentsOf: url),
           let dict = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] {
            var result: [String: String] = [:]
            for (k, v) in dict {
                if let s = v as? String { result[k] = s }
            }
            return result
        }
        logger.error("Configuration plist \(filename).plist not found in bundle")
        return [:]
    }()

    private static func configValue(_ key: String) -> String? {
        buildConfig[key].flatMap { $0.isEmpty ? nil : $0 }
    }

    // MARK: - Supabase Configuration

    /// Supabase project URL retrieved from environment variables
    /// Falls back to development URL if not set in production
    ///
    /// - Returns: The Supabase project URL as a string
    /// - Note: Set SUPABASE_URL environment variable in production
    static var supabaseURL: String {
        if let url = ProcessInfo.processInfo.environment["SUPABASE_URL"], !url.isEmpty {
            return url
        }
        if let url = configValue("SupabaseURL") {
            return url
        }
        logger.error("Supabase URL not found in environment or plist")
        return "https://your-production-project.supabase.co"
    }

    /// Supabase anonymous key retrieved from environment variables
    /// This key is safe to expose in client-side code
    ///
    /// - Returns: The Supabase anonymous key as a string
    /// - Note: Set SUPABASE_ANON_KEY environment variable in production
    static var supabaseAnonKey: String {
        if let key = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !key.isEmpty {
            return key
        }
        if let key = configValue("SupabaseAnonKey") {
            return key
        }
        logger.error("Supabase anon key not found in environment or plist")
        return "your-production-anon-key"
    }

    // MARK: - RevenueCat Configuration

    /// RevenueCat API key retrieved from environment variables
    /// Uses public key format (prefixed with 'appl_')
    ///
    /// - Returns: The RevenueCat API key as a string
    /// - Note: Set REVENUECAT_API_KEY environment variable in production
    static var revenueCatAPIKey: String {
        if let key = ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"], !key.isEmpty {
            return key
        }
        if let key = configValue("RevenueCatAPIKey") {
            return key
        }
        logger.error("RevenueCat API key not found in environment or plist")
        return "appl_your_production_key"
    }

    /// Optional RevenueCat Entitlement Identifier to check for active subscription
    /// If not provided, the app will fall back to checking any active entitlement.
    ///
    /// - Returns: The entitlement identifier string, or nil if not configured
    static var revenueCatEntitlementID: String? {
        if let id = ProcessInfo.processInfo.environment["REVENUECAT_ENTITLEMENT_ID"], !id.isEmpty {
            return id
        }
        if let id = configValue("RevenueCatEntitlementID"), !id.isEmpty {
            return id
        }
        return nil
    }

    // MARK: - Configuration Validation

    /// Validates all required configuration values
    /// Checks that all necessary environment variables are set and valid
    ///
    /// - Returns: Result indicating success or specific configuration error
    /// - Note: Call this method at app startup to ensure proper configuration
    ///
    /// ## Usage Example
    /// ```swift
    /// let result = Configuration.validateConfiguration()
    /// switch result {
    /// case .success:
    ///     // Proceed with app initialization
    /// case .failure(let error):
    ///     // Handle configuration error
    ///     fatalError("Configuration validation failed: \(error.localizedDescription)")
    /// }
    /// ```
    static func validateConfiguration() -> Result<Void, ConfigurationError> {
        logger.info("Starting configuration validation")

        // Validate Supabase URL
        let supabaseURL = self.supabaseURL
        guard !supabaseURL.isEmpty else {
            logger.error("Supabase URL is empty")
            return .failure(.missingSupabaseURL)
        }

        guard supabaseURL.hasPrefix("https://") else {
            logger.error("Supabase URL must use HTTPS: \(supabaseURL)")
            return .failure(.invalidSupabaseURL)
        }

        // Validate Supabase anonymous key
        let supabaseKey = self.supabaseAnonKey
        guard !supabaseKey.isEmpty else {
            logger.error("Supabase anonymous key is empty")
            return .failure(.missingSupabaseKey)
        }

        guard supabaseKey.count > 50 else { // Basic validation for JWT-like key
            logger.error("Supabase anonymous key appears invalid (too short)")
            return .failure(.invalidSupabaseKey)
        }

        // Validate RevenueCat API key
        let revenueCatKey = self.revenueCatAPIKey
        guard !revenueCatKey.isEmpty else {
            logger.error("RevenueCat API key is empty")
            return .failure(.missingRevenueCatKey)
        }

        guard revenueCatKey.hasPrefix("appl_") else {
            logger.error("RevenueCat API key must be a public key (start with 'appl_')")
            return .failure(.invalidRevenueCatKey)
        }

        logger.info("Configuration validation completed successfully")
        return .success(())
    }

    // MARK: - Environment Detection

    /// Determines if the app is running in production environment
    /// Based on presence of production environment variables
    ///
    /// - Returns: True if production environment variables are detected
    static var isProductionEnvironment: Bool {
        let hasPlistValues = configValue("SupabaseURL") != nil &&
                             configValue("SupabaseAnonKey") != nil &&
                             configValue("RevenueCatAPIKey") != nil
        let hasEnv = ProcessInfo.processInfo.environment["SUPABASE_URL"]?.isEmpty == false &&
                     ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"]?.isEmpty == false &&
                     ProcessInfo.processInfo.environment["REVENUECAT_API_KEY"]?.isEmpty == false
        return hasPlistValues || hasEnv
    }
}

/// Configuration-related error types
/// Provides detailed error information for configuration validation failures
enum ConfigurationError: LocalizedError {
    /// Supabase URL is missing or empty
    case missingSupabaseURL
    /// Supabase URL is invalid (not HTTPS)
    case invalidSupabaseURL
    /// Supabase anonymous key is missing or empty
    case missingSupabaseKey
    /// Supabase anonymous key is invalid
    case invalidSupabaseKey
    /// RevenueCat API key is missing or empty
    case missingRevenueCatKey
    /// RevenueCat API key is invalid
    case invalidRevenueCatKey

    /// Human-readable error description
    var errorDescription: String? {
        switch self {
        case .missingSupabaseURL:
            return "Supabase URL is not configured. Set SUPABASE_URL environment variable."
        case .invalidSupabaseURL:
            return "Supabase URL must use HTTPS protocol."
        case .missingSupabaseKey:
            return "Supabase anonymous key is not configured. Set SUPABASE_ANON_KEY environment variable."
        case .invalidSupabaseKey:
            return "Supabase anonymous key is invalid."
        case .missingRevenueCatKey:
            return "RevenueCat API key is not configured. Set REVENUECAT_API_KEY environment variable."
        case .invalidRevenueCatKey:
            return "RevenueCat API key must be a public key (starting with 'appl_')."
        }
    }

    /// Recovery suggestion for the error
    var recoverySuggestion: String? {
        switch self {
        case .missingSupabaseURL, .missingSupabaseKey:
            return "Ensure SUPABASE_URL and SUPABASE_ANON_KEY are set in environment variables."
        case .invalidSupabaseURL:
            return "Update SUPABASE_URL to use HTTPS protocol."
        case .invalidSupabaseKey:
            return "Verify SUPABASE_ANON_KEY is correct in environment variables."
        case .missingRevenueCatKey:
            return "Set REVENUECAT_API_KEY environment variable with your public RevenueCat key."
        case .invalidRevenueCatKey:
            return "Use a public RevenueCat API key (prefixed with 'appl_')."
        }
    }
}

extension Configuration {
    static var termsOfServiceURL: String {
        if let url = ProcessInfo.processInfo.environment["TERMS_URL"], !url.isEmpty {
            return url
        }
        if let url = configValue("TermsURL") {
            return url
        }
        logger.warning("Using fallback Terms of Service URL - set TERMS_URL env variable or Config plist")
        return "https://example.com/terms"
    }

    static var privacyPolicyURL: String {
        if let url = ProcessInfo.processInfo.environment["PRIVACY_URL"], !url.isEmpty {
            return url
        }
        if let url = configValue("PrivacyURL") {
            return url
        }
        logger.warning("Using fallback Privacy Policy URL - set PRIVACY_URL env variable or Config plist")
        return "https://example.com/privacy"
    }
}