/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

/* ############################################# */
// MARK: - Data Source Protocol -
/* ############################################# */
/**
 This protocol defines the interface for data rows in the chart.
 */
public protocol RCVS_DataSource: Identifiable {
    /* ######################################### */
    /**
     (Computed Property) Returns a string we can use for UI. This must be unique (`Hashable`).
     */
    var description: String { get }
    
    /* ######################################### */
    /**
     (Computed Property) Returns a color to use for The bar element.
     */
    var color: Color { get }
    
    /* ######################################### */
    /**
     (Computed Property) Returns the associated value.
     */
    var value: Int { get }
    
    /* ######################################### */
    /**
     (Computed Property) Returns true, if the row is currently selected.
     */
    var isSelected: Bool { get set }
}

/* ##################################################### */
// MARK: - Protocol For Sending Data to the Charts -
/* ##################################################### */
/**
 */
protocol DataProviderProtocol {
    /* ##################################################### */
    /**
     This provides the data frame rows as an array of our own ``Row`` struct.
     */
    var rows: [RCVST_Row] { get set }
    
    /* ################################################# */
    /**
     This contains an explicit sub-range of the entire data X-axis range. If in error, an empty range is returned. Default means use ``totalDateRange``.
     */
    var dataWindowRange: ClosedRange<Date> { get set }

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
     (Computed Property) This provides a legend for the chart.
     
     The order of elements is first -> left (active users), last -> right (new users).
     */
    var legend: KeyValuePairs<String, Color> { get }

    /* ##################################################### */
    /**
     This provides the data frame rows as an array of our own ``Row`` struct, but filtered for the window date range.
     */
    var windowedRows: [RCVST_Row] { get }
    
    /* ##################################################### */
    /**
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
    mutating func selectRow(_: RCVST_Row, isSelected: Bool) -> Bool
    
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
     (Computed Property) This provides the data frame rows as an array of our own ``Row`` struct, but filtered for the window date range.
     */
    var windowedRows: [RCVST_Row] { rows.filter { dataWindowRange.contains(Calendar.current.startOfDay(for: $0.sampleDate)) } }
    
    /* ##################################################### */
    /**
     (Computed Property) This provides a row that is currently selected. Nil, if no row selected.
     
     > NOTE: This may return rows not in the window.
     */
    var selectedRow: RCVST_Row? { rows.first(where: { $0.isSelected }) }

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
     (Computed Property) This provides a legend for the chart.
     
     The order of elements is first -> left (active users), last -> right (new users).
     */
    var legend: KeyValuePairs<String, Color> { [:] }
    
    /* ##################################################### */
    /**
     */
    var maxYValue: Int { 0 }
}

/* ##################################################### */
// MARK: Defaults For Non-Mutating Functions
/* ##################################################### */
extension DataProviderProtocol {
    /* ##################################################### */
    /**
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
    mutating func selectRow(_ inIndex: Int, isSelected inIsSelected: Bool = true) -> Bool {
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
    mutating func selectRow(_ inRow: RCVST_Row, isSelected inIsSelected: Bool = true) -> Bool {
        guard let index = rows.firstIndex(where: { $0 == inRow }) else { return false }
        return selectRow(index, isSelected: inIsSelected)
    }
    
    /* ##################################################### */
    /**
     */
    mutating func deselectAllRows() {
        for row in rows.enumerated() { rows[row.offset].isSelected = false }
    }
}

// MARK: - IMPLEMENTATION -

/* ##################################################### */
// MARK: - One Row Of Data -
/* ##################################################### */
/**
 This interprets the untyped DataFrame Row data into data that we find useful.
 
 This is meant to be a base class. Subclasses should provide specific data.
 
 > NOTE: This is a class, as opposed to a struct, so it will be referenced, and can be subclassed.
 */
public class RCVST_Row {
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
    public var plottableData: [any RCVS_DataSource] = []

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
// MARK: Equatable Conformance
/* ##################################################### */
extension RCVST_Row: Equatable {
    /* ################################################# */
    /**
     We base this on the sample date.
     
     - parameter lhs: The left-hand side of the comparison.
     - parameter rhs: The right-hand side of the comparison.
     */
    public static func == (lhs: RCVST_Row, rhs: RCVST_Row) -> Bool { lhs.sampleDate == rhs.sampleDate }
}

/* ##################################################### */
// MARK: - Array Extension For Arrays of Rows -
/* ##################################################### */
extension Array where Element == RCVST_Row {
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
// MARK: A - Data Provider Wrapper -
/* ##################################################### */
struct RCV_UserTypesDataProvider: DataProviderProtocol {
    /* ##################################################### */
    /**
     */
    var rows: [RCVST_Row] = []
    
    /* ##################################################### */
    /**
     */
    var dataWindowRange: ClosedRange<Date> = .distantPast ... .distantPast
    
    /* ##################################################### */
    /**
     */
    init(rows inRows: [RCVST_Row]) {
        rows = inRows
        if let lowerBound = rows.first?.sampleDate,
           let upperBound = rows.last?.sampleDate {
            dataWindowRange = Calendar.current.startOfDay(for: lowerBound) ... Calendar.current.startOfDay(for: upperBound)
        }
    }
}
