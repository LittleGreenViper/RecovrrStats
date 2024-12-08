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
    // MARK: Private Properties
    
    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     This allows us to unwind the stack, when we go into the background.
     */
    @Environment(\.dismiss) private var _dismiss

    /* ################################################################## */
    /**
     This is the selected type of activity we are displaying. It is affected by the segmented picker.
     */
    @State private var _selectedActivityRange: Int = 1

    /* ################################################################## */
    /**
     This contains the data window, at the start of the gesture.
     */
    @State private var _firstRange: ClosedRange<Date> = Date.distantPast...Date.distantFuture
    
    /* ################################################################## */
    /**
     This is set to true, while we are in the middle of a gesture.
     */
    @State private var _isPinching: Bool = false

    /* ################################################################## */
    /**
     */
    @State private var _magnification: CGFloat = 1

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
                VStack(spacing: 8) {
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
                            .gesture(
                                MagnifyGesture()
                                    .onChanged { value in
                                        guard let minimumClipDate = data?.allRows.first?.date,
                                              let maximumClipDate = data?.allRows.last?.date
                                        else { return }
                                        
                                        if !_isPinching {
                                            _isPinching = true
                                            _firstRange = dataWindow
                                        }
                                        
                                        let minimumDate = minimumClipDate.addingTimeInterval(-43200)
                                        let maximumDate = maximumClipDate.addingTimeInterval(43200)
                                        let multiplier = CGFloat(_firstRange.upperBound.timeIntervalSinceReferenceDate - _firstRange.lowerBound.timeIntervalSinceReferenceDate) / (maximumDate.timeIntervalSinceReferenceDate - minimumDate.timeIntervalSinceReferenceDate)
                                        
                                        let range = (_firstRange.upperBound.timeIntervalSinceReferenceDate - _firstRange.lowerBound.timeIntervalSinceReferenceDate) / 2
                                        let location = TimeInterval(value.startAnchor.x)
                                        
                                        let centerDateInSeconds = (location * (range * 2)) + _firstRange.lowerBound.timeIntervalSinceReferenceDate
                                        let centerDate = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: centerDateInSeconds)).addingTimeInterval(43200)
                                        
                                        // No less than 1 day.
                                        let newRange = max(86400, range * (1 / value.magnification) * 1.2)
                                        
                                        _magnification = min(1.0, (1 / value.magnification) * multiplier)
                                        
                                        let newStartDate = Swift.min(maximumDate, Swift.max(minimumDate, centerDate.addingTimeInterval(-newRange)))
                                        let newEndDate = Swift.max(minimumDate, Swift.min(maximumDate, centerDate.addingTimeInterval(newRange)))
                                        
                                        dataWindow = newStartDate...newEndDate
                                    }
                                    .onEnded { _ in _isPinching = false }
                           )
                    }
                    
                    RCVST_ZoomControl(data: $data, dataWindow: $dataWindow, magnification: $_magnification)
                        .frame(
                            maxWidth: inGeometry.size.width * 0.9,
                            alignment: .bottom
                        )
                }
            }
            .frame(
                minWidth: inGeometry.size.width,
                maxWidth: inGeometry.size.width,
                minHeight: inGeometry.size.width,
                maxHeight: inGeometry.size.width,
                alignment: .top
            )
            .onChange(of: inGeometry.frame(in: .global)) { prepareHaptics() }
        }
        .padding([.leading, .trailing], 12)
        // This makes sure that we go back, if the app is backgrounded.
        .onChange(of: _scenePhase, initial: false) {
            if .background == _scenePhase {
                _dismiss()
            }
        }
        .onDisappear { selectedValuesString = " " }
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
    @State private var _selectedValue: RCVST_DataProvider.Row? {
        didSet {
            if nil == _selectedValue {
                selectedValuesString = " "
            }
        }
    }

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
     This returns the maximum possible Y-value, rounded up to the nearest multiple of 4.
     */
    private var _maximumYValue: Int {
        let minimumClipDate = data?.allRows.first?.date ?? Date.now
        let maximumClipDate = data?.allRows.last?.date ?? Date.now
        let minClip = minimumClipDate.addingTimeInterval(43200)
        let maxClip = maximumClipDate.addingTimeInterval(-43200)
        let clipRange = Swift.min(minClip, maxClip)...Swift.max(minClip, maxClip)
        
        let ret = _dataFiltered.reduce(0) { current, next in
            var new = current
            
            if clipRange.contains(next.date) {
                new = Swift.max(new, _getDataValue(for: next))
            }
            
            return new
        }
        
        return ((ret + 3) / 4) * 4
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
        let maximumDate = max(minimumClipDate, maximumClipDate).addingTimeInterval(43200)
        let minClip = minimumClipDate.addingTimeInterval(43200)
        let maxClip = maximumClipDate.addingTimeInterval(-43200)
        let clipRange = Swift.min(minClip, maxClip)...Swift.max(minClip, maxClip)

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
            if clipRange.contains(inRowData.date) {
                BarMark(
                    x: .value("SLUG-BAR-CHART-TYPES-X".localizedVariant, date, unit: .day),
                    y: .value("SLUG-BAR-CHART-ACTIVE-TYPES-Y".localizedVariant, active)
                )
                .cornerRadius(4)
                .foregroundStyle(by: .value("SLUG-BAR-CHART-ACTIVE-TYPES-Y-LEGEND".localizedVariant,
                                            _isLineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : "SLUG-BAR-CHART-ACTIVE-TYPES-Y-LEGEND".localizedVariant)
                )
            }
        }
        .clipped()
        .onChange(of: dataWindow) { _selectedValue = nil }
        .onAppear { _chartDomain = _chartDomain ?? minimumDate...maximumDate }
        // These define the two items in the legend, as well as the colors we'll use in the bars.
        .chartForegroundStyleScale(["SLUG-BAR-CHART-ACTIVE-TYPES-Y-LEGEND".localizedVariant: .green,
                                    "SLUG-SELECTED-LEGEND-LABEL".localizedVariant: .red
                                   ])
        // We fix the Y-axis, because we want the scale to be the same, if we zoom in.
        .chartYScale(domain: 0...Int(_maximumYValue))
        .chartYAxisLabel("SLUG-BAR-CHART-Y-AXIS-CHART-3-LABEL".localizedVariant, spacing: 12)
        // We leave the Y-axis almost default, except that we want it on the left.
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(anchor: .trailing)
            }
        }
        // We customize the X-axis, to only have a few sections.
        .chartXScale(domain: dataWindow)
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
            GeometryReader { inGeometry in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        // This allows pinch-to-zoom (horizontal axis).
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .short
                                dateFormatter.timeStyle = .none
                                if let frame = chart.plotFrame {
                                    let currentX = max(0, min(chart.plotSize.width, value.location.x - inGeometry[frame].origin.x))
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
                    .onChange(of: inGeometry.frame(in: .global)) { prepareHaptics() }
            }
        }
        // This gives the last X axis label room to display.
        .padding([.trailing], RCVST_App.sidePadding)
    }
}
