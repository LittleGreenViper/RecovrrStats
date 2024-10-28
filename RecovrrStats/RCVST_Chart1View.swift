/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Special Date Extension For Subtracting Dates -
/* ###################################################################################################################################### */
extension Date {
    /* ################################################################## */
    /**
     A simple minus operator for dates.
     
     - paremeter lhs: The left-hand side of the subtration
     - parameter rhs: The right-hand side of the subtraction.
     - returns: A TimeInterval, with the number of seconds between the dates. If rhs > lhs, it is negative.
     */
    static func - (lhs: Date, rhs: Date) -> TimeInterval { lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate }
}

/* ###################################################################################################################################### */
// MARK: - Array Extension For Our Data Type -
/* ###################################################################################################################################### */
extension Array where Element == RCVST_DataProvider.RowPlottableData {
    /* ################################################################## */
    /**
     This returns the sample closest to the given date.
     
     - parameter inDate: The date we want to compare against.
     
     - returns: The sample that is closest to (above or below) the given date.
     */
    func nearestTo(_ inDate: Date) -> RCVST_DataProvider.RowPlottableData? {
        var ret: RCVST_DataProvider.RowPlottableData?
        
        forEach {
            guard let retTemp = ret else {
                ret = $0
                return
            }
            if abs($0.date.timeIntervalSince(inDate)) < abs(retTemp.date.timeIntervalSince(inDate)) {
                ret = $0
            }
        }
        return ret
    }
}
/* ###################################################################################################################################### */
// MARK: - Main Content View -
/* ###################################################################################################################################### */
/**
 This displays a chart, with the different user types, over time.
 It is selectable, and dragging your finger across the chart, shows exact numbers.
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
struct UserTypesChart: View {
    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State private var _hapticEngine: CHHapticEngine?
    
    /* ################################################################## */
    /**
     The segregated user type data.
     */
    @State var data: [RCVST_DataProvider.RowPlottableData]

    /* ################################################################## */
    /**
     True, if the user is dragging across the chart.
     */
    @State private var _isDragging = false

    /* ################################################################## */
    /**
     The value being selected by the user, while dragging.
     */
    @State private var _selectedValue: RCVST_DataProvider.RowPlottableData?

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    @State private var _selectedValuesString: String = " "

    /* ################################################################## */
    /**
     This returns whether or not the selected data bar is being dragged.
     
     - parameter inRowData: The selected bar.
     - returns: True, if the bar is being selected.
     */
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.RowPlottableData) -> Bool {
        _isDragging && inRowData.date == _selectedValue?.date
    }
    
    /* ################################################################## */
    /**
     This prepares our haptic engine.
     */
    private func _prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let hapticEngine = try? CHHapticEngine()
        else { return }
        
        _hapticEngine = hapticEngine
        
        try? hapticEngine.start()
    }

    /* ################################################################## */
    /**
     This triggers the haptic. We don't lose sleep, if it fails.
     */
    private func _triggerHaptic() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.25)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity], relativeTime: 0)
        events.append(event)

        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? _hapticEngine?.makePlayer(with: pattern)
        else { return }
        
        try? player.start(atTime: 0)
    }
    
    /* ################################################################## */
    /**
     The main chart body.
     */
    var body: some View {
        let numberOfXValues = TimeInterval(4)
        // This gives us "breathing room" around the X-axis.
        let minimumDate = data.first?.date.addingTimeInterval(-43200) ?? .now
        let maximumDate = data.last?.date.addingTimeInterval(43200) ?? .now
        // We use this to set a fixed number of X-axis dates.
        let step = (maximumDate - minimumDate) / numberOfXValues
        // Set up an array of dates to use as values for the X-axis.
        let dates = Array<Date>(stride(from: minimumDate, through: maximumDate, by: step))
        // Set up an array of strings to use as labels for the X-axis.
        let dateString = dates.map { $0.formatted(Date.FormatStyle().month(.abbreviated).day(.twoDigits)) }
        
        // It is surrounded by a standard group box.
        GroupBox("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) {
            // This displays the value of the selected bar.
            Text(_selectedValuesString)
                .minimumScaleFactor(0.5)
                .font(.subheadline)
                .foregroundStyle(.red)
            // The main chart view. It is a simple bar chart, with each bar, segregated by user type.
            Chart(data) { inRowData in
                ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                    BarMark(
                        x: .value("SLUG-BAR-CHART-USER-TYPES-X".localizedVariant, inRowData.date),
                        y: .value("SLUG-BAR-CHART-USER-TYPES-Y".localizedVariant, inUserTypeData.value)
                    )
                    .foregroundStyle(by: .value("SLUG-BAR-CHART-USER-TYPES-LEGEND".localizedVariant,
                                                _isLineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : inUserTypeData.displayColor)
                    )
                }
            }
            // Thes define the three items in the legend, as well as the colors we'll use in the bars.
            .chartForegroundStyleScale(["SLUG-ACTIVE-LEGEND-LABEL".localizedVariant: .green,
                                        "SLUG-NEW-LEGEND-LABEL".localizedVariant: .blue,
                                        "SLUG-SELECTED-LEGEND-LABEL".localizedVariant: .red
                                       ])
            // We leave the Y-axis almost default, except that we want it on the left.
            .chartYAxisLabel("SLUG-BAR-CHART-Y-AXIS-LABEL".localizedVariant, spacing: 12)
            .chartYAxis {
                AxisMarks(preset: .aligned, position: .leading) { _ in
                    AxisTick()
                    AxisGridLine()
                    AxisValueLabel(anchor: .trailing)
                }
            }
            // We customize the X-axis, to only have a few sections.
            .chartXScale(domain: [minimumDate, maximumDate])
            .chartXAxisLabel("SLUG-BAR-CHART-X-AXIS-LABEL".localizedVariant, alignment: .top)
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
                                        if let newValue = data.nearestTo(date) {
                                            _selectedValuesString = String(format: "SLUG-USER-TYPES-DESC-STRING-FORMAT".localizedVariant,
                                                                           dateFormatter.string(from: newValue.date),
                                                                           newValue.data[0].value,
                                                                           newValue.data[1].value,
                                                                           newValue.data[0].value + newValue.data[1].value
                                            )
                                            if newValue.date != _selectedValue?.date {
                                                _triggerHaptic()
                                            }
                                            _selectedValue = newValue
                                        }
                                        
                                        _isDragging = true
                                    }
                                }
                                .onEnded { _ in
                                    _triggerHaptic()
                                    _isDragging = false
                                    _selectedValue = nil
                                    _selectedValuesString = " "
                                }
                        )
                }
            }
            .padding([.trailing], 20)
            .padding([.leading, .top, .bottom], 8)
        }
        .onAppear { _prepareHaptics() }
    }
}
