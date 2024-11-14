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
extension Array where Element == RCVST_DataProvider.RowDeletePlottableData {
    /* ################################################################## */
    /**
     This returns the sample closest to the given date.
     
     - parameter inDate: The date we want to compare against.
     
     - returns: The sample that is closest to (above or below) the given date.
     */
    func nearestTo(_ inDate: Date) -> RCVST_DataProvider.RowDeletePlottableData? {
        var ret: RCVST_DataProvider.RowDeletePlottableData?
        
        forEach {
            guard let retTemp = ret else {
                ret = $0
                return
            }
            
            ret = abs($0.date.timeIntervalSince(inDate)) < abs(retTemp.date.timeIntervalSince(inDate)) ? $0 : ret
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Main Content View for Deletion Types Chart -
/* ###################################################################################################################################### */
/**
 This displays a chart, with the different deletion types, over time.
 It is selectable, and dragging your finger across the chart, shows exact numbers.
 */
struct RCVST_Chart4View: View, RCVST_UsesData {
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
            GroupBox("SLUG-CHART-4-TITLE".localizedVariant) {
                VStack {
                    // This displays the value of the selected bar.
                    Text(selectedValuesString)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.red)
                    
                    DeleteChart(data: data, selectedValuesString: $selectedValuesString)
                        .frame(
                            minHeight: inGeometry.size.width - (UserTypesChart.sidePadding * 2), // Make it square.
                            maxHeight: .infinity,
                            alignment: .topLeading
                        )
                }
            }
            .frame(
                minWidth: inGeometry.size.width,
                maxWidth: inGeometry.size.width,
                minHeight: inGeometry.size.width, // Make it square.
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
     This is the range displayed by the chart.
     */
    @State private var _chartDomain: ClosedRange<Date>?

    /* ################################################################## */
    /**
     The value being selected by the user, while dragging.
     */
    @State private var _selectedValue: RCVST_DataProvider.RowDeletePlottableData?

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
    private var _dataFiltered: [RCVST_DataProvider.RowDeletePlottableData] { data?.deleteTypePlottable ?? [] }

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
    private func _isLineDragged(_ inRowData: RCVST_DataProvider.RowDeletePlottableData) -> Bool {
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
            ForEach(inRowData.data, id: \.deletionType) { inDeletionType in
                BarMark(
                    x: .value("SLUG-BAR-CHART-DELETION-TYPES-X".localizedVariant, inRowData.date),
                    y: .value("SLUG-BAR-CHART-DELETION-TYPES-Y".localizedVariant, inDeletionType.value)
                )
                .foregroundStyle(by: .value("SLUG-BAR-CHART-DELETION-TYPES-LEGEND".localizedVariant,
                                            _isLineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : inDeletionType.descriptionString)
                )
            }
        }
        .onAppear {
            _chartDomain = _chartDomain ?? minimumDate...maximumDate
        }
        // These define the three items in the legend, as well as the colors we'll use in the bars.
        .chartForegroundStyleScale(["SLUG-DELETED-ACTIVE-LEGEND-LABEL".localizedVariant: .green,
                                    "SLUG-DELETED-INACTIVE-LEGEND-LABEL".localizedVariant: .blue,
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
        .chartXScale(domain: _chartDomain ?? minimumDate...maximumDate)
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
