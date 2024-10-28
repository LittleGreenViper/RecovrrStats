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
            .navigationDestination(for: RootStackView.ChartTypes.self) { _ in RCVST_Chart1View(data: data) }
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
    }

    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @ObservedObject var data: RCVST_DataProvider

    /* ################################################################## */
    /**
     */
    var body: some View {
        NavigationStack {
            Text(String(format: "SLUG-HEADER-FORMAT".localizedVariant, data.count, data.formattedStartDate, data.formattedEndDate))
            List(ChartTypes.allCases, id: \.self) { inChartType in NavigationLink("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant, value: inChartType) }
            .navigationDestination(for: ChartTypes.self) { _ in RCVST_Chart1View(data: data) }
            .navigationTitle("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
        }
    }
}
