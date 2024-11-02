/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData

/* ###################################################################################################################################### */
// MARK: - Special Date Extension For Subtracting Dates -
/* ###################################################################################################################################### */
extension Date {
    /* ################################################################## */
    /**
     A simple minus operator for dates.
     
     - paremeter lhs: The left-hand side of the subtration
     - parameter rhs: The right-hand side of the subtraction.
     - returns: A TimeInterval, with the number of seconds between the dates. If rhs > lhs, it is negative.
     */
    static func - (lhs: Date, rhs: Date) -> TimeInterval { lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate }
}

/* ###################################################################################################################################### */
// MARK: - Main App -
/* ###################################################################################################################################### */
/**
 This is the main stats viewer app.
 */
@main
struct RCVST_App: App {
    /* ################################################################## */
    /**
     The initial app screen.
     */
    var body: some Scene {
        /* ############################################################## */
        /**
         The main scene screen.
         */
        WindowGroup { RCVST_InitialContentView() }
    }
}
