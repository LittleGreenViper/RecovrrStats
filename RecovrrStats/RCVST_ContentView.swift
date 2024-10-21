/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData

/* ###################################################################################################################################### */
// MARK: - Main Content View -
/* ###################################################################################################################################### */
/**
 */
struct RCVST_ContentView: View {
    /* ################################################################## */
    /**
     */
    @ObservedObject var data = RCVST_DataProvider()

    /* ################################################################## */
    /**
     */
    var body: some View {
        GeometryReader { inGeometry in
            ScrollView {
                VStack {
                        Text(self.data.debugDescription)
                        .lineLimit(nil)
                }
                .padding()
                .frame(
                    minWidth: inGeometry.size.width,
                    maxWidth: inGeometry.size.width,
                    minHeight: inGeometry.size.height,
                    maxHeight: .infinity,
                    alignment: .topLeading
                )
            }
        }
    }
}
