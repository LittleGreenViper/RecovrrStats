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
 This displays a simple bar chart of the users, segeregated by the type of user.
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
        Chart(data) { inRowData in
                ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                    BarMark(
                        x: .value("SLUG-BAR-CHART-USER-TYPES-X".localizedVariant, inRowData.date),
                        y: .value("SLUG-BAR-CHART-USER-TYPES-Y".localizedVariant, inUserTypeData.value)
                    )
                    .foregroundStyle(by: .value("SLUG-BAR-CHART-USER-TYPES-LEGEND".localizedVariant, inUserTypeData.userType.localizedString))
                }
            }
        }
        .chartYAxisLabel("Users", spacing: 12)
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(anchor: .trailing)
            }
        }
        .chartXAxisLabel("Date", alignment: .bottom)
        .chartXAxis {
            AxisMarks(preset: .aligned, position: .bottom) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel()
            }
        }
        .padding()
    }
}
