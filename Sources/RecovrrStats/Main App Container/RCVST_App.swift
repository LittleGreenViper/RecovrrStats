/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI

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
     Padding for the right side. This allows the last X-axis value label to show.
     */
    static let sidePadding = CGFloat(20)
    
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
