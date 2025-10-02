/*
 © Copyright 2024-2025, Little Green Viper Software Development LLC
 LICENSE:
 
 MIT License
 
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
 modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF
 CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
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
                                                      color: (isSelected ? RCVS_LegendSelectionColor : .green),
                                                      value: Float(activeUsers),
                                                      isSelected: isSelected),
                    RCVST_Row.RCVST_BasePlottableData(description: "SLUG-USER-COLUMN-NAME-new".localizedVariant,
                                                      color: (isSelected ? RCVS_LegendSelectionColor : .blue),
                                                      value: Float(newUsers),
                                                      isSelected: isSelected)
                ]
            }
            
            set { _ = newValue }
        }
    }
    
    /* ##################################################### */
    /**
     This is the displayed range of data, stored.
     
     The reason for this, is so we trigger redraws. The value of this is always ignored.
     */
    private var _dataWindowRange: ClosedRange<Date> = .distantPast ... .distantPast
    
    /* ##################################################### */
    /**
     This is the displayed range of data. We set the singleton from here, which is the real storage.
     */
    var dataWindowRange: ClosedRange<Date> {
        get { RCVST_DataProvider.singletonWindowRange }
        set {
            self._dataWindowRange = newValue
            RCVST_DataProvider.singletonTotalWindowRange = self.totalDateRange
            RCVST_DataProvider.singletonWindowRange = newValue
        }
    }
    
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
     The initializer.
     
     - parameter inDataFrame: The data frame, with the data processed from the CSV.
     - parameter inChartName: The name to be used to describe the chart representing this data.
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
        RCVST_DataProvider.singletonTotalWindowRange = self.totalDateRange
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
