/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics

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
                    UserActivityChart(data: data)
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
// MARK: - Signup Activity Bar Chart -
/* ###################################################################################################################################### */
/**
 This displays a simple bar chart of the signups, segeregated by whether the signup was approved or rejected.
 */
struct UserActivityChart: View, RCVST_UsesData, RCVST_HapticHopper {
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
    private var _dataFiltered: [RCVST_DataProvider.Row] { data?.allRows ?? [] }

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
        let numberOfXValues = TimeInterval(4)
        // This gives us "breathing room" around the X-axis.
        let minimumDate = _dataFiltered.first?.sampleDate?.addingTimeInterval(-43200) ?? .now
        let maximumDate = _dataFiltered.last?.sampleDate?.addingTimeInterval(43200) ?? .now
        // We use this to set a fixed number of X-axis dates.
        let step = (maximumDate - minimumDate) / numberOfXValues
        // Set up an array of dates to use as values for the X-axis.
        let dates = Array<Date>(stride(from: minimumDate, through: maximumDate, by: step))
        // Set up an array of strings to use as labels for the X-axis.
        let dateString = dates.map { $0.formatted(Date.FormatStyle().month(.abbreviated).day(.twoDigits)) }
        // It is surrounded by a standard group box.
        GroupBox("SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant) {
            Text(dateString.description)
        }
        // This is so the user has room to scroll, if the chart is off the screen.
        .padding([.leading, .trailing], 20)
        // This makes sure the haptics are set up, every time we are activated.
        .onChange(of: _scenePhase, initial: true) {
            if .active == _scenePhase {
                prepareHaptics()
            }
        }
    }
}
