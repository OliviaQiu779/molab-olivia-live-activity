import XCTest

final class CuletUITests: XCTestCase {
    @MainActor
    func testConversationJourney() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["occasion-network"].waitForExistence(timeout: 10))
        capture("01-Home")
        app.buttons["occasion-network"].tap()
        XCTAssertTrue(app.buttons["start-session"].waitForExistence(timeout: 5))
        capture("02-Prepare")
        app.buttons["start-session"].tap()
        if app.alerts["Session update"].waitForExistence(timeout: 2) {
            app.alerts.buttons["OK"].tap()
        }
        XCTAssertTrue(app.buttons["next-prompt"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["What brought you to this event?"].exists)
        capture("03-Session")

        app.buttons["next-prompt"].tap()
        XCTAssertTrue(app.staticTexts["Which part of the event were you most interested in coming for?"].waitForExistence(timeout: 5))
        app.segmentedControls.buttons["Explore"].tap()
        XCTAssertTrue(app.staticTexts["What part of your work has you most curious right now?"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Profile"].tap()
        XCTAssertTrue(app.switches["hint-mode-toggle"].waitForExistence(timeout: 5))
        capture("04-Profile")

        app.terminate()
        app.launch()
        app.tabBars.buttons["Session"].tap()
        XCTAssertTrue(app.buttons["next-prompt"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["What part of your work has you most curious right now?"].exists)
        app.swipeUp()
        app.buttons["end-session"].tap()
        XCTAssertTrue(app.buttons["keep-session"].waitForExistence(timeout: 5))
        capture("08-EndSession")
        app.buttons["keep-session"].tap()
        XCTAssertTrue(app.buttons["next-prompt"].exists)
        app.buttons["end-session"].tap()
        let endConfirmation = app.buttons["confirm-end-session"].firstMatch
        XCTAssertTrue(endConfirmation.waitForExistence(timeout: 5))
        endConfirmation.tap()
        XCTAssertTrue(app.buttons["Find your occasion"].waitForExistence(timeout: 10))

        app.tabBars.buttons["Home"].tap()
        let search = app.textFields["occasion-search"]
        search.tap()
        search.typeText("wedding")
        XCTAssertTrue(app.buttons["occasion-wedding"].exists)
        XCTAssertFalse(app.buttons["occasion-network"].exists)
        app.buttons["occasion-wedding"].tap()
        XCTAssertTrue(app.staticTexts["How do you know the couple?"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.buttons["custom-occasion"].tap()
        let custom = app.textFields["custom-name"]
        XCTAssertTrue(custom.waitForExistence(timeout: 5))
        custom.tap()
        // The search value is prefilled; append a name to exercise arbitrary text.
        custom.typeText(" book club")
        app.buttons["Continue"].tap()
        XCTAssertTrue(app.staticTexts["General prompts, with your occasion’s name."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["start-session"].exists)
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testHintMode() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        app.tabBars.buttons["Profile"].tap()
        let hintToggle = app.switches["hint-mode-toggle"]
        XCTAssertTrue(hintToggle.waitForExistence(timeout: 5))
        if hintToggle.value as? String != "1" { hintToggle.tap() }
        XCTAssertEqual(hintToggle.value as? String, "1")
        XCTAssertFalse(app.otherElements["hint-mode-preview"].exists)
        XCTAssertFalse(app.staticTexts["Ask what brought them here."].exists)
        XCTAssertFalse(app.staticTexts["On this device. No account needed."].exists)
        XCTAssertFalse(app.staticTexts["In your own words."].exists)
        capture("09-HintProfile")
        app.tabBars.buttons["Home"].tap()
        app.buttons["occasion-date"].tap()
        XCTAssertTrue(app.staticTexts["Trade a recent favorite place."].waitForExistence(timeout: 5))
        capture("10-HintPrepare")
        app.buttons["start-session"].tap()
        XCTAssertTrue(app.buttons["next-prompt"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Have you been somewhere lately that you really liked?"].exists)
        XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Unlock to interact")).firstMatch.exists)
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.01))
            .press(forDuration: 0.1, thenDragTo: springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.86)))
        for title in ["Allow", "Always Allow"] {
            if springboard.buttons[title].exists { springboard.buttons[title].firstMatch.tap() }
        }
        XCTAssertTrue(springboard.staticTexts["Trade a recent favorite place."].waitForExistence(timeout: 10))
        XCTAssertFalse(springboard.staticTexts["Have you been somewhere lately that you really liked?"].exists)
        capture("11-HintActivity")
        springboard.buttons["activity-next-prompt"].firstMatch.tap()
        app.activate()
        XCTAssertTrue(app.staticTexts["What made you choose this spot?"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.buttons["end-session"].tap()
        app.buttons["confirm-end-session"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Find your occasion"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Profile"].tap()
        if hintToggle.value as? String == "1" { hintToggle.tap() }
    }

    @MainActor
    func testLiveActivityPresentation() throws {
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launch()
        let scene = app.buttons["occasion-date"]
        XCTAssertTrue(scene.waitForExistence(timeout: 10))
        scene.tap()
        app.buttons["start-session"].tap()
        XCTAssertTrue(app.buttons["next-prompt"].waitForExistence(timeout: 10))
        capture("06-ActivitySession")
        XCUIDevice.shared.press(.home)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let top = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.01))
        let bottom = springboard.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.86))
        top.press(forDuration: 0.1, thenDragTo: bottom)
        XCTAssertTrue(springboard.staticTexts["culet"].waitForExistence(timeout: 10))
        for title in ["Allow", "Always Allow"] {
            if springboard.buttons[title].exists { springboard.buttons[title].firstMatch.tap() }
        }
        let next = springboard.buttons["activity-next-prompt"].firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        capture("05-LiveActivity")
        next.tap()
        app.activate()
        XCTAssertTrue(app.staticTexts["What made you choose this spot?"].waitForExistence(timeout: 10))
        app.swipeUp()
        app.buttons["end-session"].tap()
        app.buttons["confirm-end-session"].firstMatch.tap()
        XCTAssertTrue(app.buttons["Find your occasion"].waitForExistence(timeout: 10))
    }
}
