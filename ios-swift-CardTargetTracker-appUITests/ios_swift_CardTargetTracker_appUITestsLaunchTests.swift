//
//  ios_swift_CardTargetTracker_appUITestsLaunchTests.swift
//  ios-swift-CardTargetTracker-appUITests
//
//  Created by Xufeng Zhang on 23/10/25.
//

import XCTest

final class ios_swift_CardTargetTracker_appUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // Insert steps here to perform after app launch but before taking a screenshot,
        // such as logging into a test account or navigating somewhere in the app

        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Launch Screen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
