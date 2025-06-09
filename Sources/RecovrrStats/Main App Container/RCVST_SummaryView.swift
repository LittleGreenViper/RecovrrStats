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
     The data we'll be mining.
     */
    @State var data: RCVST_DataProvider?
    
    /* ##################################################### */
    /**
     */
    var body: some View {
        Text("SLUG-SUMMARY-HEADER".localizedVariant)
            .bold()
        List {
            HStack {
                Text("SLUG-TOTAL-SIGNUP-PROMPT".localizedVariant)
                Spacer()
                Text("\(self.data?.totalRequests ?? 0)")
            }
            HStack {
                Text("SLUG-AVERAGE-RATE-PROMPT".localizedVariant)
                Spacer()
                let displ = String(format: "%.2g", self.data?.averageSignupsPerDay ?? 0)
                Text(displ)
            }
            HStack {
                Text("SLUG-TOTAL-REJECTION-PROMPT".localizedVariant)
                Spacer()
                Text("\(self.data?.totalRejections ?? 0)")
            }
            HStack {
                Text("SLUG-AVERAGE-REJ-PROMPT".localizedVariant)
                Spacer()
                let displ = String(format: "%.2g", self.data?.averageRejectedSignupsPerDay ?? 0)
                Text(displ)
            }
            HStack {
                Text("SLUG-TOTAL-DELETED-PROMPT".localizedVariant)
                Spacer()
                Text("\(self.data?.totalAdminDeleted ?? 0)")
            }
            HStack {
                Text("SLUG-AVERAGE-DEL-PROMPT".localizedVariant)
                Spacer()
                let displ = String(format: "%.2g", self.data?.averageDeletionsPerDay ?? 0)
                Text(displ)
            }
            HStack {
                Text("SLUG-TOTAL-DEL-ACT-PROMPT".localizedVariant)
                Spacer()
                Text("\(self.data?.totalAdminActiveDeleted ?? 0)")
            }
            HStack {
                Text("SLUG-TOTAL-DEL-INACT-PROMPT".localizedVariant)
                Spacer()
                Text("\(self.data?.totalAdminInactiveDeleted ?? 0)")
            }
        }
        Spacer()
    }
}
