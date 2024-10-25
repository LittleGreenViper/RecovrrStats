/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts

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
                    Chart {
                        ForEach(data.userTypePlottable, id: \.id) { inRowData in
                            ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                                BarMark(
                                    x: .value("Date", inRowData.date),
                                    y: .value("Users", inUserTypeData.value)
                                )
                                .foregroundStyle(by: .value("User Type", inUserTypeData.userType.localizedString))
                            }
                        }
                    }
                }
                .padding()
                .frame(
                    minWidth: inGeometry.size.width,
                    maxWidth: inGeometry.size.width,
                    minHeight: 300,
                    maxHeight: 300,
                    alignment: .topLeading
                )
            }
        }
    }
}
