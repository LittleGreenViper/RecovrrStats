/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Main Content View for Last Active Chart -
/* ###################################################################################################################################### */
/**
 This displays a chart, with the activity of active users (based on when they last signed in, at the time of the sample), over time.
 It is selectable, and dragging your finger across the chart, shows exact numbers.
 */
struct RCVST_Chart3View: RCVST_DataDisplay, RCVST_UsesData, RCVST_HapticHopper {
    /* ################################################################## */
    /**
     This is the selected type of activity we are displaying. It is affected by the segmented picker.
     */
    @State private var _selectedActivityRange: Int = 1

    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?

    /* ################################################################## */
    /**
     This is the title to display over the chart.
     */
    @State var title: String

    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @Binding var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     This has the data range we will be looking at.
     */
    @Binding var dataWindow: ClosedRange<Date>

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    @Binding var selectedValuesString: String

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
     This is the layout for this screen.
     */
    var body: some View {
        GeometryReader { inGeometry in
            GroupBox(title) {
                VStack {
                    // This picker allows us to view the various activity ranges.
                    Picker("Activity", selection: $_selectedActivityRange) {
                        Text("1").tag(1)
                        Text("7").tag(7)
                        Text("30").tag(30)
                        Text("90").tag(90)
                        Text("SLUG-BAR-CHART-ACTIVE-TYPES-AVERAGE".localizedVariant).tag(0)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: _selectedActivityRange) { triggerHaptic(intensity: 0.5, sharpness: 0.25) }
                    
                    UserActivityChart(data: $data, dataWindow: $dataWindow, selectedValuesString: $selectedValuesString, selectedActivityRange: $_selectedActivityRange)
                        .frame(
                            minHeight: inGeometry.size.width,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                }
            }
            .frame(
                minWidth: inGeometry.size.width,
                maxWidth: inGeometry.size.width,
                minHeight: inGeometry.size.width,
                maxHeight: inGeometry.size.width,
                alignment: .topLeading
            )
            // This makes sure the haptics are set up, every time we are activated.
            .onChange(of: _scenePhase, initial: true) {
                if .active == _scenePhase {
                    prepareHaptics()
                }
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Active User Activity Bar Chart -
/* ###################################################################################################################################### */
/**
 This displays a simple bar chart of the activity, selectable for one day (24 hours) 1 week (7 days), 30 days, or 90 days.
 You also have an "Average," which is the average of all users' last sign in from the time of the sample (in days).
 */
struct UserActivityChart: View, RCVST_UsesData, RCVST_HapticHopper {
    // MARK: Private Properties

    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     True, if the user is dragging across the chart.
     */
    @State private var _isDragging = false
    
    /* ################################################################## */
    /**
     This is the range displayed by the chart.
     */
    @State private var _chartDomain: ClosedRange<Date>?

    /* ################################################################## */
    /**
     The value being selected by the user, while dragging.
     */
    @State private var _selectedValue: RCVST_DataProvider.Row?

    // MARK: External Bindings

    /* ################################################################## */
    /**
     The general user type data.
     */
    @Binding var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     This has the data range we will be looking at.
     */
    @Binding var dataWindow: ClosedRange<Date>

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    @Binding var selectedValuesString: String

    /* ################################################################## */
    /**
     This is the selected type of activity we are displaying. It is affected by the segmented picker.
     */
    @Binding var selectedActivityRange: Int

    // MARK: Private Functions

    /* ################################################################## */
    /**
     This returns whether or not the selected data bar is being dragged.
     
     - parameter inRowData: The selected bar.
     - returns: True, if the bar is being selected.
     */
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.Row) -> Bool {
        _isDragging && nil != _selectedValue?.date && inRowData.date == _selectedValue?.date
    }

    /* ################################################################## */
    /**
     This returns a set of strings and integers, to be displayed to the user, depending on the given row.
     
     - parameter inRowData: The selected bar.
     - returns: The number of active users, depending on the segmented selection.
     */
    private func _getDataValue(for inRowData: RCVST_DataProvider.Row) -> Int {
        switch selectedActivityRange {
        case 1:
            return inRowData.activeInLast24Hours
        case 7:
            return inRowData.activeInLastWeek
        case 30:
            return inRowData.activeInLast30Days
        case 90:
            return inRowData.activeInLast90Days
        default:
            return inRowData.averageLastActiveInDays
        }
    }

    /* ################################################################## */
    /**
     This returns a set of strings and integers, to be displayed to the user, depending on the given row.
     
     - parameter inRowData: The selected bar.
     - returns: A tuple, with the relevant data to use for the string.
     */
    private func _getDataItem(for inRowData: RCVST_DataProvider.Row) -> (activePeriodString: String, activeUsersNew: Int) {
        let activePeriodString = "SLUG-BAR-CHART-ACTIVE-TYPES-VALUES-\(selectedActivityRange)".localizedVariant
        var activeUsersNew = 0
        switch selectedActivityRange {
        case 1:
            activeUsersNew = inRowData.activeInLast24Hours
        case 7:
            activeUsersNew = inRowData.activeInLastWeek
        case 30:
            activeUsersNew = inRowData.activeInLast30Days
        case 90:
            activeUsersNew = inRowData.activeInLast90Days
        default:
            activeUsersNew = inRowData.averageLastActiveInDays
        }
        
        return (activePeriodString: activePeriodString, activeUsersNew: activeUsersNew)
    }

    // MARK: RCVST_HapticHopper Conformance
    
    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?

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

    // MARK: Computed Properties
    
    /* ################################################################## */
    /**
     We provide the whole row, as data, broken into 1-day intervals.
     */
    private var _dataFiltered: [RCVST_DataProvider.Row] {
        var ret = [RCVST_DataProvider.Row]()
        
        guard let rows = data?.allRows,
              !rows.isEmpty
        else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let dailySample = rows[index]
            ret.append(dailySample)
        }
        
        return ret
    }

    /* ################################################################## */
    /**
     The main chart body.
     */
    var body: some View {
        let numberOfXValues = TimeInterval(4)
        // This gives us "breathing room" around the X-axis.
        let minimumClipDate = Date.distantPast < dataWindow.lowerBound ? dataWindow.lowerBound : _dataFiltered.first?.date ?? .now
        let maximumClipDate = Date.distantFuture > dataWindow.upperBound ? dataWindow.upperBound : _dataFiltered.last?.date ?? .now
        let minimumDate = minimumClipDate.addingTimeInterval(-43200)
        let maximumDate = maximumClipDate.addingTimeInterval(43200)

        // We use this to set a fixed number of X-axis dates.
        let step = (maximumDate - minimumDate) / numberOfXValues
        // Set up an array of dates to use as values for the X-axis.
        let dates = Array<Date>(stride(from: minimumDate, through: maximumDate, by: step))
        // Set up an array of strings to use as labels for the X-axis.
        let dateString = dates.map { $0.formatted(Date.FormatStyle().month(.abbreviated).day(.twoDigits)) }
        // The main chart view. It is a simple bar chart.
        Chart(_dataFiltered) { inRowData in
            let date = inRowData.date
            let active = _getDataValue(for: inRowData)
            if (minimumClipDate...maximumClipDate).contains(inRowData.date) {
                BarMark(
                    x: .value("SLUG-BAR-CHART-TYPES-X".localizedVariant, date, unit: .day),
                    y: .value("SLUG-BAR-CHART-ACTIVE-TYPES-Y".localizedVariant, active)
                )
                .foregroundStyle(by: .value("SLUG-BAR-CHART-ACTIVE-TYPES-Y-LEGEND".localizedVariant,
                                            _isLineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : "SLUG-BAR-CHART-ACTIVE-TYPES-Y-LEGEND".localizedVariant)
                )
            }
        }
        .onAppear { _chartDomain = _chartDomain ?? minimumDate...maximumDate }
        .chartForegroundStyleScale(["SLUG-BAR-CHART-ACTIVE-TYPES-Y-LEGEND".localizedVariant: .green,
                                    "SLUG-SELECTED-LEGEND-LABEL".localizedVariant: .red
                                   ])
        // We leave the Y-axis almost default, except that we want it on the left.
        .chartYAxisLabel("SLUG-BAR-CHART-Y-AXIS-CHART-3-LABEL".localizedVariant, spacing: 12)
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(anchor: .trailing)
            }
        }
        // We customize the X-axis, to only have a few sections.
        .chartXScale(domain: _chartDomain ?? minimumDate...maximumDate)
        .chartXAxisLabel("SLUG-BAR-CHART-X-AXIS-CHART-3-LABEL".localizedVariant, alignment: .top)
        .chartXAxis {
            AxisMarks(preset: .aligned, position: .bottom, values: dates) { inValue in
                AxisTick(length: 8)
                AxisGridLine()
                AxisValueLabel(dateString[inValue.index])
            }
        }
        // This mess is the finger tracker.
        .chartOverlay { chart in
            GeometryReader { geometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .short
                                dateFormatter.timeStyle = .none
                                if let frame = chart.plotFrame {
                                    let currentX = max(0, min(chart.plotSize.width, value.location.x - geometry[frame].origin.x))
                                    guard let date = chart.value(atX: currentX, as: Date.self) else { return }
                                    if let newValue = _dataFiltered.nearestTo(date) {
                                        let newDate = newValue.date
                                        let dateString = dateFormatter.string(from: newDate)
                                        let allUsers = newValue.activeUsers
                                        let activeUsersNew = _getDataItem(for: newValue).activeUsersNew
                                        let activePeriodString = _getDataItem(for: newValue).activePeriodString
                                        let percentage =  Int((100 * activeUsersNew) / allUsers)
                                        if 0 == selectedActivityRange {
                                            selectedValuesString = String(format: "SLUG-CHART-3-AVERAGE-DESC-STRING-FORMAT".localizedVariant,
                                                                           dateString,
                                                                           activeUsersNew
                                            )
                                        } else {
                                            selectedValuesString = String(format: "SLUG-CHART-3-TYPES-DESC-STRING-FORMAT".localizedVariant,
                                                                           dateString,
                                                                           activePeriodString,
                                                                           activeUsersNew,
                                                                           percentage
                                            )
                                        }
                                        if newDate != (_selectedValue?.date ?? newDate) {
                                            triggerHaptic()
                                        }
                                        _selectedValue = newValue
                                    }
                                    
                                    _isDragging = true
                                }
                            }
                            .onEnded { _ in
                                triggerHaptic()
                                _isDragging = false
                                _selectedValue = nil
                                selectedValuesString = " "
                            }
                    )
            }
        }
        // This gives the last X axis label room to display.
        .padding([.trailing], RCVST_App.sidePadding)
        // This makes sure the haptics are set up, every time we are activated.
        .onChange(of: _scenePhase, initial: true) {
            if .active == _scenePhase {
                prepareHaptics()
            }
        }
    }
}
