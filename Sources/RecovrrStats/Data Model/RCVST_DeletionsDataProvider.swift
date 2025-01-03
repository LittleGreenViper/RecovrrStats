/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Account Deletions Specialized Stats Data Provider -
/* ###################################################################################################################################### */
/**
 This implementation specializes for the account deletion activity user display.
 */
struct RCVST_DeletionsDataProvider: DataProviderProtocol {
    /* ################################################################################################################################## */
    // MARK: Specialized Row Type
    /* ################################################################################################################################## */
    /**
     This adds the plottable data to the row.
     */
    class _RCVST_SignupsDataRow: RCVST_Row {
        /* ################################################# */
        /**
         This has an instance of the previous row, as we aggregate two at a time.
         */
        var previousRowInstance: _RCVST_SignupsDataRow?
        
        /* ################################################# */
        /**
         We generate plottable data on demand.
         */
        override var plottableData: [RCVST_BasePlottableData] {
            get {
                let signupsAccepted = newAcceptedRequests + (previousRowInstance?.newAcceptedRequests ?? 0)
                let signupsRejected = newRejectedRequests + (previousRowInstance?.newRejectedRequests ?? 0)
                return [
                    RCVST_Row.RCVST_BasePlottableData(description: "SLUG-SIGNUP-COLUMN-NAME-acceptedSignups".localizedVariant,
                                                      color: isSelected ? RCVS_LegendSelectionColor : .green,
                                                      value: signupsAccepted, isSelected: isSelected),
                    RCVST_Row.RCVST_BasePlottableData(description: "SLUG-SIGNUP-COLUMN-NAME-rejectedSignups".localizedVariant,
                                                      color:  isSelected ? RCVS_LegendSelectionColor : .orange,
                                                      value: signupsRejected, isSelected: isSelected)
                ]
            }
            
            set { _ = newValue }
        }

        /* ################################################# */
        /**
         initializer
         
         - parameter dataRow: The `DataFrame.Row` for the line we're saving.
         - parameter previousDataRow: The `DataFrame.Row` for the line prior to the one we're saving (may be nil, for the first row).
         - parameter rowIndex: The 0-based index (in the dataframe rows) of this row (it will also be the index of this row).
         - parameter previousRowInstance: The resolved instance of the row prior to this one (may be nil, for row 0).
         */
        public init(dataRow inDataRow: DataFrame.Row, previousDataRow inPreviousDataRow: DataFrame.Row?, rowIndex inIndex: Int, previousRowInstance inPreviousRowInstance: _RCVST_SignupsDataRow?) {
            super.init(dataRow: inDataRow, previousDataRow: inPreviousDataRow, rowIndex: inIndex)
            previousRowInstance = inPreviousRowInstance
        }
    }
    
    /* ##################################################### */
    /**
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
        var rowTypes = [_RCVST_SignupsDataRow]()
    
        // We do every other one, because we have two samples per day. We will be adding them together.
        for index in stride(from: 1, to: inDataFrame.rows.count, by: 2) {
            let row = inDataFrame.rows[index]
            let previousRow = 0 < index ? inDataFrame.rows[index - 1] : nil
            let previousRowInstance = nil != previousRow ? _RCVST_SignupsDataRow(dataRow: previousRow!, previousDataRow: rowTypes.last?.dataRow, rowIndex: index, previousRowInstance: rowTypes.last) : nil
            rowTypes.append(_RCVST_SignupsDataRow(dataRow: row, previousDataRow: previousRow, rowIndex: index, previousRowInstance: previousRowInstance))
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
            if let selectedValue = selectedRow as? _RCVST_SignupsDataRow {
                let dateFormatter = DateFormatter()
                dateFormatter.dateStyle = .short
                dateFormatter.timeStyle = .none
                let signupsAccepted = selectedValue.newAcceptedRequests + (selectedValue.previousRowInstance?.newAcceptedRequests ?? 0)
                let signupsRejected = selectedValue.newRejectedRequests + (selectedValue.previousRowInstance?.newRejectedRequests ?? 0)
                let ret = String(format: "SLUG-SIGNUP-TYPES-DESC-STRING-FORMAT".localizedVariant,
                                 dateFormatter.string(from: selectedValue.sampleDate),
                                 signupsAccepted,
                                 signupsRejected,
                                 signupsAccepted + signupsRejected
                )
                return ret
            } else {
                return " "
            }
        }
        
        set { _ = newValue }
    }
}
