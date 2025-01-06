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
struct RCVST_UserTypesDataProvider: DataProviderProtocol {
    /* ################################################################################################################################## */
    // MARK: Specialized Row Type
    /* ################################################################################################################################## */
    /**
     This adds the plottable data to the row.
     */
    class _RCVST_UserTypesDataRow: RCVST_Row {
        /* ################################################# */
        /**
         We generate plottable data on demand.
         */
        override var plottableData: [RCVST_BasePlottableData] {
            get {
                [
                    RCVST_Row.RCVST_BasePlottableData(description: "SLUG-USER-COLUMN-NAME-active".localizedVariant,
                                                      color: isSelected ? RCVS_LegendSelectionColor : .green,
                                                      value: activeUsers, isSelected: isSelected),
                    RCVST_Row.RCVST_BasePlottableData(description: "SLUG-USER-COLUMN-NAME-new".localizedVariant,
                                                      color:  isSelected ? RCVS_LegendSelectionColor : .blue,
                                                      value: newUsers, isSelected: isSelected)
                ]
            }
            
            set { _ = newValue }
        }
    }
    
    /* ##################################################### */
    /**
     This is the displayed range of data.
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
     */
    init(with inDataFrame: DataFrame, chartName inChartName: String) {
        var rowTypes = [_RCVST_UserTypesDataRow]()
    
        // We do every other one, because we have two samples per day. We only need the last one.
        for index in stride(from: 1, to: inDataFrame.rows.count, by: 2) {
            let row = inDataFrame.rows[index]
            let previousRow = 0 < index ? inDataFrame.rows[index - 1] : nil
            rowTypes.append(_RCVST_UserTypesDataRow(dataRow: row, previousDataRow: previousRow, rowIndex: index))
        }
        
        rows = rowTypes
        chartName = inChartName
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
            if let selectedValue = selectedRow as? _RCVST_UserTypesDataRow {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none
                let ret = String(format: "SLUG-USER-TYPES-DESC-STRING-FORMAT".localizedVariant,
                                 dateFormatter.string(from: selectedValue.sampleDate),
                                 selectedValue.activeUsers,
                                 selectedValue.newUsers,
                                 selectedValue.totalUsers
                )
                return ret
            } else {
                return " "
            }
        }
        
        set { _ = newValue }
    }
}
