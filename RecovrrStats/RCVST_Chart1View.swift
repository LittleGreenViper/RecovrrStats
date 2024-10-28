/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import Charts
import RVS_Generic_Swift_Toolbox

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
    var dateFormatter = DateFormatter()
    
    /* ################################################################## */
    /**
     The segregated user type data.
     */
    @State var data: [RCVST_DataProvider.RowPlottableData]
    @State private var _isDragging = false
    @State private var _selectedValue: RCVST_DataProvider.RowPlottableData?
    @State private var _selectedDateString: String = ""
    @State private var _selectedValuesString: String = ""

    /* ################################################################## */
    /**
     */
    func lineDragged(_ inRowData: RCVST_DataProvider.RowPlottableData) -> Bool {
        _isDragging && inRowData.date == _selectedValue?.date
    }
    
    /* ################################################################## */
    /**
     */
    var body: some View {
        GroupBox("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) {
            Text(_selectedDateString)
            Text(_selectedValuesString)
            Chart(data) { inRowData in
                ForEach(inRowData.data, id: \.userType) { inUserTypeData in
                    BarMark(
                        x: .value("SLUG-BAR-CHART-USER-TYPES-X".localizedVariant, inRowData.date),
                        y: .value("SLUG-BAR-CHART-USER-TYPES-Y".localizedVariant, inUserTypeData.value)
                    )
                    .foregroundStyle(by: .value("SLUG-BAR-CHART-USER-TYPES-LEGEND".localizedVariant, lineDragged(inRowData) ? "SLUG-SELECTED-LEGEND-LABEL".localizedVariant : inUserTypeData.displayColor))
                }
            }
            .chartForegroundStyleScale(["SLUG-ACTIVE-LEGEND-LABEL".localizedVariant: .green, "SLUG-NEW-LEGEND-LABEL".localizedVariant: .yellow, "SLUG-SELECTED-LEGEND-LABEL".localizedVariant: .red])
            .chartYAxisLabel("SLUG-BAR-CHART-Y-AXIS-LABEL".localizedVariant, spacing: 12)
            .chartYAxis {
                AxisMarks(preset: .aligned, position: .leading) { _ in
                    AxisGridLine()
                    AxisValueLabel(anchor: .trailing, horizontalSpacing: 8)
                }
            }
            .chartXAxisLabel("SLUG-BAR-CHART-X-AXIS-LABEL".localizedVariant, alignment: .bottom)
            .chartXAxis {
                AxisMarks(preset: .aligned, position: .bottom) { _ in
                    AxisGridLine()
                    AxisValueLabel()
                }
            }
            .chartOverlay { chart in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    dateFormatter.dateStyle = .medium
                                    dateFormatter.timeStyle = .none
                                    if let frame = chart.plotFrame {
                                        let currentX = max(0, min(chart.plotSize.width, value.location.x - geometry[frame].origin.x))
                                        guard let date = chart.value(atX: currentX, as: Date.self) else { return }
                                        if let newValue = data.nearestTo(date) {
                                            _selectedDateString = dateFormatter.string(from: newValue.date)
                                            _selectedValuesString = String(format: "SLUG-USER-TYPES-DESC-STRING-FORMAT".localizedVariant, newValue.data[0].value, newValue.data[1].value)
                                            _selectedValue = newValue
                                        }
                                        
                                        _isDragging = true
                                    }
                                }
                                .onEnded { _ in
                                    _isDragging = false
                                    _selectedValue = nil
                                    _selectedDateString = ""
                                    _selectedValuesString = ""
                                }
                        )
                }
            }
        }
        .padding()
    }
}
