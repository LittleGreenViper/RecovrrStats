/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData

/* ###################################################################################################################################### */
// MARK: - Initial View -
/* ###################################################################################################################################### */
/**
 */
struct RCVST_InitialContentView: View {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @ObservedObject var data = RCVST_DataProvider()

    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        RootStackView(data: data)
            .navigationBarTitleDisplayMode(.large)
    }
}

struct RootStackView: View {
    /* ################################################################################################################################## */
    // MARK: These are the types of charts we can have.
    /* ################################################################################################################################## */
    /**
     */
    enum ChartTypes: String, CaseIterable {
        /* ############################################################## */
        /**
         */
        case userTotals = "User Totals"
        
        /* ############################################################## */
        /**
         */
        case signupTotals = "Signup Totals"
    }

    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State var data: RCVST_DataProvider

    /* ################################################################## */
    /**
     */
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) { RCVST_Chart1View(data: data) }
                NavigationLink("SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant) { RCVST_Chart2View(data: data) }
            }
            .navigationTitle("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
        }
    }
}
