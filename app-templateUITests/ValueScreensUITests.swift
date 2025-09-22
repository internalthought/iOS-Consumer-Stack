import XCTest

final class ValueScreensUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here.
    }

    @MainActor
    func testValueScreensInitialLoad() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for ValueScreensView to appear (assuming it's the first screen)
        let skipButton = app.buttons["ValueScreensSkipButton"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))

        // Check that initial elements are present
        let tabView = app.otherElements["ValueScreensTabView"]
        XCTAssertTrue(tabView.exists)

        let progressIndicator = app.progressIndicators["ValueScreensProgressIndicator"]
        XCTAssertTrue(progressIndicator.exists)

        // Check initial progress (should be 0.25 for first of 4 screens)
        XCTAssertEqual(progressIndicator.value as? String, "25%")

        // Check navigation buttons
        let previousButton = app.buttons["ValueScreensPreviousButton"]
        XCTAssertTrue(previousButton.exists)
        XCTAssertFalse(previousButton.isEnabled) // Should be disabled on first screen

        let nextButton = app.buttons["ValueScreensNextButton"]
        XCTAssertTrue(nextButton.exists)
        XCTAssertTrue(nextButton.isEnabled)
    }

    @MainActor
    func testValueScreensNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let nextButton = app.buttons["ValueScreensNextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))

        let progressIndicator = app.progressIndicators["ValueScreensProgressIndicator"]
        let previousButton = app.buttons["ValueScreensPreviousButton"]

        // Start at first screen (25%)
        XCTAssertEqual(progressIndicator.value as? String, "25%")
        XCTAssertFalse(previousButton.isEnabled)

        // Navigate to second screen
        nextButton.tap()
        XCTAssertEqual(progressIndicator.value as? String, "50%")
        XCTAssertTrue(previousButton.isEnabled)

        // Navigate to third screen
        nextButton.tap()
        XCTAssertEqual(progressIndicator.value as? String, "75%")
        XCTAssertTrue(previousButton.isEnabled)

        // Navigate to fourth screen
        nextButton.tap()
        XCTAssertEqual(progressIndicator.value as? String, "100%")
        XCTAssertTrue(previousButton.isEnabled)

        // Check that next button shows "Get Started" on last screen
        let getStartedButton = app.buttons["ValueScreensNextButton"]
        XCTAssertTrue(getStartedButton.label.contains("Get Started"))
    }

    @MainActor
    func testValueScreensSkipFunctionality() throws {
        let app = XCUIApplication()
        app.launch()

        let skipButton = app.buttons["ValueScreensSkipButton"]
        XCTAssertTrue(skipButton.waitForExistence(timeout: 5))

        // Skip should advance to last screen
        skipButton.tap()

        let progressIndicator = app.progressIndicators["ValueScreensProgressIndicator"]
        XCTAssertEqual(progressIndicator.value as? String, "100%")

        // Next button should show "Get Started"
        let nextButton = app.buttons["ValueScreensNextButton"]
        XCTAssertTrue(nextButton.label.contains("Get Started"))
    }

    @MainActor
    func testValueScreensPreviousNavigation() throws {
        let app = XCUIApplication()
        app.launch()

        let nextButton = app.buttons["ValueScreensNextButton"]
        let previousButton = app.buttons["ValueScreensPreviousButton"]
        let progressIndicator = app.progressIndicators["ValueScreensProgressIndicator"]

        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))

        // Navigate forward to third screen
        nextButton.tap()
        nextButton.tap()
        XCTAssertEqual(progressIndicator.value as? String, "75%")

        // Navigate back to second screen
        previousButton.tap()
        XCTAssertEqual(progressIndicator.value as? String, "50%")

        // Navigate back to first screen
        previousButton.tap()
        XCTAssertEqual(progressIndicator.value as? String, "25%")
        XCTAssertFalse(previousButton.isEnabled)
    }

    @MainActor
    func testValueScreensTabViewSwiping() throws {
        let app = XCUIApplication()
        app.launch()

        let tabView = app.otherElements["ValueScreensTabView"]
        let progressIndicator = app.progressIndicators["ValueScreensProgressIndicator"]

        XCTAssertTrue(tabView.waitForExistence(timeout: 5))

        // Swipe to next screen
        tabView.swipeLeft()
        XCTAssertEqual(progressIndicator.value as? String, "50%")

        // Swipe to next screen
        tabView.swipeLeft()
        XCTAssertEqual(progressIndicator.value as? String, "75%")

        // Swipe back
        tabView.swipeRight()
        XCTAssertEqual(progressIndicator.value as? String, "50%")
    }

    @MainActor
    func testValueScreensContentDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        // Check that content elements are displayed
        let titleElement = app.staticTexts["ValueScreenTitle"]
        XCTAssertTrue(titleElement.waitForExistence(timeout: 5))
        XCTAssertEqual(titleElement.label, "Welcome to Our App")

        let descriptionElement = app.staticTexts["ValueScreenDescription"]
        XCTAssertTrue(descriptionElement.exists)
        XCTAssertTrue(descriptionElement.label.contains("Discover amazing features"))

        let imageElement = app.images["ValueScreenImage"]
        XCTAssertTrue(imageElement.exists)
    }

    @MainActor
    func testValueScreensCompletion() throws {
        let app = XCUIApplication()
        app.launch()

        let nextButton = app.buttons["ValueScreensNextButton"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))

        // Navigate through all screens
        for _ in 1..<4 {
            nextButton.tap()
        }

        // On last screen, tap "Get Started" to complete
        let getStartedButton = app.buttons["ValueScreensNextButton"]
        XCTAssertTrue(getStartedButton.label.contains("Get Started"))

        // Note: Completion would navigate to next screen in the flow
        // This test verifies the button is ready for completion
        XCTAssertTrue(getStartedButton.isEnabled)
    }
}