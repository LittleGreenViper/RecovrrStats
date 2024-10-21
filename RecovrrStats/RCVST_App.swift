/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData

/* ###################################################################################################################################### */
// MARK: - Main App -
/* ###################################################################################################################################### */
/**
 This is the main stats viewer app.
 
 It is a class, to make setting up the data frame easier.
 */
@main
struct RCVST_App: App {
    /* ################################################################## */
    /**
     */
    var body: some Scene {
        WindowGroup {
            RCVST_ContentView()
        }
    }
}
