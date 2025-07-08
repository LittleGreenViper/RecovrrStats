/*
 © Copyright 2024-2025, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import SwiftUI
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - "As Of Today" Summary View -
/* ###################################################################################################################################### */
/**
 This displays a list of significant aggregate data points, as of today.
 */
struct RCVST_SummaryView: View {
    /* ##################################################### */
    /**
     This declares a local type that will contain our list item data.
     */
    struct SummaryRow: Identifiable {
        /* ################################################# */
        /**
         This makes it identifiable (for the ForEach).
         */
        let id = UUID()
        
        /* ################################################# */
        /**
         The prompt.
         */
        let key: String
        
        /* ################################################# */
        /**
         The value display.
         */
        let value: Text
        
        /* ################################################# */
        /**
         The color to use.
         */
        let color: Color?
    }

    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     Used to allow the summary to return to the root screen.
     */
    @Binding var path: NavigationPath
    
    /* ##################################################### */
    /**
     The data we'll be mining.
     */
    @State var data: RCVST_DataProvider?

    /* ##################################################### */
    /**
     Displays the list of items in the summary.
     */
    var body: some View {
        if let data = self.data {
            let rows: [SummaryRow] = [
                SummaryRow(key: "SLUG-FIRST-SAMPLE-PROMPT", value: Text(data.startDate, format: .dateTime.day().month().year()), color: nil),
                SummaryRow(key: "SLUG-LAST-SAMPLE-PROMPT\(data.lastSampleWasNoon ? "" : "-2")", value: Text(data.endDate, format: .dateTime.day().month().year()), color: nil),
                SummaryRow(key: "SLUG-TOTAL-USERS-PROMPT", value: Text("\(data.totalUsers)"), color: nil),
                SummaryRow(key: "SLUG-TOTAL-ACTIVE-PROMPT", value: Text("\(data.totalActive)"), color: .green),
                SummaryRow(key: "SLUG-TOTAL-INACTIVE-PROMPT", value: Text("\(data.totalInactive)"), color: .blue),
                SummaryRow(key: "SLUG-TOTAL-DEL-PROMPT", value: Text("\(data.totalAdminDeleted)"), color: nil),
                SummaryRow(key: "SLUG-TOTAL-DEL-ACT-PROMPT", value: Text("\(data.totalAdminActiveDeleted)"), color: .green),
                SummaryRow(key: "SLUG-TOTAL-DEL-INACT-PROMPT", value: Text("\(data.totalAdminInactiveDeleted)"), color: .blue),
                SummaryRow(key: "SLUG-TOTAL-SIGNUP-PROMPT", value: Text("\(data.totalRequests)"), color: nil),
                SummaryRow(key: "SLUG-TOTAL-ACCEPTED-PROMPT", value: Text("\(data.totalApprovals)"), color: .blue),
                SummaryRow(key: "SLUG-TOTAL-REJECTION-PROMPT", value: Text("\(data.totalRejections)"), color: .orange),
                SummaryRow(key: "SLUG-TOTAL-DELETED-PROMPT", value: Text("\(data.totalAdminDeleted)"), color: nil),
                SummaryRow(key: "SLUG-AVERAGE-RATE-PROMPT", value: Text(String(format: "%.2g", data.averageSignupsPerDay)), color: nil),
                SummaryRow(key: "SLUG-AVERAGE-ACCEPTED-PROMPT", value: Text(String(format: "%.2g", data.averageAcceptedSignupsPerDay)), color: .blue),
                SummaryRow(key: "SLUG-AVERAGE-REJ-PROMPT", value: Text(String(format: "%.2g", data.averageRejectedSignupsPerDay)), color: .orange),
                SummaryRow(key: "SLUG-AVERAGE-DEL-PROMPT", value: Text(String(format: "%.2g", data.averageDeletionsPerDay)), color: nil)
            ]

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(rows) { inRow in
                        HStack {
                            Text(inRow.key.localizedVariant)
                                .foregroundColor(inRow.color ?? .primary)
                            Spacer()
                            inRow.value
                                .foregroundColor(inRow.color ?? .primary)
                        }
                        .padding(.horizontal, 16)
                    }
                }
            }
            .onChange(of: self._scenePhase, initial: true) {    // If we background, we unwind the stack.
                if .background == self._scenePhase {
                    self.path.removeLast(path.count)
                }
            }
            Spacer()
        }
    }
}
