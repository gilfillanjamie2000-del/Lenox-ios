import XCTest

final class StudioUITests: XCTestCase {
    private var app: XCUIApplication!
    override func setUpWithError() throws { continueAfterFailure = false; app = XCUIApplication() }
    override func tearDownWithError() throws { XCUIDevice.shared.orientation = .portrait; app.terminate() }
    private func launch(_ extra: [String] = []) {
        app.launchArguments = ["--ci-ui-fixture"] + extra
        app.launch()
        XCTAssertTrue(app.buttons["dock-home"].waitForExistence(timeout: 15))
    }
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func openRealFilesPicker() {
        app.launchArguments = ["--ci-picker-fixture", "--ci-screen", "library"]
        app.launch()
        let importButton = app.buttons["selectAudio"]
        XCTAssertTrue(importButton.waitForExistence(timeout: 15))
        importButton.tap()
        // UIKit starts in ordinary browsing mode. Enter its actual Select mode
        // so both the one-file and multi-file cases exercise the Open action.
        let select = app.buttons["Select"]
        if !select.exists {
            let actions = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "DOC.itemCollectionMenuButton")).firstMatch
            XCTAssertTrue(actions.waitForExistence(timeout: 15), app.debugDescription)
            actions.tap()
        }
        XCTAssertTrue(select.waitForExistence(timeout: 5), app.debugDescription)
        select.tap()
    }
    private func selectFile(_ name: String) {
        // Files separates known extensions in its accessibility label, e.g.
        // "Picker-one, wav, ...", despite showing a filename on screen.
        let stem = (name as NSString).deletingPathExtension
        let file = app.cells.matching(NSPredicate(format: "label BEGINSWITH[c] %@", stem)).firstMatch
        XCTAssertTrue(file.waitForExistence(timeout: 15), app.debugDescription)
        file.tap()
    }
    private func confirmOpen(_ captureName: String) {
        let open = app.buttons["Open"]
        XCTAssertTrue(open.waitForExistence(timeout: 5), app.debugDescription)
        XCTAssertTrue(open.isEnabled, "Files Open must be enabled after selection")
        capture(captureName)
        open.tap()
    }
    func testFilesOpenImportsMultipleActualSelectionsAndCancelPreservesThem() {
        openRealFilesPicker()
        selectFile("Picker-one.wav")
        selectFile("Picker-two.bin")
        confirmOpen("files-multi-open-enabled")
        let result = app.staticTexts["import-result"]
        let imported = NSPredicate(format: "label CONTAINS %@", "Imported 2 songs")
        expectation(for: imported, evaluatedWith: result)
        waitForExpectations(timeout: 15)
        XCTAssertTrue(app.staticTexts["Picker-one"].exists)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Picker-two"].exists)
        capture("files-multi-imported")
        app.swipeDown()
        app.buttons["selectAudio"].tap()
        XCTAssertTrue(app.buttons["Cancel"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["Picker-one"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Picker-two"].exists)
    }
    func testFilesOpenImportsOneActualSelection() {
        openRealFilesPicker()
        selectFile("Picker-one.wav")
        confirmOpen("files-single-open-enabled")
        let imported = NSPredicate(format: "label CONTAINS %@", "Imported 1 song")
        expectation(for: imported, evaluatedWith: app.staticTexts["import-result"])
        waitForExpectations(timeout: 15)
        app.buttons["load-0-Picker-one"].tap()
        XCTAssertTrue(app.buttons["mixer-play-0"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.descendants(matching: .any)["platter-0"].value as? String, "Paused")
    }
    func testFilesOpenRejectsUndecodableSelectionWithoutSavingIt() {
        openRealFilesPicker()
        selectFile("Picker-invalid.txt")
        confirmOpen("files-invalid-selection")
        let rejected = NSPredicate(format: "label CONTAINS %@", "Import was not saved")
        expectation(for: rejected, evaluatedWith: app.staticTexts["import-result"])
        waitForExpectations(timeout: 15)
        XCTAssertTrue(app.staticTexts["No music saved"].exists)
    }
    func testOriginalHomeAndMoreRoutes() {
        launch()
        XCTAssertTrue(app.buttons["lenoxMix"].exists)
        capture("home-original-art")
        app.buttons["lenoxMix"].tap()
        XCTAssertTrue(app.staticTexts["✧ MIX ASSISTANT"].exists)
        app.buttons["dock-more"].tap()
        app.buttons["more-assistant"].tap()
        XCTAssertTrue(app.staticTexts["✧ MIX ASSISTANT"].exists)
        app.buttons["dock-more"].tap()
        app.buttons["more-status"].tap()
        XCTAssertTrue(app.staticTexts["Offline studio"].exists)
    }
    func testPlaylistSearchEditCancelAndLoad() {
        launch(["--ci-screen", "playlists"])
        let row = app.buttons["playlist-row-Night set"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["playlist-edit"].exists)
        capture("playlist-details")
        app.buttons["playlist-edit"].tap()
        let name = app.textFields["playlist-name"]
        XCTAssertTrue(name.waitForExistence(timeout: 3))
        name.tap(); name.typeText(" changed")
        app.buttons["playlist-cancel"].tap()
        XCTAssertTrue(app.navigationBars["Night set"].waitForExistence(timeout: 3))
        app.buttons["load-0-UI-tone-440"].tap()
        XCTAssertTrue(app.buttons["mixer-play-0"].waitForExistence(timeout: 3))
        XCTAssertEqual(app.descendants(matching: .any)["platter-0"].value as? String, "Paused")
        capture("mixer-portrait")
    }
    func testPlaylistCreateSaveCollisionAndDelete() {
        launch(["--ci-screen", "playlists"])
        app.buttons["playlist-create"].tap()
        let name = app.textFields["playlist-name"]
        name.tap(); name.typeText("Test set")
        app.buttons["playlist-add-UI-tone-440"].tap()
        app.buttons["playlist-save"].tap()
        let row = app.buttons["playlist-row-Test set"]
        XCTAssertTrue(row.waitForExistence(timeout: 3)); row.tap()
        XCTAssertTrue(app.staticTexts["UI-tone-440"].exists)
        app.buttons["playlist-edit"].tap()
        let field = app.textFields["playlist-name"]
        field.tap()
        // Replace using a deterministic delete sequence, without clipboard access.
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 20) + "Night set")
        app.buttons["playlist-save"].tap()
        XCTAssertTrue(app.alerts["Playlist was not saved"].waitForExistence(timeout: 3))
        app.alerts.buttons["OK"].tap(); app.buttons["playlist-cancel"].tap()
        app.buttons["playlist-delete"].tap()
        app.alerts.buttons["Delete playlist"].tap()
        XCTAssertTrue(app.buttons["playlist-create"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.buttons["playlist-row-Test set"].exists)
    }
    func testMixerPlaybackRotationAndExitPreserveDeck() {
        launch(["--ci-screen", "playlists"])
        app.buttons["playlist-row-Night set"].tap()
        app.buttons["load-0-UI-tone-440"].tap()
        app.buttons["mixer-play-0"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["platter-0"].value as? String, "Playing")
        XCUIDevice.shared.orientation = .landscapeLeft
        let rotated = NSPredicate { _, _ in self.app.windows.firstMatch.frame.width > self.app.windows.firstMatch.frame.height }
        expectation(for: rotated, evaluatedWith: nil)
        waitForExpectations(timeout: 5)
        XCTAssertTrue(app.buttons["mixer-load-1"].waitForExistence(timeout: 3))
        let window = app.windows.firstMatch.frame
        for element in [app.buttons["mixer-exit"], app.buttons["mixer-load-0"], app.buttons["mixer-load-1"], app.buttons["mixer-play-0"], app.sliders["crossfader"]] {
            XCTAssertTrue(window.contains(element.frame), "Control outside visible landscape window: \(element.identifier) \(element.frame) in \(window)")
        }
        XCTAssertTrue(app.buttons["mixer-play-0"].isHittable)
        XCTAssertTrue(app.sliders["crossfader"].isHittable)
        capture("mixer-landscape")
        app.buttons["mixer-exit"].tap()
        XCTAssertTrue(app.buttons["dock-mixer"].waitForExistence(timeout: 5))
        app.buttons["dock-mixer"].tap()
        XCTAssertTrue(app.staticTexts["UI-tone-440"].exists)
        XCTAssertFalse(app.buttons["intro-skip"].exists)
    }
    func testIntroSkipAndNoReplay() {
        app.launchArguments = ["--ci-intro"]
        app.launch()
        XCTAssertTrue(app.buttons["intro-skip"].waitForExistence(timeout: 5))
        capture("intro-native-video")
        app.buttons["intro-skip"].tap()
        XCTAssertTrue(app.buttons["dock-mixer"].waitForExistence(timeout: 3))
        app.buttons["dock-mixer"].tap(); app.buttons["mixer-exit"].tap()
        XCTAssertFalse(app.buttons["intro-skip"].exists)
    }
    func testIntroCompletesOffline() {
        app.launchArguments = ["--ci-intro"]
        app.launch()
        XCTAssertTrue(app.buttons["intro-skip"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["dock-home"].waitForExistence(timeout: 17))
        XCTAssertFalse(app.buttons["intro-skip"].exists)
    }
    func testMissingIntroFallsThrough() {
        app.launchArguments = ["--ci-intro", "--ci-intro-missing"]
        app.launch()
        XCTAssertTrue(app.buttons["dock-home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["intro-skip"].exists)
    }
    func testBackgroundingIntroDoesNotReplay() {
        app.launchArguments = ["--ci-intro"]
        app.launch()
        XCTAssertTrue(app.buttons["intro-skip"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.buttons["dock-home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["intro-skip"].exists)
    }
}
