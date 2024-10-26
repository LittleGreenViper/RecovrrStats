/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Main Content View -
/* ###################################################################################################################################### */
/**
 */
struct RCVST_Chart1View: View {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State var data: RCVST_DataProvider

    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        GeometryReader { inGeometry in
            ScrollView {
                VStack {
                    UserTypesChart(data: data.userTypePlottable)
                }
                .padding()
                .frame(
                    minWidth: inGeometry.size.width,
                    maxWidth: inGeometry.size.width,
                    minHeight: inGeometry.size.height / 2,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - User Type Bar Chart -
/* ###################################################################################################################################### */
/**
 */
struct UserTypesChart: View {
    /* ################################################################## */
    /**
     The segregated user type data.
     */
    @State var data: [RCVST_DataProvider.RowPlottableData]
    
    /* ################################################################## */
    /**
     */
    var body: some View {
        GroupBox("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) {
            Chart {
                ForEach(data, id: \.id) { inRowData in
                    ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                        BarMark(
                            x: .value("SLUG-BAR-CHART-USER-TYPES-X".localizedVariant, inRowData.date),
                            y: .value("SLUG-BAR-CHART-USER-TYPES-Y".localizedVariant, inUserTypeData.value)
                        )
                        .offset(x: -4, y: 0)
                        .foregroundStyle(by: .value("SLUG-BAR-CHART-USER-TYPES-LEGEND".localizedVariant, inUserTypeData.userType.localizedString))
                    }
                }
            }
        }
    }
}
