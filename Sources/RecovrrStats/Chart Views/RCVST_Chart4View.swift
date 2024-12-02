/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import Charts
import RVS_Generic_Swift_Toolbox
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Main Content View for Deletion Types Chart -
/* ###################################################################################################################################### */
/**
 This displays a chart, with the different deletion types, over time.
 It is selectable, and dragging your finger across the chart, shows exact numbers.
 */
struct RCVST_Chart4View: RCVST_DataDisplay, RCVST_UsesData {
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
            GroupBox(title) {
                VStack(spacing: 8) {
                    DeleteChart(data: $data, dataWindow: $dataWindow, selectedValuesString: $selectedValuesString)
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
                                    
                                    let centerDateInSeconds = (location * (range * 2)) + minimumDate.timeIntervalSinceReferenceDate
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
                alignment: .topLeading
            )
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - User Type Bar Chart -
/* ###################################################################################################################################### */
/**
 This displays a simple bar chart of the deletion activities.
 */
struct DeleteChart: View, RCVST_UsesData, RCVST_HapticHopper {
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
    @State private var _selectedValue: RCVST_DataProvider.RowDeletePlottableData? {
        didSet {
            if nil == _selectedValue {
                selectedValuesString = " "
            }
        }
    }

    /* ################################################################## */
    /**
     This is the range displayed by the chart.
     */
    @State private var _chartDomain: ClosedRange<Date>?

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
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.RowDeletePlottableData) -> Bool {
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
    private var _dataFiltered: [RCVST_DataProvider.RowDeletePlottableData] { data?.deleteTypePlottable ?? [] }

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
        
        // The main chart view. It is a simple bar chart, with each bar, segregated by user type.
        Chart(_dataFiltered) { inRowData in
            if clipRange.contains(inRowData.date) {
                ForEach(inRowData.data, id: \.deletionType) { inDeletionType in
                    BarMark(
                        x: .value("SLUG-BAR-CHART-DELETION-TYPES-X".localizedVariant, inRowData.date, unit: .day),
                        y: .value("SLUG-BAR-CHART-DELETION-TYPES-Y".localizedVariant, inDeletionType.value)
                    )
                    .foregroundStyle(by: .value("SLUG-BAR-CHART-DELETION-TYPES-LEGEND".localizedVariant,
                                                _isLineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : inDeletionType.descriptionString)
                    )
                }
            }
        }
        .onChange(of: dataWindow) { _selectedValue = nil }
        .onAppear { _chartDomain = _chartDomain ?? minimumDate...maximumDate }
        // These define the three items in the legend, as well as the colors we'll use in the bars.
        .chartForegroundStyleScale(["SLUG-DELETED-ACTIVE-LEGEND-LABEL".localizedVariant: .green,
                                    "SLUG-DELETED-INACTIVE-LEGEND-LABEL".localizedVariant: .blue,
                                    "SLUG-DELETED-SELF-LEGEND-LABEL".localizedVariant: .yellow,
                                    "SLUG-SELECTED-LEGEND-LABEL".localizedVariant: .red
                                   ])
        // We leave the Y-axis almost default, except that we want it on the left.
        .chartYAxisLabel("SLUG-BAR-CHART-X-AXIS-DELETION-LABEL".localizedVariant, spacing: 12)
        .chartYAxis {
            AxisMarks(preset: .aligned, position: .leading) { _ in
                AxisTick()
                AxisGridLine()
                AxisValueLabel(anchor: .trailing)
            }
        }
        // We customize the X-axis, to only have a few sections.
        .chartXScale(domain: dataWindow)
        .chartXAxisLabel("SLUG-BAR-CHART-Y-AXIS-DELETION-LABEL".localizedVariant, alignment: .top)
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
                                        selectedValuesString = String(format: "SLUG-DELETED-TYPES-DESC-STRING-FORMAT".localizedVariant,
                                                                      dateFormatter.string(from: newValue.date),
                                                                      newValue.data[0].value,
                                                                      newValue.data[1].value,
                                                                      newValue.data[2].value,
                                                                      newValue.data[0].value + newValue.data[1].value + newValue.data[2].value
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
