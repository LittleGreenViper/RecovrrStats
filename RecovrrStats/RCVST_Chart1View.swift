/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Main Content View for User Types Chart -
/* ###################################################################################################################################### */
/**
 This displays a chart, with the different user types, over time.
 It is selectable, and dragging your finger across the chart, shows exact numbers.
 */
struct RCVST_Chart1View: View, RCVST_UsesData {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    @State var selectedValuesString: String = " "
    
    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        GeometryReader { inGeometry in
            GroupBox("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) {
                VStack {
                    // This displays the value of the selected bar.
                    Text(selectedValuesString)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    UserTypesChart(data: data, selectedValuesString: $selectedValuesString)
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
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - User Type Bar Chart -
/* ###################################################################################################################################### */
/**
 This displays a simple bar chart of the users, segeregated by the type of user.
 */
struct UserTypesChart: View, RCVST_UsesData, RCVST_HapticHopper {
    /* ################################################################## */
    /**
     Padding for the right side.
     */
    static let sidePadding = CGFloat(20)
    
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
     */
    @State private var _startingPoint: (minimumSeconds: Double, maximumSeconds: Double)?

    /* ################################################################## */
    /**
     This is the range displayed by the chart.
     */
    @State private var _chartDomain: ClosedRange<Date>?

    /* ################################################################## */
    /**
     The value being selected by the user, while dragging.
     */
    @State private var _selectedValue: RCVST_DataProvider.RowUserPlottableData?

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    @Binding var selectedValuesString: String
    
    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?

    /* ################################################################## */
    /**
     The segregated user type data.
     */
    private var _dataFiltered: [RCVST_DataProvider.RowUserPlottableData] { data?.userTypePlottable ?? [] }

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
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.RowUserPlottableData) -> Bool {
        _isDragging && inRowData.date == _selectedValue?.date
    }

    /* ################################################################## */
    /**
     The main chart body.
     */
    var body: some View {
        let numberOfXValues = TimeInterval(4)
        // This gives us "breathing room" around the X-axis.
        let minimumDate = _dataFiltered.first?.date.addingTimeInterval(-43200) ?? .now
        let maximumDate = _dataFiltered.last?.date.addingTimeInterval(43200) ?? .now

        // We use this to set a fixed number of X-axis dates.
        let step = (maximumDate - minimumDate) / numberOfXValues
        // Set up an array of dates to use as values for the X-axis.
        let dates = Array<Date>(stride(from: minimumDate, through: maximumDate, by: step))
        // Set up an array of strings to use as labels for the X-axis.
        let dateString = dates.map { $0.formatted(Date.FormatStyle().month(.abbreviated).day(.twoDigits)) }
                
        // The main chart view. It is a simple bar chart, with each bar, segregated by user type.
        Chart(_dataFiltered) { inRowData in
            ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                if _chartDomain?.contains(inRowData.date) ?? false {
                    BarMark(
                        x: .value("SLUG-BAR-CHART-USER-TYPES-X".localizedVariant, inRowData.date, unit: .day),
                        y: .value("SLUG-BAR-CHART-USER-TYPES-Y".localizedVariant, inUserTypeData.value)
                    )
                    .foregroundStyle(by: .value("SLUG-BAR-CHART-USER-TYPES-LEGEND".localizedVariant,
                                                _isLineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : inUserTypeData.descriptionString)
                    )
                }
            }
        }
        .onAppear {
            _chartDomain = _chartDomain ?? minimumDate...maximumDate
        }
        // These define the three items in the legend, as well as the colors we'll use in the bars.
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
        .chartXScale(domain: _chartDomain ?? minimumDate...maximumDate)
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
            GeometryReader { inGeom in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    // This allows pinch-to-zoom (horizonatl axis).
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                let dateFormatter = DateFormatter()
                                dateFormatter.dateStyle = .short
                                dateFormatter.timeStyle = .none
                                if let frame = chart.plotFrame {
                                    let currentX = max(0, min(chart.plotSize.width, value.location.x - inGeom[frame].origin.x))
                                    guard let date = chart.value(atX: currentX, as: Date.self) else { return }
                                    if let newValue = _dataFiltered.nearestTo(date) {
                                        selectedValuesString = String(format: "SLUG-USER-TYPES-DESC-STRING-FORMAT".localizedVariant,
                                                                       dateFormatter.string(from: newValue.date),
                                                                       newValue.data[0].value,
                                                                       newValue.data[1].value,
                                                                       newValue.data[0].value + newValue.data[1].value
                                        )
                                        if newValue.date != _selectedValue?.date {
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
        // This is so the user has room to scroll, if the chart is off the screen.
        .padding([.leading, .trailing], Self.sidePadding)
        // This makes sure the haptics are set up, every time we are activated.
        .onChange(of: _scenePhase, initial: true) {
            if .active == _scenePhase {
                prepareHaptics()
            }
        }
    }
}
