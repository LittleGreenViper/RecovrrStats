/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
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
struct RCVST_Chart1View: RCVST_DataDisplay, RCVST_UsesData {
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
     This is the layout for this screen.
     */
    var body: some View {
        GeometryReader { inGeometry in
            VStack(spacing: 8) {
                GroupBox(title) {
                    UserTypesChart(data: $data, dataWindow: $dataWindow, selectedValuesString: $selectedValuesString)
                        .frame(
                            minHeight: inGeometry.size.width,
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                    
                    ZoomControl(data: $data, dataWindow: $dataWindow)
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
}

/* ###################################################################################################################################### */
// MARK: - User Type Bar Chart -
/* ###################################################################################################################################### */
/**
 This displays a simple bar chart of the users, segeregated by the type of user.
 */
struct UserTypesChart: RCVST_DataDisplay, RCVST_UsesData, RCVST_HapticHopper {
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
     The value being selected by the user, while dragging.
     */
    @State private var _selectedValue: RCVST_DataProvider.RowUserPlottableData?

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

    // MARK: Private Functions
    
    /* ################################################################## */
    /**
     This returns whether or not the selected data bar is being dragged.
     
     - parameter inRowData: The selected bar.
     - returns: True, if the bar is being selected.
     */
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.RowUserPlottableData) -> Bool {
        _isDragging && inRowData.date == _selectedValue?.date
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
     The segregated user type data.
     */
    private var _dataFiltered: [RCVST_DataProvider.RowUserPlottableData] { data?.userTypePlottable ?? [] }

    /* ################################################################## */
    /**
     The main chart body.
     */
    var body: some View {
        let numberOfXValues = TimeInterval(4)
        // This gives us "breathing room" around the X-axis.
        let minimumClipDate = Date.distantPast < dataWindow.lowerBound ? dataWindow.lowerBound : data?.allRows.first?.date ?? Date.now
        let maximumClipDate = Date.distantFuture > dataWindow.upperBound ? dataWindow.upperBound : data?.allRows.last?.date ?? Date.now
        let minimumDate = minimumClipDate.addingTimeInterval(-43200)
        let maximumDate = maximumClipDate.addingTimeInterval(43200)
        let clipRange = minimumClipDate.addingTimeInterval(43200)...maximumClipDate.addingTimeInterval(-43200)
        
        // We use this to set a fixed number of X-axis dates.
        let step = (maximumDate - minimumDate) / numberOfXValues
        // Set up an array of dates to use as values for the X-axis.
        let dates = Array<Date>(stride(from: minimumDate, through: maximumDate, by: step))
        // Set up an array of strings to use as labels for the X-axis.
        let dateString = dates.map { $0.formatted(Date.FormatStyle().month(.abbreviated).day(.twoDigits)) }
                
        // The main chart view. It is a simple bar chart, with each bar, segregated by user type.
        Chart(_dataFiltered) { inRowData in
            ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                if clipRange.contains(inRowData.date) {
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
            if Date.distantPast == dataWindow.lowerBound,
               Date.distantFuture == dataWindow.upperBound {
                dataWindow = minimumDate...maximumDate
            }
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
        .chartXScale(domain: dataWindow)
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
