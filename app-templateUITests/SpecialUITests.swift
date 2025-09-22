import XCTest

final class SpecialUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        // Put teardown code here.
    }

    @MainActor
    func testSpecialViewInitialLoad() throws {
        let app = XCUIApplication()
        app.launch()

        // Wait for SpecialView to appear
        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check that initial elements are present
        XCTAssertTrue(specialTitle.exists)

        // Check for loading state initially
        let loadingIndicator = app.activityIndicators.firstMatch
        if loadingIndicator.exists {
            XCTAssertTrue(loadingIndicator.isHittable)
        }
    }

    @MainActor
    func testSpecialFeaturesDisplay() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Wait for loading to complete and features to appear
        let featuresTitle = app.staticTexts["Exclusive Special Features"]
        XCTAssertTrue(featuresTitle.waitForExistence(timeout: 10))

        // Check that special features are displayed
        let premiumFeatures = app.staticTexts["Premium Features"]
        XCTAssertTrue(premiumFeatures.exists)

        let specialOffers = app.staticTexts["Special Offers"]
        XCTAssertTrue(specialOffers.exists)

        let exclusiveContent = app.staticTexts["Exclusive Content"]
        XCTAssertTrue(exclusiveContent.exists)

        let vipSupport = app.staticTexts["VIP Support"]
        XCTAssertTrue(vipSupport.exists)
    }

    @MainActor
    func testSpecialFeatureIcons() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check that feature icons are displayed
        let starIcons = app.images.matching(identifier: "star.fill")
        XCTAssertTrue(starIcons.firstMatch.waitForExistence(timeout: 10))

        let tagIcons = app.images.matching(identifier: "tag.fill")
        XCTAssertTrue(tagIcons.firstMatch.exists)

        let bookIcons = app.images.matching(identifier: "book.fill")
        XCTAssertTrue(bookIcons.firstMatch.exists)

        let questionmarkIcons = app.images.matching(identifier: "person.fill.questionmark")
        XCTAssertTrue(questionmarkIcons.firstMatch.exists)
    }

    @MainActor
    func testSpecialFeatureStatusIcons() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check for status icons (crown for premium, checkmark for free)
        let crownIcons = app.images.matching(identifier: "crown.fill")
        let checkmarkIcons = app.images.matching(identifier: "checkmark.circle.fill")

        // At least one type of status icon should be present
        XCTAssertTrue(crownIcons.firstMatch.waitForExistence(timeout: 10) ||
                     checkmarkIcons.firstMatch.exists)
    }

    @MainActor
    func testSpecialFeatureDescriptions() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check that feature descriptions are displayed
        let premiumDesc = app.staticTexts["Access advanced tools and exclusive content"]
        XCTAssertTrue(premiumDesc.waitForExistence(timeout: 10))

        let offersDesc = app.staticTexts["Limited-time discounts and promotions"]
        XCTAssertTrue(offersDesc.exists)

        let contentDesc = app.staticTexts["Premium articles and tutorials"]
        XCTAssertTrue(contentDesc.exists)

        let supportDesc = app.staticTexts["Priority customer assistance"]
        XCTAssertTrue(supportDesc.exists)
    }

    @MainActor
    func testSpecialFeatureTapping() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Tap on a special feature
        let premiumFeature = app.staticTexts["Premium Features"]
        XCTAssertTrue(premiumFeature.waitForExistence(timeout: 10))
        premiumFeature.tap()

        // Verify that tapping doesn't crash the app
        XCTAssertTrue(app.exists)
    }

    @MainActor
    func testSpecialViewPremiumAccess() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Wait for subscription check to complete
        sleep(2)

        // Check for full access indicators
        let featuresTitle = app.staticTexts["Exclusive Special Features"]
        XCTAssertTrue(featuresTitle.waitForExistence(timeout: 10))

        // Check that all features are accessible
        let premiumFeatures = app.staticTexts["Premium Features"]
        XCTAssertTrue(premiumFeatures.exists)

        let exclusiveContent = app.staticTexts["Exclusive Content"]
        XCTAssertTrue(exclusiveContent.exists)

        let vipSupport = app.staticTexts["VIP Support"]
        XCTAssertTrue(vipSupport.exists)
    }

    @MainActor
    func testSpecialViewLimitedAccess() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Wait for subscription check
        sleep(2)

        // Check for limited access indicators
        let limitedTitle = app.staticTexts["Special Features"]
        if limitedTitle.exists {
            // Check for blurred premium features
            let blurredFeatures = app.staticTexts["Upgrade to unlock"]
            XCTAssertTrue(blurredFeatures.exists)

            // Check for lock icons
            let lockIcons = app.images.matching(identifier: "lock.fill")
            XCTAssertTrue(lockIcons.firstMatch.exists)

            // Check for upgrade prompt
            let upgradeTitle = app.staticTexts["Upgrade to Premium"]
            XCTAssertTrue(upgradeTitle.exists)

            let upgradeButton = app.buttons["Upgrade Now"]
            XCTAssertTrue(upgradeButton.exists)
        }
    }

    @MainActor
    func testSpecialViewScrollView() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check that ScrollView is present and functional
        let scrollView = app.scrollViews.firstMatch
        XCTAssertTrue(scrollView.waitForExistence(timeout: 10))

        // Test scrolling
        scrollView.swipeUp()
        scrollView.swipeDown()
    }

    @MainActor
    func testSpecialViewAccessibility() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check accessibility of key elements
        XCTAssertTrue(specialTitle.isAccessibilityElement)

        let featuresTitle = app.staticTexts["Exclusive Special Features"]
        XCTAssertTrue(featuresTitle.waitForExistence(timeout: 10))
        XCTAssertTrue(featuresTitle.isAccessibilityElement)

        let premiumFeature = app.staticTexts["Premium Features"]
        XCTAssertTrue(premiumFeature.exists)
        XCTAssertTrue(premiumFeature.isAccessibilityElement)
    }

    @MainActor
    func testSpecialFeatureCardLayout() throws {
        let app = XCUIApplication()
        app.launch()

        let specialTitle = app.staticTexts["Special"]
        XCTAssertTrue(specialTitle.waitForExistence(timeout: 5))

        // Check that feature cards have proper layout
        let premiumFeature = app.staticTexts["Premium Features"]
        XCTAssertTrue(premiumFeature.waitForExistence(timeout: 10))

        // Verify that related elements are positioned correctly
        let premiumDesc = app.staticTexts["Access advanced tools and exclusive content"]
        XCTAssertTrue(premiumDesc.exists)

        // Check that icon is present for the feature
        let starIcon = app.images["star.fill"].firstMatch
        XCTAssertTrue(starIcon.exists)
    }
}