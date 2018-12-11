/**
 © Copyright 2018, The Great Rift Valley Software Company. All rights reserved.
 
 This code is proprietary and confidential code,
 It is NOT to be reused or combined into any application,
 unless done so, specifically under written license from The Great Rift Valley Software Company.
 
 The Great Rift Valley Software Company: https://riftvalleysoftware.com
 */

import XCTest

class Rift_Valley_Alarm_Clock_UITests: XCTestCase {

    override func setUp() {
        continueAfterFailure = false
        XCUIApplication().launch()
        XCUIApplication().activate()
    }

    override func tearDown() {
        XCUIApplication().terminate()
    }
    
    func testExample() {
        
        let app = XCUIApplication()
        app.staticTexts["The Main Time Display"].tap()
        
        let pickerWheel = app.pickers["This is a Picker That Allows You to Choose A Display Font"].children(matching: .pickerWheel).element
        pickerWheel.tap()
        app.pickers["This is a Picker View That Allows You to Select A Font Color"].children(matching: .pickerWheel).element/*@START_MENU_TOKEN@*/.press(forDuration: 1.1);/*[[".tap()",".press(forDuration: 1.1);"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        pickerWheel.swipeUp()

    }
}
