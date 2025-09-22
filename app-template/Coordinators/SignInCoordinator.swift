import SwiftUI
import AuthenticationServices

/// Coordinator for managing Apple Sign-In presentation context
/// Conforms to ASAuthorizationControllerPresentationContextProviding to provide the presentation anchor
class SignInCoordinator: NSObject, ASAuthorizationControllerPresentationContextProviding, ObservableObject {

    // MARK: - Properties

    /// The view controller to use for presentation
    private weak var viewController: UIViewController?

    // MARK: - Initialization

    /// Initialize with a view controller for presentation
    /// - Parameter viewController: The view controller to use for presenting the authorization interface
    init(viewController: UIViewController?) {
        self.viewController = viewController
        super.init()
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    /// Provides the presentation anchor for the authorization controller
    /// - Parameter controller: The authorization controller requesting the anchor
    /// - Returns: The window to use for presenting the authorization interface
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Try to get the key window from the view controller's window scene
        if let window = viewController?.view.window {
            return window
        }

        // Fallback to the key window from connected scenes
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            // Last resort fallback
            return ASPresentationAnchor()
        }

        return keyWindow
    }
}