/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Array Extension For Our Data Type -
/* ###################################################################################################################################### */
//extension Array where Element == RCVST_DataProvider.RowSignupPlottableData {
//    /* ################################################################## */
//    /**
//     This returns the sample closest to the given date.
//     
//     - parameter inDate: The date we want to compare against.
//     
//     - returns: The sample that is closest to (above or below) the given date.
//     */
//    func nearestTo(_ inDate: Date) -> RCVST_DataProvider.RowSignupPlottableData? {
//        var ret: RCVST_DataProvider.RowSignupPlottableData?
//        
//        forEach {
//            guard let retTemp = ret else {
//                ret = $0
//                return
//            }
//            
//            if abs($0.date.timeIntervalSince(inDate)) < abs(retTemp.date.timeIntervalSince(inDate)) {
//                ret = $0
//            }
//        }
//        return ret
//    }
//}

/* ###################################################################################################################################### */
// MARK: - Main Content View -
/* ###################################################################################################################################### */
/**
 This displays a chart, with the different signup states, over time.
 It is selectable, and dragging your finger across the chart, shows exact numbers.
 */
struct RCVST_Chart3View: View, RCVST_UsesData {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        GeometryReader { inGeometry in
            ScrollView {
                VStack {
                    PieChart(data: data)
                }
                .padding()
                .frame(
                    minWidth: inGeometry.size.width,
                    maxWidth: inGeometry.size.width,
                    minHeight: inGeometry.size.width,
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
struct PieChart: View, RCVST_UsesData, RCVST_HapticHopper {
    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     The general user type data.
     */
    @State var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     True, if the user is dragging across the chart.
     */
    @State private var _isDragging = false

    /* ################################################################## */
    /**
     The value being selected by the user, while dragging.
     */
    @State private var _selectedValue: RCVST_DataProvider.RowSignupPlottableData?

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    @State private var _selectedValuesString: String = " "

    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?
    
    /* ################################################################## */
    /**
     The segregated user type data.
     */
    private var _dataFiltered: [RCVST_DataProvider.RowSignupPlottableData] { data?.signupTypePlottable ?? [] }

    /* ################################################################## */
    /**
     This prepares our haptic engine.
     */
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let hapticEngineTemp = try? CHHapticEngine()
        else { return }
        
        hapticEngine = hapticEngineTemp
        
        try? hapticEngine?.start()
    }

    /* ################################################################## */
    /**
     This returns whether or not the selected data bar is being dragged.
     
     - parameter inRowData: The selected bar.
     - returns: True, if the bar is being selected.
     */
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.RowSignupPlottableData) -> Bool {
        _isDragging && inRowData.date == _selectedValue?.date
    }

    /* ################################################################## */
    /**
     The main chart body.
     */
    var body: some View {
        // It is surrounded by a standard group box.
        GroupBox("SLUG-CHART-3-TITLE".localizedVariant) {
        }
    }
}
