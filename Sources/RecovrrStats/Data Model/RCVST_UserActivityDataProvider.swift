/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - User Type Specialized Stats Data Provider -
/* ###################################################################################################################################### */
/**
 This implementation specializes for the "active/new" user display.
 */
struct RCVST_UserActivityDataProvider: DataProviderProtocol {
    /* ################################################################################################################################## */
    // MARK: Specialized Row Type
    /* ################################################################################################################################## */
    /**
     This adds the plottable data to the row.
     */
    class _RCVST_UserActivityDataRow: RCVST_Row {
        /* ################################################# */
        /**
         We generate plottable data on demand.
         */
        override var plottableData: [RCVST_BasePlottableData] {
            get {
                var activity: Float = 0
                switch days {
                case 0..<2:
                    activity = Float(activeInLast24Hours)
                case 2..<8:
                    activity = Float(activeInLastWeek)
                case 8..<89:
                    activity = Float(activeInLast30Days)
                default:
                    activity = Float(activeInLast90Days)
                }
                
                activity = Float(Int(activity * 100)) / Float(activeUsers)
                
                return [
                    RCVST_Row.RCVST_BasePlottableData(description: "SLUG-USER-COLUMN-NAME-active".localizedVariant,
                                                      color: isSelected ? RCVS_LegendSelectionColor : .green,
                                                      value: activity, isSelected: isSelected)
                ]
            }
            
            set { _ = newValue }
        }
        
        /* ##################################################### */
        /**
         The number of days in the range we are examining.
         It must be 1, 7, 30 or 90.
         */
        var days: Int = 1

        /* ################################################# */
        /**
         initializer
         
         - parameter dataRow: The `DataFrame.Row` for the line we're saving.
         - parameter previousDataRow: The `DataFrame.Row` for the line prior to the one we're saving (may be nil, for the first row).
         - parameter rowIndex: The 0-based index (in the dataframe rows) of this row (it will also be the index of this row).
         */
        public init(dataRow inDataRow: DataFrame.Row, previousDataRow inPreviousDataRow: DataFrame.Row?, rowIndex inIndex: Int, days inDays: Int = 1) {
            super.init(dataRow: inDataRow, previousDataRow: inPreviousDataRow, rowIndex: inIndex)
            days = inDays
        }
    }
    
    /* ##################################################### */
    /**
     The actual range of the currently displayed rows.
     */
    var dataWindowRange: ClosedRange<Date> = .distantPast ... .distantPast
    
    /* ##################################################### */
    /**
     This contains the rows assigned to this instance.
     */
    var rows: [any RCVST_RowProtocol] = []
    
    /* ##################################################### */
    /**
     The name to be used to describe the chart.
     */
    var chartName: String = ""

    /* ##################################################### */
    /**
     (Computed Property) The string to use for the Y-axis.
     */
    var yAxisLabel: String { "SLUG-BAR-CHART-Y-AXIS-PERCENTAGE-LABEL".localizedVariant }

    /* ##################################################### */
    /**
     The number of days in the range we are examining.
     It must be 1, 7, 30 or 90.
     */
    var days: Int = 1

    /* ##################################################### */
    /**
     The initializer.
     
     - parameter with: The data frame, with the data processed from the CSV.
     - parameter chartName: The name to be used to describe the chart representing this data.
     */
    init(with inDataFrame: DataFrame, days inDays: Int = 1) {
        var rowTypes = [_RCVST_UserActivityDataRow]()
    
        // We do every other one, because we have two samples per day. We only need the last one.
        for index in stride(from: 1, to: inDataFrame.rows.count, by: 2) {
            let row = inDataFrame.rows[index]
            let previousRow = 0 < index ? inDataFrame.rows[index - 1] : nil
            let value = _RCVST_UserActivityDataRow(dataRow: row, previousDataRow: previousRow, rowIndex: index, days: inDays)
            rowTypes.append(value)
        }
        
        days = inDays
        rows = rowTypes
        chartName = 1 < inDays ? String(format: "SLUG-BAR-CHART-ACTIVE-TITLE-FORMAT".localizedVariant, inDays) : "SLUG-BAR-CHART-ACTIVE-TITLE-SHORT".localizedVariant
        if let lowerBound = rowTypes.first?.sampleDate,
           let upperBound = rowTypes.last?.sampleDate {
            dataWindowRange = Calendar.current.startOfDay(for: lowerBound) ... Calendar.current.startOfDay(for: upperBound)
        }
    }
    
    /* ##################################################### */
    /**
     This is a string that is to be displayed, to describe the selected row.
     */
    var selectionString: String {
        get {
            if let selectedValue = selectedRow as? _RCVST_UserActivityDataRow {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none
                var activity: Float = 0
                var string: String = ""
                let day = Float(selectedValue.activeInLast24Hours)
                let week = Float(selectedValue.activeInLastWeek) - day
                let month = Float(selectedValue.activeInLast30Days) - (week + day)
                let quarter = Float(selectedValue.activeInLast90Days) - (week + day + month)
                
                switch days {
                case 0..<2:
                    activity = day
                    string = "SLUG-BAR-CHART-ACTIVE-TYPES-VALUES-1".localizedVariant
                case 2..<8:
                    activity = week
                    string = "SLUG-BAR-CHART-ACTIVE-TYPES-VALUES-7".localizedVariant
                case 8..<89:
                    activity = month
                    string = "SLUG-BAR-CHART-ACTIVE-TYPES-VALUES-30".localizedVariant
                default:
                    activity = quarter
                    string = "SLUG-BAR-CHART-ACTIVE-TYPES-VALUES-90".localizedVariant
                }
                let percentage = Float(Int(activity * 100)) / Float(selectedValue.activeUsers)
                return String(format: "SLUG-BAR-CHART-ACTIVE-DESC-STRING-FORMAT".localizedVariant, dateFormatter.string(from: selectedValue.sampleDate), string, Int(activity), percentage)
            } else {
                return " "
            }
        }
        
        set { _ = newValue }
    }
}
