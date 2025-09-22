import XCTest

final class LibraryUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here.
    }

    @MainActor
    func testLibraryViewInitialLoad() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for LibraryView to appear (assuming it's accessible in the tab bar)
        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Check that initial elements are present
        XCTAssertTrue(libraryTitle.exists)

        // Check for loading state initially
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.isHittable)
        }
    }

    @MainActor
    func testLibraryItemsDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Wait for loading to complete and items to appear
        let firstItem = app.staticTexts["Sample Item 1"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 10))

        // Check that all placeholder items are displayed
        let secondItem = app.staticTexts["Sample Item 2"]
        XCTAssertTrue(secondItem.exists)

        let thirdItem = app.staticTexts["Sample Item 3"]
        XCTAssertTrue(thirdItem.exists)

        // Check item descriptions
        let description = app.staticTexts["This is a placeholder item"]
        XCTAssertTrue(description.exists)
    }

    @MainActor
    func testLibraryItemIcons() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Check that document icons are displayed for each item
        let docIcons = app.images.matching(identifier: "doc.fill")
        XCTAssertTrue(docIcons.firstMatch.waitForExistence(timeout: 10))
        XCTAssertGreaterThan(docIcons.count, 0)
    }

    @MainActor
    func testLibraryAddItemFunctionality() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Wait for initial items to load
        let initialItemCount = app.staticTexts.matching(identifier: "Sample Item").count

        // Find and tap the "Add Item" button
        let addButton = app.buttons["Add Item"]
        XCTAssertTrue(addButton.waitForExistence(timeout: 10))
        addButton.tap()

        // Verify that a new item was added
        let newItemCount = app.staticTexts.matching(identifier: "Sample Item").count
        XCTAssertGreaterThan(newItemCount, initialItemCount)

        // Check that the new item appears
        let newItem = app.staticTexts["New Item"]
        XCTAssertTrue(newItem.exists)
    }

    @MainActor
    func testLibraryRemoveItemFunctionality() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Wait for items to load
        let firstItem = app.staticTexts["Sample Item 1"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 10))

        let initialItemCount = app.staticTexts.matching(identifier: "Sample Item").count

        // Long press on first item to show context menu
        firstItem.press(forDuration: 1.0)

        // Tap the remove button in context menu
        let removeButton = app.buttons["Remove"]
        if removeButton.waitForExistence(timeout: 2) {
            removeButton.tap()

            // Verify that the item was removed
            let newItemCount = app.staticTexts.matching(identifier: "Sample Item").count
            XCTAssertLessThan(newItemCount, initialItemCount)
        }
    }

    @MainActor
    func testLibraryPremiumFeaturesDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Wait for subscription check to complete
        sleep(2) // Allow time for async subscription check

        // Check for premium features section
        let savedItemsTitle = app.staticTexts["Your Saved Items"]
        XCTAssertTrue(savedItemsTitle.waitForExistence(timeout: 10))

        // Check that add button is present (indicating premium access)
        let addButton = app.buttons["Add Item"]
        XCTAssertTrue(addButton.exists)
    }

    @MainActor
    func testLibraryLimitedAccessDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Wait for subscription check
        sleep(2)

        // Check for limited access indicators
        let limitedTitle = app.staticTexts["Your Saved Items (Limited)"]
        if limitedTitle.exists {
            // Check that only 2 items are shown
            let sampleItems = app.staticTexts.matching(identifier: "Sample Item")
            XCTAssertLessThanOrEqual(sampleItems.count, 2)

            // Check for upgrade prompt
            let upgradeTitle = app.staticTexts["Upgrade to Premium"]
            XCTAssertTrue(upgradeTitle.exists)

            let upgradeButton = app.buttons["Upgrade Now"]
            XCTAssertTrue(upgradeButton.exists)
        }
    }

    @MainActor
    func testLibraryScrollView() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Check that ScrollView is present and functional
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10))

        // Test scrolling
        scrollView.swipeUp()
        scrollView.swipeDown()
    }

    @MainActor
    func testLibraryItemStatusIcons() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Check for status icons (checkmark or lock)
        let checkmarkIcons = app.images.matching(identifier: "checkmark.circle.fill")
        let lockIcons = app.images.matching(identifier: "lock.fill")

        // At least one type of status icon should be present
        XCTAssertTrue(checkmarkIcons.firstMatch.exists || lockIcons.firstMatch.exists)
    }

    @MainActor
    func testLibraryAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        let libraryTitle = app.staticTexts["Library"]
        XCTAssertTrue(libraryTitle.waitForExistence(timeout: 5))

        // Check accessibility of key elements
        XCTAssertTrue(libraryTitle.isAccessibilityElement)

        let firstItem = app.staticTexts["Sample Item 1"]
        XCTAssertTrue(firstItem.waitForExistence(timeout: 10))
        XCTAssertTrue(firstItem.isAccessibilityElement)
    }
}