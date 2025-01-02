/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

/* ############################################# */
/**
 This is the color to use, when a row is selected.
 */
public let RCVS_LegendSelectionColor = Color.red

/* ############################################# */
// MARK: - Legend Element Data Class -
/* ############################################# */
/**
 This is used to generate the legend.
 */
fileprivate class _RCVS_LegendElement: Identifiable {
    /* ############################################# */
    /**
     Make me identifiable.
     */
    let id = UUID()

    /* ############################################# */
    /**
     The name should be hashable.
     */
    let name: String

    /* ############################################# */
    /**
     We can change the color of a named item
     */
    var color: Color

    /* ############################################# */
    /**
     Default initializer. If you don't specify any arguments, the selection item is created.
     
     - parameter name: The name of the legend item.
     - parameter color: The color to associate with the name.
     */
    init(name inName: String = "SLUG-SELECTED-LEGEND-LABEL".localizedVariant, color inColor: Color = RCVS_LegendSelectionColor) {
        name = inName
        color = inColor
    }
}

/* ############################################# */
// MARK: - Data Source Protocol -
/* ############################################# */
/**
 This protocol defines the interface for sections of each row.
 */
public protocol RCVS_DataSourceProtocol: AnyObject, Identifiable {
    /* ######################################### */
    /**
     Returns a string we can use for UI. This must be unique (`Hashable`).
     */
    var description: String { get }
    
    /* ######################################### */
    /**
     Returns a color to use for The bar element.
     */
    var color: Color { get }
    
    /* ######################################### */
    /**
     Returns the associated value.
     */
    var value: Int { get }
    
    /* ######################################### */
    /**
     Returns true, if the row is currently selected.
     */
    var isSelected: Bool { get set }
}

/* ##################################################### */
// MARK: - One Row Of Data Protocol -
/* ##################################################### */
/**
 This interprets the untyped DataFrame Row data into data that we find useful.
 
 > NOTE: Rows should be classes.
 */
public protocol RCVST_RowProtocol: AnyObject, Identifiable {
    /* ############################################# */
    /**
     True, if this row is selected.
     */
    var isSelected: Bool { get set }

    /* ################################################# */
    /**
     The date the sample was taken. `.distantFuture` is returned, if there is an error.
     */
    var sampleDate: Date { get }
    
    /* ##################################################### */
    /**
     This is the highest integer value for the Y-axis.
     */
    var maxYValue: Int { get }

    /* ################################################# */
    /**
     The untyped `DataFrame.Row` instance assigned to this instance.
     */
    var dataRow: DataFrame.Row { get set }
    
    /* ################################################# */
    /**
     This is the important part. The implementation should populate this with relevant data for display.
     
     > NOTE: The population should occur at call time, or, if cached, the cache should be refreshed, when ``dataRow`` is changed.
     */
    var plottableData: [any RCVS_DataSourceProtocol] { get }
}

/* ##################################################### */
// MARK: Protocol Defaults
/* ##################################################### */
public extension RCVST_RowProtocol {
    /* ############################################# */
    /**
     We simply use the date as an ID.
     */
    var id: any Hashable { sampleDate }

    /* ################################################# */
    /**
     Default simply gets it from the attached row.
     */
    var sampleDate: Date { dataRow["sample_date"] as? Date ?? .distantFuture }
    
    /* ##################################################### */
    /**
     Default simply goes through the values, and stacks them all together.
     */
    var maxYValue: Int { plottableData.reduce(0) { $0 + $1.value } }
}

/* ##################################################### */
// MARK: - Array Extension For Arrays of Rows -
/* ##################################################### */
extension Array where Element == any RCVST_RowProtocol {
    /* ################################################################## */
    /**
     This returns the sample closest to the given date.
     
     - parameter inDate: The date we want to compare against.
     
     - returns: The sample that is closest to (above or below) the given date.
     */
    func nearestTo(_ inDate: Date) -> Element? {
        var ret: Element?
        
        forEach {
            if let compDate = ret?.sampleDate {
                ret = abs($0.sampleDate.timeIntervalSince(inDate)) < abs(compDate.timeIntervalSince(inDate)) ? $0 : ret
            } else {
                ret = $0
            }
        }
        
        return ret
    }
}

/* ##################################################### */
// MARK: - Protocol For Sending Data to the Charts -
/* ##################################################### */
/**
 This protocol describes a chart dataset, which is sent to each chart.
 */
protocol DataProviderProtocol {
    // MARK: Required
    
    /* ##################################################### */
    /**
     This provides the data frame rows as an array of our own ``RCVST_RowProtocol`` struct.
     */
    var rows: [any RCVST_RowProtocol] { get }

    /* ##################################################### */
    /**
     (Computed Property) This provides a legend for the chart.
     
     The order of elements is first -> left (active users), last -> right (new users).
     */
    var legend: any View { get }

    /* ##################################################### */
    /**
     This is a string to be displayed at the top of the chart.
     */
    var chartName: String { get }

    /* ##################################################### */
    /**
     This is a string that is to be displayed, to describe the selected row.
     */
    var selectionString: String { get }

    /* ################################################# */
    /**
     This contains an explicit sub-range of the entire data X-axis range. If in error, an empty range is returned. Default means use ``totalDateRange``.
     */
    var dataWindowRange: ClosedRange<Date> { get set }

    // MARK: Has Default Implementation
    
    /* ##################################################### */
    /**
     The date range of our complete list of values.
     
     If not able to compute, an empty (distant past) range is returned.
     */
    var totalDateRange: ClosedRange<Date> { get }
    
    /* ################################################# */
    /**
     This contains an explicit sub-range of the entire data X-axis range. If in error, an empty range is returned. Default means use ``totalDateRange``.
     */
    var currentDataWindowRange: ClosedRange<Date> { get set }

    /* ##################################################### */
    /**
     This provides the data frame rows as an array of our own ``Row`` struct, but filtered for the window date range.
     */
    var windowedRows: [any RCVST_RowProtocol] { get }

    /* ##################################################### */
    /**
     (Computed Property) This provides a row that is currently selected. Nil, if no row selected.
     
     > NOTE: This may return rows not in the window.
     */
    var selectedRow: (any RCVST_RowProtocol)? { get }

    /* ##################################################### */
    /**
     This is the highest integer value for the Y-axis.
     */
    var maxYValue: Int { get }
    
    /* ##################################################### */
    /**
     This is a utility function, for extracting discrete user count steps from a user maximum value range. It will "pad" the gridlines to round numbers, depending on the level of the maximum value.
     
     The result will ensure that we have a top value, and a bottom value, with discrete, padded steps, in nice, round numbers, in between.
     
     - parameter numberOfValues: This is an integer, with the number of gridline steps we want. This is an arbitrary number, and will be used to determine the number of counts, between steps.
     
     - returns: An array of `Int`s, each representing one step in the Y-array values. There will be a maximum of `numberOfValues` steps, but there could be less.
     */
    func yAxisCountValues(numberOfValues: Int) -> [Int]
    
    /* ##################################################### */
    /**
     This is a utility function, for extracting discrete date steps from a date range. The step size will always be 1 day, and the returned dates will always be at 12:00:00 (Noon).
     
     - parameter numberOfValues: This is an optional (default is 4) integer, with the number of date steps we want. This is an arbitrary number, and will be used to determine the number of full days, between steps, but is not days, in itself.
     
     - returns: An array of `Date` instances, each representing one day. Each date will be at noon. There will be a maximum of `numberOfValues` dates, but there could be less.
     */
    func xAxisDateValues(numberOfValues: Int) -> [Date]
    
    /* ##################################################### */
    /**
     This will allow you to set the selection of a row, at the given index.
     
     > NOTE: The index is in terms of ``totalDateRange``.
     
     - parameter inIndex: The 0-based index (in terms of ``totalDateRange``) of the row to be affected.
     - parameter isSelected: Optional (default is true) state for the new selection (set to false, to deselect a row).
     
     - returns: The previous state of the row.
     */
    @discardableResult
    mutating func selectRow(_: Int, isSelected: Bool) -> Bool
    
    /* ##################################################### */
    /**
     This will allow you to set the selection of a a row, given a copy of the row.
     
     - parameter inRow: The row to be selected.
     - parameter isSelected: Optional (default is true) state for the new selection (set to false, to deselect a row).

     - returns: The previous state of the row.
     */
    @discardableResult
    mutating func selectRow(_: any RCVST_RowProtocol, isSelected: Bool) -> Bool
    
    /* ##################################################### */
    /**
     This removes selection from all rows.
     */
    mutating func deselectAllRows()
}

/* ##################################################### */
// MARK: Defaults For Properties
/* ##################################################### */
extension DataProviderProtocol {
    /* ##################################################### */
    /**
     (Computed Property) The date range of our complete list of values.
     
     If not able to compute, an empty (distant past) range is returned.
     */
    var totalDateRange: ClosedRange<Date> {
        guard let lowerBound = rows.first?.sampleDate,
              let upperBound = rows.last?.sampleDate
        else { return .distantPast ... .distantPast }
        
        return Calendar.current.startOfDay(for: lowerBound) ... Calendar.current.startOfDay(for: upperBound)
    }
    
    /* ################################################# */
    /**
     (Computed Property) This contains an explicit sub-range of the entire data X-axis range. If in error, an empty range is returned. Default means use ``totalDateRange``.
     */
    var currentDataWindowRange: ClosedRange<Date> {
        get {
            guard !dataWindowRange.isEmpty,
                  !totalDateRange.isEmpty
            else { return totalDateRange }
            
            return dataWindowRange.clamped(to: totalDateRange)
        }
        
        set {
            guard !newValue.isEmpty
            else {
                dataWindowRange = totalDateRange
                return
            }
            dataWindowRange = newValue.clamped(to: totalDateRange)
        }
    }

    /* ##################################################### */
    /**
     Returns a chart legend KeyValuePairs instance.
     */
    var legend: any View {
        var dictionaryLiterals = [_RCVS_LegendElement]()
        rows.forEach {
            $0.plottableData.forEach {
                let key = $0.description
                if let index = dictionaryLiterals.firstIndex(where: { $0.name == key }) {
                    dictionaryLiterals[index].color = $0.color
                } else {
                    dictionaryLiterals.append(_RCVS_LegendElement(name: key, color: $0.color))
                }
            }
        }
        dictionaryLiterals.append(_RCVS_LegendElement())
        return VStack {
            ForEach(dictionaryLiterals) { inElement in
                Text(inElement.name).foregroundColor(inElement.color)
            }
        }
    }
    
    /* ##################################################### */
    /**
     (Computed Property) This provides the data frame rows as an array of our own ``Row`` struct, but filtered for the window date range.
     */
    var windowedRows: [any RCVST_RowProtocol] { rows.filter { dataWindowRange.contains(Calendar.current.startOfDay(for: $0.sampleDate)) } }
    
    /* ##################################################### */
    /**
     (Computed Property) This provides a row that is currently selected. Nil, if no row selected.
     
     > NOTE: This may return rows not in the window.
     */
    var selectedRow: (any RCVST_RowProtocol)? { rows.first(where: { $0.isSelected }) }
    
    /* ##################################################### */
    /**
     This returns the max Y value, for the whole dataset.
     */
    var maxYValue: Int { rows.reduce(0) { max($0, $1.maxYValue) } }
}

/* ##################################################### */
// MARK: Defaults For Non-Mutating Functions
/* ##################################################### */
extension DataProviderProtocol {
    /* ##################################################### */
    /**
     This returns an array of Integers, that are to be used as the Y-axis values for the chart. This has 4 as the default value for the maximum number of elements.
     */
    func yAxisCountValues(numberOfValues inNumberOfValues: Int = 4) -> [Int] {
        guard 1 < inNumberOfValues,
              0 < maxYValue
        else { return [] }

        // This will be used for the "round up" operation. Crude, but sufficient for our needs.
        let divisors = [4, 8, 20, 100, 200, 400]
        let topDivisorIndex = divisors.last(where: { $0 < maxYValue }) ?? 0
        let divisor = topDivisorIndex / 4
        
        let stepSizeStart = Int(ceil(Double(maxYValue) / Double(inNumberOfValues - 1)))  // We start, by getting the maximum step size necessary to reach the maximum users.
        
        let stepSize = ((stepSizeStart / divisor) + 1) * divisor    // We then, pad that, so we get nice, even numbers.
        
        let finalValue = inNumberOfValues * stepSize    // The maximum value, if we go all the way.
        
        var ret = [Int]()
        
        for value in stride(from: 0, to: finalValue, by: stepSize) { ret.append(value) }
        
        return ret
    }
    
    /* ##################################################### */
    /**
     This returns an array of Dates, that are to be used as the X-axis values for the chart. This has 4 as the default value for the maximum number of elements.
     */
    func xAxisDateValues(numberOfValues inNumberOfValues: Int = 4) -> [Date] {
        guard 1 < inNumberOfValues,
              !dataWindowRange.isEmpty,
              let numberOfDays = Calendar.current.dateComponents([.day], from: dataWindowRange.lowerBound, to: dataWindowRange.upperBound).day, // Count how many days we have in our range.
              0 < numberOfDays
        else { return [] }
        
        let requestedNumberOfPoints = max(1, inNumberOfValues - 1)
        
        var dates = [Date]()    // We start by filling an array of dates, with each day in the range.

        let startingPoint = Calendar.current.startOfDay(for: dataWindowRange.lowerBound)                            // We start at the beginning of the first day.
        let endingPoint = Calendar.current.startOfDay(for: dataWindowRange.upperBound).addingTimeInterval(86400)    // We stop at the end of the last day.
        
        // We use the calendar to calculate the dates, because it will account for things like DST and leap years.
        Calendar.current.enumerateDates(startingAfter: startingPoint,
                                        matching: DateComponents(hour: 12, minute: 0, second: 0),    // We return noon, of each day. This ensures the bars center.
                                        matchingPolicy: .nextTime) { inDate, _, inOutStop in
            guard let date = inDate,
                  date < endingPoint
            else {
                inOutStop = true    // This causes the iteration to stop.
                return
            }
            
            dates.append(date)
        }
        
        // What we should have now, is an array of dates, representing noon, of each day between the two dates (inclusive).
        guard let last = dates.last else { return [] }  // Getting the last also tests, to make sure we got something.
        
        // We will now build an array of the dates that will be shown in the chart X-axis labels. We should always have the first day, and the last day.
        // The in-between values should be evenly spaced, with the possible exception of the last one, which may be inset by one day.
        var ret = [Date]()
        let divisor = Int(ceil(Double(dates.count) / Double(requestedNumberOfPoints)))  // The ceil() is where the inset might come from.
        // We add dates, depending on whether or not they are on the "steps," and we don't add any that are less than a day away from the end (prevents overlap).
        for dayCount in 0..<dates.count where (0 == dayCount % divisor) && (dates[dayCount] < last.addingTimeInterval(-86400)) { ret.append(dates[dayCount]) }
        ret.append(last)    // This makes sure we have the last value.
        
        return ret
    }
}

/* ##################################################### */
// MARK: Defaults For Mutating Functions
/* ##################################################### */
extension DataProviderProtocol {
    /* ##################################################### */
    /**
     */
    @discardableResult
    func selectRow(_ inIndex: Int, isSelected inIsSelected: Bool = true) -> Bool {
        precondition((0..<rows.count).contains(inIndex), "Index out of bounds")
        
        let ret = rows[inIndex].isSelected
        
        deselectAllRows()
        // If we are selecting a row, we make sure to deselect all others. As Connor MacLeod would say, "There can only be one."
        
        rows[inIndex].isSelected = inIsSelected
        
        return ret
    }

    /* ##################################################### */
    /**
     */
    @discardableResult
    func selectRow(_ inRow: any RCVST_RowProtocol, isSelected inIsSelected: Bool = true) -> Bool {
        guard let index = rows.firstIndex(where: { $0.sampleDate == inRow.sampleDate }) else { return false }
        return selectRow(index, isSelected: inIsSelected)
    }

    /* ##################################################### */
    /**
     */
    func deselectAllRows() {
        for row in rows.enumerated() { rows[row.offset].isSelected = false }
    }
}

// MARK: - IMPLEMENTATION -

/* ##################################################### */
// MARK: - One Element Of Data From A Row -
/* ##################################################### */
/**
 */
class RCVS_DataSource: RCVS_DataSourceProtocol {
    var description: String = "ERROR"
    
    var color: Color = .clear
    
    var value: Int = 0
    
    var isSelected: Bool = false
}

/* ##################################################### */
// MARK: - One Row Of Data -
/* ##################################################### */
/**
 This interprets the untyped DataFrame Row data into data that we find useful.
 
 This is meant to be a base class. Subclasses should provide specific data.
 */
public class RCVST_Row: RCVST_RowProtocol {
    /* ################################################# */
    /**
     (Stored Property) The untyped `DataFrame.Row` instance assigned to this instance.
     */
    public var dataRow: DataFrame.Row
    
    /* ############################################# */
    /**
     (Stored Property) True, if this row is selected.
     */
    public var isSelected = false

    /* ################################################# */
    /**
     (Computed Property) The date the sample was taken. `.distantFuture` is returned, if there is an error.
     */
    public var sampleDate: Date { dataRow["sample_date"] as? Date ?? .distantFuture }

    /* ################################################# */
    /**
     This is the important part. This should be overridden, and the subclass should populate this with relevant data for display.
     */
    public var plottableData: [any RCVS_DataSourceProtocol] = []

    /* ################################################# */
    /**
     initializer
     
     - parameter dataRow: The `DataFrame.Row` for the line we're saving.
     */
    public init(dataRow inDataRow: DataFrame.Row) {
        dataRow = inDataRow
    }
}

/* ##################################################### */
// MARK: A - Data Provider Wrapper Base Class -
/* ##################################################### */
/**
 Specialize this class, for each of the charts.
 */
class RCV_UserTypesDataProvider: DataProviderProtocol {
    /* ##################################################### */
    /**
     The name to be used to describe the chart.
     */
    var chartName: String = ""
    
    /* ##################################################### */
    /**
     This is a string that is to be displayed, to describe the selected row.
     
     > NOTE: This is meant to be provided by the subclass. The base class is empty.
     */
    var selectionString: String = ""

    /* ##################################################### */
    /**
     This contains the rows assigned to this instance.
     */
    var rows: [any RCVST_RowProtocol] = []
    
    /* ##################################################### */
    /**
     */
    var dataWindowRange: ClosedRange<Date> = .distantPast ... .distantPast
    
    /* ##################################################### */
    /**
     Default initializer. We need to supply the rows, and the chart name.
     */
    init(rows inRows: [RCVST_Row], chartName inChartName: String) {
        rows = inRows
        chartName = inChartName
        if let lowerBound = rows.first?.sampleDate,
           let upperBound = rows.last?.sampleDate {
            dataWindowRange = Calendar.current.startOfDay(for: lowerBound) ... Calendar.current.startOfDay(for: upperBound)
        }
    }
}
