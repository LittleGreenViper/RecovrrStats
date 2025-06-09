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
class RCVS_LegendElement: Identifiable {
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
    var value: Float { get }
    
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
    var maxYValue: Float { get }

    /* ################################################# */
    /**
     The untyped `DataFrame.Row` instance for the row just previous to the one assigned to this instance (can be nil, if it's the first row).
     */
    var previousDataRow: DataFrame.Row? { get set }

    /* ################################################# */
    /**
     The untyped `DataFrame.Row` instance assigned to this instance.
     */
    var dataRow: DataFrame.Row { get set }

    /* ################################################# */
    /**
     The 0-based index (in the dataframe rows) of this row (it will also be the index of this row).
     */
    var rowIndex: Int { get set }

    /* ################################################# */
    /**
     This is the important part. The implementation should populate this with relevant data for display.
     
     > NOTE: The population should occur at call time, or, if cached, the cache should be refreshed, when ``dataRow`` is changed.
     */
    var plottableData: [RCVST_Row.RCVST_BasePlottableData] { get }
}

/* ##################################################### */
// MARK: Protocol Defaults
/* ##################################################### */
public extension RCVST_RowProtocol {
    // MARK: Previous Sample Access (Private)
    
    /* ############################################################## */
    /**
     The total number of users (both active and inactive), for the previous sample.
     */
    var previousTotalUsers: Int { previousDataRow?[RCVST_DataProvider.Columns.total_users.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.total_users.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The total number of new (inactive) users, for the previous sample.
     */
    var previousNewUsers: Int { previousDataRow?[RCVST_DataProvider.Columns.new_users.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.new_users.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of users (both active and new), for the previous sample.
     */
    var previousNeverSetLocation: Int { previousDataRow?[RCVST_DataProvider.Columns.never_set_location.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.never_set_location.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative total number of signup requests, for the previous sample.
     */
    var previousTotalRequests: Int { previousDataRow?[RCVST_DataProvider.Columns.total_requests.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.total_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative total number of signup requests approved by the administrators, for the previous sample.
     */
    var previousAcceptedRequests: Int { previousDataRow?[RCVST_DataProvider.Columns.accepted_requests.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.accepted_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative total number of signup requests rejected by the administrators, for the previous sample.
     */
    var previousRejectedRequests: Int { previousDataRow?[RCVST_DataProvider.Columns.rejected_requests.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.rejected_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative number of active users that have been deleted by the administrators, for the previous sample.
     */
    var previousDeletedActive: Int { previousDataRow?[RCVST_DataProvider.Columns.deleted_active.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.deleted_active.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative number of new users that have been deleted by the administrators, for the previous sample.
     */
    var previousDeletedInactive: Int { previousDataRow?[RCVST_DataProvider.Columns.deleted_inactive.rawValue] as? Int ?? dataRow[RCVST_DataProvider.Columns.deleted_inactive.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The total number of active users, for the previous sample.
     */
    var previousActiveUsers: Int { previousTotalUsers - previousNewUsers }
    
    // MARK: Public Data
    
    /* ############################################# */
    /**
     We simply use the date as an ID.
     */
    var id: any Hashable { sampleDate }
    
    /* ################################################# */
    /**
     Default simply gets it from the attached row.
     */
    var sampleDate: Date { dataRow[RCVST_DataProvider.Columns.sample_date.rawValue] as? Date ?? .distantFuture }
    
    /* ##################################################### */
    /**
     Default simply goes through the values, and stacks them all together.
     */
    var maxYValue: Float { plottableData.reduce(0) { $0 + $1.value } }
    
    // MARK: Raw Data
    
    /* ############################################################## */
    /**
     The total number of users (both active and inactive), at the time the sample was taken.
     */
    var totalUsers: Int { dataRow[RCVST_DataProvider.Columns.total_users.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The total number of new (inactive) users, at the time the sample was taken.
     */
    var newUsers: Int { dataRow[RCVST_DataProvider.Columns.new_users.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of users (both active and new), that have a nil location (never set one).
     */
    var neverSetLocation: Int { dataRow[RCVST_DataProvider.Columns.never_set_location.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative total number of signup requests.
     */
    var totalRequests: Int { dataRow[RCVST_DataProvider.Columns.total_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative total number of signup requests approved by the administrators.
     */
    var acceptedRequests: Int { dataRow[RCVST_DataProvider.Columns.accepted_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative total number of signup requests rejected by the administrators.
     */
    var rejectedRequests: Int { dataRow[RCVST_DataProvider.Columns.rejected_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of signup requests that have not been addressed by the administrators.
     */
    var openRequests: Int { dataRow[RCVST_DataProvider.Columns.open_requests.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of active (not new) users that have signed in, within the last 24 hours.
     */
    var activeInLast24Hours: Int { dataRow[RCVST_DataProvider.Columns.active_1.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of active (not new) users that have signed in, within the last 7 days.
     */
    var activeInLastWeek: Int { dataRow[RCVST_DataProvider.Columns.active_7.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of active (not new) users that have signed in, within the last 30 days.
     */
    var activeInLast30Days: Int { dataRow[RCVST_DataProvider.Columns.active_30.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current number of active (not new) users that have signed in, within the last 90 days.
     */
    var activeInLast90Days: Int { dataRow[RCVST_DataProvider.Columns.active_90.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The current simple average last activity period for all active users, in days.
     */
    var averageLastActiveInDays: Int { dataRow[RCVST_DataProvider.Columns.active_avg.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative number of active users that have been deleted by the administrators.
     */
    var deletedActive: Int { dataRow[RCVST_DataProvider.Columns.deleted_active.rawValue] as? Int ?? 0 }

    /* ############################################################## */
    /**
     The cumulative number of new users that have been deleted by the administrators.
     */
    var deletedInactive: Int { dataRow[RCVST_DataProvider.Columns.deleted_inactive.rawValue] as? Int ?? 0 }

    // MARK: Interpreted Data

    /* ############################################################## */
    /**
     The total number of active users, at the time the sample was taken.
     */
    var activeUsers: Int { totalUsers - newUsers }

    /* ############################################################## */
    /**
     The change in the total number of users. Positive is users added, negative is users removed.
     */
    var changeInTotalUsers: Int { 0 == previousTotalUsers ? 0 : totalUsers - previousTotalUsers }

    /* ############################################################## */
    /**
     The change in the total number of inactive users. Positive is users added, negative is users removed.
     */
    var changeInNewUsers: Int { 0 == previousNewUsers ? 0 : newUsers - previousNewUsers }

    /* ############################################################## */
    /**
     The change in the total number of inactive users. Positive is users added, negative is users removed.
     */
    var changeInActiveUsers: Int { 0 == previousActiveUsers ? 0 : activeUsers - previousActiveUsers }

    /* ############################################################## */
    /**
     The change in the number of users (both active and new), that have a nil location.
     */
    var changeInNeverSetLocation: Int { 0 == previousNeverSetLocation ? 0 : neverSetLocation - previousNeverSetLocation }

    /* ############################################################## */
    /**
     The number of signup requests since the last sample.
     */
    var newRequests: Int { totalRequests - previousTotalRequests }

    /* ############################################################## */
    /**
     The number of signup requests approved by the administrators since the last sample.
     */
    var newAcceptedRequests: Int { acceptedRequests - previousAcceptedRequests }

    /* ############################################################## */
    /**
     The number of signup requests rejected by the administrators since the last sample.
     */
    var newRejectedRequests: Int { rejectedRequests - previousRejectedRequests }

    /* ############################################################## */
    /**
     The number of active users deleted by the administrators since the last sample.
     */
    var newDeletedActive: Int { deletedActive - previousDeletedActive }

    /* ############################################################## */
    /**
     The number of inactive users deleted by the administrators since the last sample.
     */
    var newDeletedInactive: Int { deletedInactive - previousDeletedInactive }
    
    /* ############################################################## */
    /**
     The number of users that deleted their own accounts.
     */
    var selfDeletions: Int {
        let adminDeletions = (deletedActive - previousDeletedActive) +
                             (deletedInactive - previousDeletedInactive)

        // Calculate expected total users if only admin deletions happened
        let expectedTotalUsers = totalUsers - adminDeletions

        // Self-deletions are the unexpected drop in totalUsers
        return max(0, expectedTotalUsers - totalUsers)
    }
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
        let testDate = Calendar.current.startOfDay(for: inDate).addingTimeInterval(43200)
        forEach {
            if let compDateTemp = ret?.sampleDate {
                let compDate = Calendar.current.startOfDay(for: compDateTemp).addingTimeInterval(43200)
                let thisDate = Calendar.current.startOfDay(for: $0.sampleDate).addingTimeInterval(43200)
                ret = abs(thisDate.timeIntervalSince(testDate)) < abs(compDate.timeIntervalSince(testDate)) ? $0 : ret
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
protocol DataProviderProtocol: Identifiable {
    /* ##################################################### */
    /**
     This satisfies our ID requirements.
     */
    var id: String { get }
    
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
    var legend: [RCVS_LegendElement] { get }
    
    /* ##################################################### */
    /**
     (Computed Property) The string to use for the Y-axis.
     */
    var yAxisLabel: String { get }
    
    /* ##################################################### */
    /**
     (Computed Property) The string to use for the X-axis.
     */
    var xAxisLabel: String { get }

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
    var maxYValue: Float { get }

    /* ################################################################## */
    /**
     This reports the number of days in the current data window.
     */
    var numberOfDays: Int { get }

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
     
     - parameter inRow: The row to be selected (as an instance).
     - parameter isSelected: Optional (default is true) state for the new selection (set to false, to deselect a row).

     - returns: The previous state of the row.
     */
    @discardableResult
    mutating func selectRow(_: any RCVST_RowProtocol, isSelected: Bool) -> Bool
    
    /* ##################################################### */
    /**
     This sets our data range.
     
     - parameter inDataWindowRange: A closed Date range, equal to, or a subset of, ``totalDateRange``
     */
    mutating func setDataWindowRange(_ inDataWindowRange: ClosedRange<Date>)
    
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
     This satisfies our ID requirements.
     */
    var id: String { chartName }
    
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
     (Computed Property) Returns true, if the data window stretches across the entire range.
     */
    var isMaxed: Bool { currentDataWindowRange == totalDateRange }
    
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
     Returns a chart legend data instance.
     */
    var legend: [RCVS_LegendElement] {
        var dictionaryLiterals = [RCVS_LegendElement]()
        rows.forEach {
            $0.plottableData.forEach {
                let key = $0.description
                if let index = dictionaryLiterals.firstIndex(where: { $0.name == key }) {
                    dictionaryLiterals[index].color = $0.color
                } else {
                    dictionaryLiterals.append(RCVS_LegendElement(name: key, color: $0.color))
                }
            }
        }
        dictionaryLiterals.append(RCVS_LegendElement())
        
        return dictionaryLiterals
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
     (Computed Property) This returns the max Y value, for the whole dataset.
     */
    var maxYValue: Float { rows.reduce(0) { max($0, $1.maxYValue) } }
    
    /* ##################################################### */
    /**
     (Computed Property) The string to use for the Y-axis.
     */
    var yAxisLabel: String { "SLUG-BAR-CHART-Y-AXIS-LABEL".localizedVariant }
    
    /* ##################################################### */
    /**
     (Computed Property) The string to use for the X-axis.
     */
    var xAxisLabel: String { "SLUG-BAR-CHART-X-AXIS-LABEL".localizedVariant }

    /* ################################################################## */
    /**
     (Computed Property) This reports the number of days in the current data window.
     */
    var numberOfDays: Int { (Int(dataWindowRange.lowerBound.distance(to: dataWindowRange.upperBound) + 86399) / 86400) }
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
        let divisors = [8, 16, 24, 32, 40, 80, 160, 240, 320, 400, 800, 1600]
        let topDivisor = divisors.last(where: { $0 <= Int(ceil(maxYValue)) }) ?? 0
        let divisor = max(1, topDivisor / 8)
        
        let stepSizeStart = Int(ceil(Double(maxYValue) / Double(inNumberOfValues - 1)))  // We start, by getting the maximum step size necessary to reach the maximum users.
        
        let stepSize = ((stepSizeStart + (divisor - 1)) / divisor) * divisor    // We then, pad that, so we get nice, even numbers.
        
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
     This simply deselects all rows, then selects the indexed one.
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
     This simply deselects all rows, then selects the referenced one.
     */
    @discardableResult
    mutating func selectRow(_ inRow: any RCVST_RowProtocol, isSelected inIsSelected: Bool = true) -> Bool {
        guard let index = rows.firstIndex(where: { $0.sampleDate == inRow.sampleDate }) else { return false }
        return selectRow(index, isSelected: inIsSelected)
    }

    /* ##################################################### */
    /**
     This deselects all rows.
     */
    mutating func deselectAllRows() {
        for row in rows.enumerated() { rows[row.offset].isSelected = false }
    }
    
    /* ##################################################### */
    /**
     We simply set the date range.
     */
    mutating func setDataWindowRange(_ inDataWindowRange: ClosedRange<Date>) {
        dataWindowRange = inDataWindowRange
    }
}

// MARK: - IMPLEMENTATION -

/* ##################################################### */
// MARK: - One Element Of Data From A Row -
/* ##################################################### */
/**
 This is a very simple interface for each plottable data item.
 
 Note that it is a class, not a struct. We do this, so it can be subclassed and referenced.
 */
class RCVS_DataSource: RCVS_DataSourceProtocol {
    /* ##################################################### */
    /**
     The textual description of this plottable data item.
     */
    var description: String = "ERROR"
    
    /* ##################################################### */
    /**
     The color to be applied, in the chart.
     */
    var color: Color = .clear
    
    /* ##################################################### */
    /**
     The value (as an Int) for this plottable data item.
     */
    var value: Float = 0
    
    /* ##################################################### */
    /**
     True, if the row is currently selected.
     */
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
    // MARK: - One Value Segment Of A Row Of Data -
    /* ################################################# */
    /**
     Each row can have multiple segments. This general-purpose class is used to communicate these segments.
     */
    public class RCVST_BasePlottableData: RCVS_DataSourceProtocol {
        /* ############################################# */
        /**
         (Stored Property) The row segment description
         */
        public var description: String
        
        /* ############################################# */
        /**
         (Stored Property) The row segment color
         */
        public var color: Color
        
        /* ############################################# */
        /**
         (Stored Property) The row segment value
         */
        public var value: Float
        
        /* ############################################# */
        /**
         (Stored Property) True, if the row segment is selected.
         */
        public var isSelected: Bool
        
        /* ############################################# */
        /**
         Default initializer.
         
         - parameters:
            - description: The row segment description
            - color: The row segment color
            - value: The row segment value
            - isSelected: True, if the row segment is selected.
         */
        public init(description inDescription: String, color inColor: Color, value inValue: Float, isSelected inIsSelected: Bool) {
            description = inDescription
            color = inColor
            value = inValue
            isSelected = inIsSelected
        }
    }

    /* ################################################# */
    /**
     The 0-based index (in the dataframe rows) of this row (it will also be the index of this row).
     */
    public var rowIndex: Int

    /* ################################################# */
    /**
     (Stored Property) The untyped `DataFrame.Row` instance assigned to this instance.
     */
    public var previousDataRow: DataFrame.Row?

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
    public var plottableData: [RCVST_BasePlottableData] = []

    /* ################################################# */
    /**
     initializer
     
     - parameter dataRow: The `DataFrame.Row` for the line we're saving.
     - parameter previousDataRow: The `DataFrame.Row` for the line prior to the one we're saving (may be nil, for the first row).
     - parameter rowIndex: The 0-based index (in the dataframe rows) of this row (it will also be the index of this row).
     */
    public init(dataRow inDataRow: DataFrame.Row, previousDataRow inPreviousDataRow: DataFrame.Row?, rowIndex inIndex: Int) {
        dataRow = inDataRow
        rowIndex = inIndex
        previousDataRow = inPreviousDataRow
    }
}
