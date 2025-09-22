import Foundation
import Testing
@testable import app_template

struct ValueScreensViewModelTests {

    @Test func testInit() {
        // Given & When
        let viewModel = ValueScreensViewModel()

        // Then
        #expect(viewModel.valueScreens.count == 4)
        #expect(viewModel.currentIndex == 0)
        #expect(!viewModel.isLoading)
        #expect(viewModel.error == nil)
        #expect(viewModel.totalScreens == 4)
    }

    @Test func testCurrentScreenValidIndex() {
        // Given
        let viewModel = ValueScreensViewModel()

        // When
        let current = viewModel.currentScreen()

        // Then
        #expect(current != nil)
        #expect(current?.title == "Welcome to Our App")
    }

    @Test func testCurrentScreenInvalidIndex() {
        // Given
        let viewModel = ValueScreensViewModel()
        viewModel.currentIndex = 10 // Invalid index

        // When
        let current = viewModel.currentScreen()

        // Then
        #expect(current == nil)
        #expect(viewModel.error != nil)
    }

    @Test func testNextScreen() {
        // Given
        let viewModel = ValueScreensViewModel()

        // When & Then - Can move to next
        let canMove1 = viewModel.nextScreen()
        #expect(canMove1)
        #expect(viewModel.currentIndex == 1)

        // Can move to next again
        let canMove2 = viewModel.nextScreen()
        #expect(canMove2)
        #expect(viewModel.currentIndex == 2)

        // Can move to next again
        let canMove3 = viewModel.nextScreen()
        #expect(canMove3)
        #expect(viewModel.currentIndex == 3)

        // Cannot move further
        let canMove4 = viewModel.nextScreen()
        #expect(!canMove4)
        #expect(viewModel.currentIndex == 3)
    }

    @Test func testPreviousScreen() {
        // Given
        let viewModel = ValueScreensViewModel()
        viewModel.currentIndex = 2

        // When & Then - Can move to previous
        let canMove1 = viewModel.previousScreen()
        #expect(canMove1)
        #expect(viewModel.currentIndex == 1)

        // Can move to previous again
        let canMove2 = viewModel.previousScreen()
        #expect(canMove2)
        #expect(viewModel.currentIndex == 0)

        // Cannot move further
        let canMove3 = viewModel.previousScreen()
        #expect(!canMove3)
        #expect(viewModel.currentIndex == 0)
    }

    @Test func testSkipToEnd() {
        // Given
        let viewModel = ValueScreensViewModel()

        // When & Then - Can skip to end
        let canSkip = viewModel.skipToEnd()
        #expect(canSkip)
        #expect(viewModel.currentIndex == 3)

        // Cannot skip again when already at end
        let canSkipAgain = viewModel.skipToEnd()
        #expect(!canSkipAgain)
        #expect(viewModel.currentIndex == 3)
    }

    @Test func testHasNext() {
        // Given
        let viewModel = ValueScreensViewModel()

        // When & Then - Initially has next
        #expect(viewModel.hasNext())

        // Move to last screen
        viewModel.currentIndex = 3
        #expect(!viewModel.hasNext())
    }

    @Test func testHasPrevious() {
        // Given
        let viewModel = ValueScreensViewModel()

        // When & Then - Initially no previous
        #expect(!viewModel.hasPrevious())

        // Move to second screen
        viewModel.currentIndex = 1
        #expect(viewModel.hasPrevious())
    }

    @Test func testReset() {
        // Given
        let viewModel = ValueScreensViewModel()
        viewModel.currentIndex = 2
        viewModel.error = "Test error"
        viewModel.isLoading = true

        // When
        viewModel.reset()

        // Then
        #expect(viewModel.currentIndex == 0)
        #expect(viewModel.error == nil)
        #expect(!viewModel.isLoading)
    }

    @Test func testProgress() {
        // Given
        let viewModel = ValueScreensViewModel()

        // When & Then - Initial progress
        #expect(viewModel.progress() == 0.25) // 1/4

        // Move to second screen
        viewModel.currentIndex = 1
        #expect(viewModel.progress() == 0.5) // 2/4

        // Move to third screen
        viewModel.currentIndex = 2
        #expect(viewModel.progress() == 0.75) // 3/4

        // Move to last screen
        viewModel.currentIndex = 3
        #expect(viewModel.progress() == 1.0) // 4/4
    }
}