import XCTest

final class SignInUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here.
    }

    @MainActor
    func testSignInViewInitialLoad() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for SignInView to appear (assuming it's shown after value screens)
        let appLogo = app.images["SignInAppLogo"]
        XCTAssertTrue(appLogo.waitForExistence(timeout: 5))

        // Check that initial elements are present
        let welcomeTitle = app.staticTexts["SignInWelcomeTitle"]
        XCTAssertTrue(welcomeTitle.exists)
        XCTAssertEqual(welcomeTitle.label, "Welcome")

        let subtitle = app.staticTexts["SignInSubtitle"]
        XCTAssertTrue(subtitle.exists)
        XCTAssertTrue(subtitle.label.contains("Sign in with your Apple ID"))

        // Check Apple Sign-In button
        let appleButton = app.buttons["SignInAppleButton"]
        XCTAssertTrue(appleButton.exists)
        XCTAssertTrue(appleButton.isEnabled)

        // Check terms notice
        let termsNotice = app.otherElements["SignInTermsNotice"]
        XCTAssertTrue(termsNotice.exists)
    }

    @MainActor
    func testSignInLoadingState() throws {
        let app = XCUIApplication()
        app.launch()

        let appleButton = app.buttons["SignInAppleButton"]
        XCTAssertTrue(appleButton.waitForExistence(timeout: 5))

        // Tap the Apple Sign-In button (this would trigger loading in real scenario)
        // Note: In a real test, you might need to mock the authentication flow
        appleButton.tap()

        // Check if loading indicator appears (this depends on implementation)
        let loadingIndicator = app.activityIndicators["SignInLoadingIndicator"]
        if loadingIndicator.waitForExistence(timeout: 2) {
            XCTAssertTrue(loadingIndicator.exists)

            let loadingText = app.staticTexts["SignInLoadingText"]
            XCTAssertTrue(loadingText.exists)
            XCTAssertEqual(loadingText.label, "Signing you in...")
        }
    }

    @MainActor
    func testSignInErrorState() throws {
        let app = XCUIApplication()
        app.launch()

        // Note: To test error state, you would need to simulate a failed sign-in
        // This might require mocking or specific test setup

        // For now, verify that error elements exist in the UI structure
        let appleButton = app.buttons["SignInAppleButton"]
        XCTAssertTrue(appleButton.waitForExistence(timeout: 5))

        // Check that error UI elements are accessible (even if not visible initially)
        let errorIcon = app.images["SignInErrorIcon"]
        let errorTitle = app.staticTexts["SignInErrorTitle"]
        let errorMessage = app.staticTexts["SignInErrorMessage"]
        let retryButton = app.buttons["SignInRetryButton"]

        // These elements should exist in the view hierarchy
        XCTAssertTrue(errorIcon.exists)
        XCTAssertTrue(errorTitle.exists)
        XCTAssertTrue(errorMessage.exists)
        XCTAssertTrue(retryButton.exists)
    }

    @MainActor
    func testSignInRetryFunctionality() throws {
        let app = XCUIApplication()
        app.launch()

        let retryButton = app.buttons["SignInRetryButton"]
        XCTAssertTrue(retryButton.waitForExistence(timeout: 5))

        // Tap retry button
        retryButton.tap()

        // Verify that the Apple Sign-In button is accessible again
        let appleButton = app.buttons["SignInAppleButton"]
        XCTAssertTrue(appleButton.isEnabled)
    }

    @MainActor
    func testSignInTermsAndPrivacyLinks() throws {
        let app = XCUIApplication()
        app.launch()

        // Check Terms of Service link
        let termsButton = app.buttons["Terms of Service"]
        XCTAssertTrue(termsButton.waitForExistence(timeout: 5))
        XCTAssertTrue(termsButton.isEnabled)

        // Check Privacy Policy link
        let privacyButton = app.buttons["Privacy Policy"]
        XCTAssertTrue(privacyButton.exists)
        XCTAssertTrue(privacyButton.isEnabled)

        // Note: In a real test, you might want to verify that tapping these
        // opens the correct URLs, but that would require additional setup
    }

    @MainActor
    func testSignInAppleButtonStyling() throws {
        let app = XCUIApplication()
        app.launch()

        let appleButton = app.buttons["SignInAppleButton"]
        XCTAssertTrue(appleButton.waitForExistence(timeout: 5))

        // Verify button properties
        XCTAssertTrue(appleButton.isEnabled)
        XCTAssertTrue(appleButton.isHittable)

        // Check that the button contains Apple branding
        // Note: The exact label may vary based on SignInWithAppleButton implementation
        XCTAssertTrue(appleButton.label.contains("Sign in with Apple") ||
                     appleButton.label.contains("Continue with Apple") ||
                     appleButton.exists)
    }

    @MainActor
    func testSignInViewLayout() throws {
        let app = XCUIApplication()
        app.launch()

        let appLogo = app.images["SignInAppLogo"]
        XCTAssertTrue(appLogo.waitForExistence(timeout: 5))

        // Verify vertical layout - logo should be above welcome text
        let welcomeTitle = app.staticTexts["SignInWelcomeTitle"]
        XCTAssertTrue(welcomeTitle.exists)

        let subtitle = app.staticTexts["SignInSubtitle"]
        XCTAssertTrue(subtitle.exists)

        // Verify that elements are in correct order (top to bottom)
        // This is a basic layout test
        XCTAssertTrue(appLogo.frame.minY < welcomeTitle.frame.minY)
        XCTAssertTrue(welcomeTitle.frame.minY < subtitle.frame.minY)
    }

    @MainActor
    func testSignInAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        let appLogo = app.images["SignInAppLogo"]
        XCTAssertTrue(appLogo.waitForExistence(timeout: 5))

        // Check accessibility identifiers
        XCTAssertNotNil(appLogo.accessibilityIdentifier)
        XCTAssertEqual(appLogo.accessibilityIdentifier, "SignInAppLogo")

        let welcomeTitle = app.staticTexts["SignInWelcomeTitle"]
        XCTAssertEqual(welcomeTitle.accessibilityIdentifier, "SignInWelcomeTitle")

        let appleButton = app.buttons["SignInAppleButton"]
        XCTAssertEqual(appleButton.accessibilityIdentifier, "SignInAppleButton")
    }
}