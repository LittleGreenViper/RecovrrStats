/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics
import Combine

/* ###################################################################################################################################### */
// MARK: - Add A Formatted Date Output -
/* ###################################################################################################################################### */
extension RCVST_DataProvider.Row {
    /* ################################################################## */
    /**
     */
    var formattedDate: String {
        guard let sampleDate = sampleDate else { return "" }
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: sampleDate)
    }
}

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
     This displays the currently selected date.
     */
    @State private var _currentDateString = " "

    /* ################################################################## */
    /**
     This holds the slider value, internally.
     */
    @State private var _sliderValue: Double = 0

    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?
    
    /* ################################################################## */
    /**
     The segregated user type data.
     */
    private var _dataFiltered: [RCVST_DataProvider.Row] {
        guard let allRows = data?.allRows else { return [] }
        var ret = [RCVST_DataProvider.Row]()
        
        for row in stride(from: 0, to: allRows.count - 1, by: 2) {
            ret.append(allRows[row])
        }
        
        return ret
    }

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
     The main chart body.
     */
    var body: some View {
        let sliderValue = Binding<Double>(
            get: { _sliderValue },
            set: {
                _currentDateString = _dataFiltered[Int($0)].formattedDate
                _sliderValue = $0
                triggerHaptic()
            }
        )

        // It is surrounded by a standard group box.
        GroupBox("SLUG-CHART-3-TITLE".localizedVariant) {
            Slider(value: sliderValue,
                   in: 0...Double(_dataFiltered.count - 1),
                   step: 1,
                   onEditingChanged: { inWasChanged in _isDragging = inWasChanged }
            )
            Text(_currentDateString)
        }
        .onAppear {
            prepareHaptics()
            _sliderValue = Double(_dataFiltered.count - 1)
            _currentDateString = _dataFiltered[Int(_sliderValue)].formattedDate
        }
    }
}
