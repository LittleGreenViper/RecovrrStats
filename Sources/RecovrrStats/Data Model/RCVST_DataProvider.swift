/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Special Date Extension For Subtracting Dates -
/* ###################################################################################################################################### */
extension Date {
    /* ################################################################## */
    /**
     A simple minus operator for dates.
     
     - paremeter lhs: The left-hand side of the subtration
     - parameter rhs: The right-hand side of the subtraction.
     - returns: A TimeInterval, with the number of seconds between the dates. If rhs > lhs, it is negative.
     */
    static func - (lhs: Date, rhs: Date) -> TimeInterval { lhs.timeIntervalSinceReferenceDate - rhs.timeIntervalSinceReferenceDate }
}

/* ###################################################################################################################################### */
// MARK: - Protocol That Allows Generic Handling -
/* ###################################################################################################################################### */
protocol RCVST_DataProvider_ElementHasDate {
    /* ############################################################## */
    /**
     The date the sample was taken. If error, it will be .distantFuture
     */
    var date: Date { get }
}

/* ###################################################################################################################################### */
// MARK: - Array Extension For Arrays of Rows -
/* ###################################################################################################################################### */
extension Array where Element: RCVST_DataProvider_ElementHasDate {
    /* ################################################################## */
    /**
     This returns the sample closest to the given date.
     
     - parameter inDate: The date we want to compare against.
     
     - returns: The sample that is closest to (above or below) the given date.
     */
    func nearestTo(_ inDate: Date) -> Element? {
        var ret: Element?
        
        forEach {
            let currentDate = $0.date
            
            guard let compDate = ret?.date
            else {
                ret = $0
                return
            }
            
            ret = abs(currentDate.timeIntervalSince(inDate)) < abs(compDate.timeIntervalSince(inDate)) ? $0 : ret
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Stats Data Provider -
/* ###################################################################################################################################### */
/**
 This class reads in and processes the stats data.
 */
public class RCVST_DataProvider {
    /* ################################################################## */
    /**
     Mock CSV data. The first ten days.
     */
    private static let _g_mockData = """
sample_date,total_users,new_users,never_set_location,total_requests,accepted_requests,rejected_requests,open_requests,active_1,active_7,active_30,active_90,active_avg,deleted_active,deleted_inactive
1728964808,662,50,133,10,8,2,0,18,65,163,337,94,0,1
1729008013,660,47,132,12,9,3,0,19,65,164,337,95,0,4
1729051207,662,49,132,18,11,3,4,21,63,164,336,95,0,4
1729094406,667,53,133,19,16,3,0,19,64,163,337,95,0,4
1729137610,671,54,135,26,21,4,1,23,68,162,340,95,0,5
1729180807,672,55,136,26,22,4,0,24,69,162,340,95,0,5
1729224015,677,56,136,33,27,6,0,24,75,161,341,95,0,5
1729267207,677,56,136,33,27,6,0,23,77,160,341,96,0,5
1729310410,678,53,136,38,32,6,1,22,81,164,345,95,0,8
1729353606,681,55,137,40,35,6,0,25,83,166,346,95,0,8
1729396809,681,54,136,44,38,7,0,28,84,166,346,95,0,11
1729440009,683,55,136,47,40,8,0,23,85,166,346,95,0,11
1729483207,684,56,136,50,42,9,0,20,84,165,342,96,0,11
1729526409,685,57,136,52,43,10,0,21,84,165,340,96,0,11
1729569607,684,55,135,57,48,10,0,17,80,163,339,96,0,17
1729612810,684,55,135,57,48,10,0,18,80,163,337,97,0,17
1729656010,680,51,135,59,49,10,1,20,80,164,336,97,0,22
1729699210,684,54,136,62,53,10,0,21,81,165,337,97,0,22
1729742408,686,54,137,64,55,10,0,26,86,162,340,97,0,22
1729785608,688,55,138,66,57,10,0,22,85,162,341,97,0,22
""".data(using: .utf8)
    
    /* ################################################################## */
    /**
     The URL string to the active stats file.
     */
    private static let _g_statsURLString = "https://recovrr.org/recovrr/log/stats.csv"
    
    /* ################################################################## */
    /**
     This stores the dataframe info.
     */
    var statusDataFrame: DataFrame?

    /* ################################################################## */
    /**
     Upon initialization, we go out, and fetch the stats file.
     
     - parameter useMockData: If true (OPTIONAL -default is true), then we load mock data, instead of the actual file.
     */
    required init(useMockData inUseMockData: Bool = true) {
        _fetchStats(useMockData: inUseMockData) { inResults in DispatchQueue.main.async { self.statusDataFrame = inResults } }
    }
}

/* ###################################################################################################################################### */
// MARK: Private Column Identifier Enum
/* ###################################################################################################################################### */
extension RCVST_DataProvider {
    /// This provides enums for internal use.
    private enum _Columns: String, CaseIterable {
        /* ############################################################## */
        /**
         The date that this sample was taken.
         */
        case sample_date
        
        /* ############################################################## */
        /**
         The current total number of users (both active and new), in the server. It does not include signups.
         */
        case total_users
        
        /* ############################################################## */
        /**
         The current number of users that have never signed in.
         */
        case new_users
        
        /* ############################################################## */
        /**
         The current number of users (both active and new), that have a nil location (never set one).
         */
        case never_set_location
        
        /* ############################################################## */
        /**
         The cumulative total number of signup requests.
         */
        case total_requests
        
        /* ############################################################## */
        /**
         The cumulative total number of signup requests approved by the administrators.
         */
        case accepted_requests
        
        /* ############################################################## */
        /**
         The cumulative total number of signup requests rejected by the administrators.
         */
        case rejected_requests
        
        /* ############################################################## */
        /**
         The current number of signup requests that have not been addressed by the administrators.
         */
        case open_requests
        
        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 24 hours.
         */
        case active_1
        
        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 7 days.
         */
        case active_7
        
        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 30 days.
         */
        case active_30
        
        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 90 days.
         */
        case active_90
        
        /* ############################################################## */
        /**
         The current simple average last activity period for all active users, in days.
         */
        case active_avg
        
        /* ############################################################## */
        /**
         The cumulative number of active users that have been deleted by the administrators.
         */
        case deleted_active
        
        /* ############################################################## */
        /**
         The cumulative number of new users that have been deleted by the administrators.
         */
        case deleted_inactive
        
        /* ############################################################## */
        /**
         The column name, localized.
         */
        var localizedString: String { "SLUG-COLUMN-NAME-\(rawValue)".localizedVariant }
    }
}

/* ###################################################################################################################################### */
// MARK: Private Instance Methods
/* ###################################################################################################################################### */
extension RCVST_DataProvider {
    /* ################################################################## */
    /**
     This fetches the current stats file, and delivers it as a dataframe.
     
     - parameter useMockData: If true, then we load mock data, instead of the actual file.
     - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats.
     */
    private func _fetchStats(useMockData inUseMockData: Bool, completion inCompletion: ((DataFrame?) -> Void)?) {
        // We don't need to do this in the main thread.
        DispatchQueue.global().async {
            if inUseMockData,
               let mockData = Self._g_mockData,
               !mockData.isEmpty {
                do {
                    var dataFrame = try DataFrame(csvData: mockData)
                    // We convert the integer timestamp to a more usable Date instance.
                    dataFrame.transformColumn(_Columns.sample_date.rawValue) { (inUnixTime: Int) -> Date in Date(timeIntervalSince1970: TimeInterval(inUnixTime)) }
                    #if DEBUG
                        print("Data Frame Mock Data Successful Initialization")
                    #endif
                    inCompletion?(dataFrame)
                } catch {
                    #if DEBUG
                        print("Data Frame Mock Data Initialization Error: \(error.localizedDescription)")
                    #endif
                    inCompletion?(nil)
                }
            } else if let url = URL(string: Self._g_statsURLString) {
                do {
                    var dataFrame = try DataFrame(contentsOfCSVFile: url)
                    // We convert the integer timestamp to a more usable Date instance.
                    dataFrame.transformColumn(_Columns.sample_date.rawValue) { (inUnixTime: Int) -> Date in Date(timeIntervalSince1970: TimeInterval(inUnixTime)) }
                    #if DEBUG
                        print("Data Frame Successful Initialization")
                    #endif
                    inCompletion?(dataFrame)
                } catch {
                    #if DEBUG
                        print("Data Frame Initialization Error: \(error.localizedDescription)")
                    #endif
                    inCompletion?(nil)
                }
            } else {
                #if DEBUG
                    print("Unknown State. No Mock Data, No URL")
                #endif
                inCompletion?(nil)
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: The Public Data Row Nested Class
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /// This provides a simple interface to the data for each row.
    struct Row: Identifiable, RCVST_DataProvider_ElementHasDate {
        /* ############################################################## */
        /**
         Make us identifiable.
         */
        public let id = UUID()
        
        // MARK: Previous Sample Access (Private)
        
        /* ############################################################## */
        /**
         This is the actual raw data that we have to work with for this row.
         */
        private var _rowData: DataFrame.Row? { dataProvider?.statusDataFrame?.rows[rowIndex] }
        
        /* ############################################################## */
        /**
         This is the raw data for the prior row.
         */
        private var _previousRowData: DataFrame.Row? { 0 < rowIndex ? dataProvider?.statusDataFrame?.rows[rowIndex - 1] : nil }
        
        /* ############################################################## */
        /**
         The total number of users (both active and inactive), for the previous sample.
         */
        private var _previousTotalUsers: Int { _previousRowData?["total_users"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of new (inactive) users, for the previous sample.
         */
        private var _previousNewUsers: Int { _previousRowData?["new_users"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of users (both active and new), for the previous sample.
         */
        private var _previousNeverSetLocation: Int { _previousRowData?["never_set_location"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests, for the previous sample.
         */
        private var _previousTotalRequests: Int { _previousRowData?["total_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests approved by the administrators, for the previous sample.
         */
        private var _previousAcceptedRequests: Int { _previousRowData?["accepted_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests rejected by the administrators, for the previous sample.
         */
        private var _previousRejectedRequests: Int { _previousRowData?["rejected_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of active users that have been deleted by the administrators, for the previous sample.
         */
        private var _previousDeletedActive: Int { _previousRowData?["deleted_active"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of new users that have been deleted by the administrators, for the previous sample.
         */
        private var _previousDeletedInactive: Int { _previousRowData?["deleted_inactive"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of active users, for the previous sample.
         */
        private var _previousActiveUsers: Int { _previousTotalUsers - _previousNewUsers }

        // MARK: Public Stored Properties
        
        /* ############################################################## */
        /**
         The main data container that "owns" this row.
         */
        public weak var dataProvider: RCVST_DataProvider?
        
        /* ############################################################## */
        /**
         The 0-based row index for this row. This is against the total rows in the data provider, not a subset.
         */
        public let rowIndex: Int
        
        /* ############################################################## */
        /**
         Default initializer.
         
         - parameter dataProvider: The instance that "owns" this row.
         - parameter rowIndex: The 0-based index of the row (in terms of the entire dataset, not a subset).
         */
        public init(dataProvider inDataProvider: RCVST_DataProvider, rowIndex inRowIndex: Int) {
            dataProvider = inDataProvider
            rowIndex = inRowIndex
        }
        
        // MARK: Raw Data
        
        /* ############################################################## */
        /**
         The total number of users (both active and inactive), at the time the sample was taken.
         */
        public var totalUsers: Int { _rowData?["total_users"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of new (inactive) users, at the time the sample was taken.
         */
        public var newUsers: Int { _rowData?["new_users"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of users (both active and new), that have a nil location (never set one).
         */
        public var neverSetLocation: Int { _rowData?["never_set_location"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests.
         */
        public var totalRequests: Int { _rowData?["total_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests approved by the administrators.
         */
        public var acceptedRequests: Int { _rowData?["accepted_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests rejected by the administrators.
         */
        public var rejectedRequests: Int { _rowData?["rejected_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of signup requests that have not been addressed by the administrators.
         */
        public var openRequests: Int { _rowData?["open_requests"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 24 hours.
         */
        public var activeInLast24Hours: Int { _rowData?["active_1"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 7 days.
         */
        public var activeInLastWeek: Int { _rowData?["active_7"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 30 days.
         */
        public var activeInLast30Days: Int { _rowData?["active_30"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 90 days.
         */
        public var activeInLast90Days: Int { _rowData?["active_90"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current simple average last activity period for all active users, in days.
         */
        public var averageLastActiveInDays: Int { _rowData?["active_avg"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of active users that have been deleted by the administrators.
         */
        public var deletedActive: Int { _rowData?["deleted_active"] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of new users that have been deleted by the administrators.
         */
        public var deletedInactive: Int { _rowData?["deleted_inactive"] as? Int ?? 0 }

        // MARK: Interpreted Data

        /* ############################################################## */
        /**
         The total number of active users, at the time the sample was taken.
         */
        public var activeUsers: Int { totalUsers - newUsers }

        /* ############################################################## */
        /**
         The change in the total number of users. Positive is users added, negative is users removed.
         */
        public var changeInTotalUsers: Int { 0 == _previousTotalUsers ? 0 : totalUsers - _previousTotalUsers }

        /* ############################################################## */
        /**
         The change in the total number of inactive users. Positive is users added, negative is users removed.
         */
        public var changeInNewUsers: Int { 0 == _previousNewUsers ? 0 : newUsers - _previousNewUsers }

        /* ############################################################## */
        /**
         The change in the total number of inactive users. Positive is users added, negative is users removed.
         */
        public var changeInActiveUsers: Int { 0 == _previousActiveUsers ? 0 : activeUsers - _previousActiveUsers }

        /* ############################################################## */
        /**
         The change in the number of users (both active and new), that have a nil location.
         */
        public var changeInNeverSetLocation: Int { 0 == _previousNeverSetLocation ? 0 : neverSetLocation - _previousNeverSetLocation }

        /* ############################################################## */
        /**
         These are the number of users that logged into their accounts for the first time, since the last sample.
         */
        public var newFirstTimeLogins: Int { Swift.max(0, changeInNewUsers - newDeletedInactive) }

        /* ############################################################## */
        /**
         The number of signup requests since the last sample.
         */
        public var newRequests: Int { totalRequests - _previousTotalRequests }

        /* ############################################################## */
        /**
         The number of signup requests approved by the administrators since the last sample.
         */
        public var newAcceptedRequests: Int { acceptedRequests - _previousAcceptedRequests }

        /* ############################################################## */
        /**
         The number of signup requests rejected by the administrators since the last sample.
         */
        public var newRejectedRequests: Int { rejectedRequests - _previousRejectedRequests }

        /* ############################################################## */
        /**
         The number of active users deleted by the administrators since the last sample.
         */
        public var newDeletedActive: Int { deletedActive - _previousDeletedActive }

        /* ############################################################## */
        /**
         The number of inactive users deleted by the administrators since the last sample.
         */
        public var newDeletedInactive: Int { deletedInactive - _previousDeletedInactive }

        /* ############################################################## */
        /**
         These are the number of users that deleted their own accounts, since the last sample.
         */
        public var newSelfDeleted: Int {
            let newNegativeDeletedActive = -newDeletedActive
            return abs(Swift.max(0, newNegativeDeletedActive - changeInActiveUsers))
        }

        // MARK: RCVST_DataProvider_ElementHasDate Conformance
        
        /* ############################################################## */
        /**
         The date the sample was taken. If error, it will be .distantFuture
         */
        public var date: Date { _rowData?["sample_date"] as? Date ?? .distantFuture }
    }
}

/* ###################################################################################################################################### */
// MARK: Public Computed Properties
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################## */
    /**
     The total number of samples.
     */
    var count: Int { statusDataFrame?.rows.count ?? 0 }
    
    /* ################################################################## */
    /**
     The range, in dates, of the samples.
     */
    var dateRange: ClosedRange<Date> {
        guard let rows = statusDataFrame?.rows,
              !rows.isEmpty
        else { return Date.now...Date.now }
        let startDate = rows[0][_Columns.sample_date.rawValue] as? Date ?? .now
        let endDate = rows[rows.count - 1][_Columns.sample_date.rawValue] as? Date ?? .now
        return startDate...endDate
    }
    
    /* ################################################################## */
    /**
     The start date, expressed as a simple day date (no time - localized string)
     */
    var formattedStartDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: dateRange.lowerBound)
    }
    
    /* ################################################################## */
    /**
     The end date, expressed as a simple day date (no time - localized string)
     */
    var formattedEndDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: dateRange.upperBound)
    }
    
    /* ################################################################## */
    /**
     The start date, expressed as a day and time date (localized string)
     */
    var formattedStartDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: dateRange.lowerBound)
    }
    
    /* ################################################################## */
    /**
     The end date, expressed as a day and time date (localized string)
     */
    var formattedEndDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: dateRange.upperBound)
    }
    
    /* ################################################################## */
    /**
     This returns every row, as an instance of ``Row``.
     */
    var allRows: [Row] { rows() }
    
    /* ################################################################## */
    /**
     This simply access a single row by its 0-based index.
     
     - parameter inIndex: The 0-based row index (0..<count)
     
     - returns: An instance of ``Row``, set up to access that row's data.
     */
    subscript(_ inIndex: Int) -> Row { Row(dataProvider: self, rowIndex: inIndex) }
}

/* ###################################################################################################################################### */
// MARK: Public Instance Methods
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################## */
    /**
     This returns all the samples between two dates.
     
     - parameter dataWindow: A date range for the samples (closed). If not provided, all samples are returned.
     
     - returns: An array of Row instances, with the filtered rows. They are ordered from earliest to latest.
     */
    func rows(dataWindow inDataWindow: ClosedRange<Date> = Date.distantPast...Date.distantFuture) -> [Row] {
        guard let dataFrameRows = statusDataFrame?.rows,
              !dataFrameRows.isEmpty
        else { return [] }
        
        var ret = [Row]()
        var index = 0
        
        dataFrameRows.forEach { inRow in
            if let date = inRow[0] as? Date,
               inDataWindow.contains(date) {
                ret.append(Row(dataProvider: self, rowIndex: index))
            }
            
            index += 1
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: CustomDebugStringConvertible Conformance
/* ###################################################################################################################################### */
extension RCVST_DataProvider: CustomDebugStringConvertible {
    /* ################################################################## */
    /**
     This string summarizes the data frame.
     */
    public var debugDescription: String {
        let dateRangeString = "\n\t\(formattedStartDateTime)\n\t\t\tto\n\t\(formattedEndDateTime)"
        let returnStringArray = ["Columns:\n\t\(_Columns.allCases.map(\.localizedString).joined(separator: "\n\t"))",
                                 "Number Of Samples: \(count)",
                                 "Date Range: \(dateRangeString)"
        ]
        
        return returnStringArray.joined(separator: "\n\n")
    }
}

/* ###################################################################################################################################### */
// MARK: RandomAccessCollection Conformance
/* ###################################################################################################################################### */
extension RCVST_DataProvider: RandomAccessCollection {
    /* ################################################################## */
    /**
     This is pretty straightforward. We start at 0.
     */
    public var startIndex: Int { 0 }
    
    /* ################################################################## */
    /**
     The last index is the 0-based count (count - 1).
     */
    public var endIndex: Int { count - 1 }
}

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff For User Types -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################################################################################## */
    // MARK: This is used to define the types of users.
    /* ################################################################################################################################## */
    /**
     This enum defines the user types we provide separately.
     */
    enum UserTypes: String {
        /* ###################################################### */
        /**
         Active users (have logged in, at least once)
         */
        case active
        
        /* ###################################################### */
        /**
         New users (have never logged in)
         */
        case new

        /* ############################################################## */
        /**
         The column name, localized.
         */
        var localizedString: String { "SLUG-USER-COLUMN-NAME-\(rawValue)".localizedVariant }
    }
    
    /* ################################################################################################################################## */
    // MARK: A Single User Data Point
    /* ################################################################################################################################## */
    /**
     This struct is one data point (count of user types).
     */
    struct RowUserTypesPlottableData: Identifiable {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The type of user being tracked.
         */
        let userType: UserTypes

        /* ############################################################## */
        /**
         The number of users that fit this type.
         */
        let value: Int
        
        /* ############################################################## */
        /**
         A string that can be used as a legend key
         */
        var descriptionString: String {
            switch userType {
            case .active: return "SLUG-ACTIVE-LEGEND-LABEL".localizedVariant
            case .new: return "SLUG-NEW-LEGEND-LABEL".localizedVariant
            }
        }
    }
    
    /* ################################################################################################################################## */
    // MARK: A Collection of Data Points For One User Types Sample.
    /* ################################################################################################################################## */
    /**
     This provides user type totals for one date.
     */
    struct RowUserPlottableData: Identifiable, RCVST_DataProvider_ElementHasDate {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The date the sample was taken.
         */
        let date: Date

        /* ############################################################## */
        /**
         The totals of the types of users, for this sample.
         */
        var data: [RowUserTypesPlottableData]
        
        /* ############################################################## */
        /**
         Initializer
         
         - parameter date: The sample date. Optional. Default is .distantPast.
         - parameter data: The totals of the types of users. Optional. Default is an empty array.
         */
        init(date inDate: Date = .distantPast, data inData: [RowUserTypesPlottableData] = []) {
            date = inDate
            data = inData
        }
    }
    
    /* ############################################################## */
    /**
     This returns all the samples in a simplified manner for user types (new and active), suitable for plotting in a chart.
     */
    var userTypePlottable: [RowUserPlottableData] {
        var ret = [RowUserPlottableData]()
        
        let rows = allRows
        
        guard 1 < rows.count else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let dailySample = rows[index]
            let date = dailySample.date
            let activeUsers = RowUserTypesPlottableData(userType: .active, value: dailySample.activeUsers)
            let newUsers = RowUserTypesPlottableData(userType: .new, value: dailySample.newUsers)
            ret.append(RowUserPlottableData(date: date, data: [activeUsers, newUsers]))
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff For Signup Types -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################################################################################## */
    // MARK: This is used to define the types of signups, and their resolutions.
    /* ################################################################################################################################## */
    /**
     This enum defines the signup types we provide separately.
     */
    enum SignupTypes: String {
        /* ############################################################## */
        /**
         Signups that have been rejected.
         */
        case rejectedSignups
        
        /* ############################################################## */
        /**
         Signups that have been accepted.
         */
        case acceptedSignups

        /* ############################################################## */
        /**
         The column name, localized.
         */
        var localizedString: String { "SLUG-SIGNUP-COLUMN-NAME-\(rawValue)".localizedVariant }
    }
    
    /* ################################################################################################################################## */
    // MARK: A Single Signup Data Point
    /* ################################################################################################################################## */
    /**
     This struct is one data point (count of signup types).
     */
    struct RowSignupTypesPlottableData: Identifiable {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The type of signup being tracked.
         */
        let signupType: SignupTypes

        /* ############################################################## */
        /**
         The number of signups that fit this type.
         */
        let value: Int
        
        /* ############################################################## */
        /**
         A string that can be used as a legend key
         */
        var descriptionString: String {
            switch signupType {
            case .rejectedSignups: return "SLUG-REJECTED-SIGNUP-LEGEND-LABEL".localizedVariant
            case .acceptedSignups: return "SLUG-ACCEPTED-SIGNUP-LEGEND-LABEL".localizedVariant
            }
        }
    }
    
    /* ################################################################################################################################## */
    // MARK: A Collection of Data Points For One Signup Types Sample.
    /* ################################################################################################################################## */
    /**
     This provides signup type totals for one date.
     */
    struct RowSignupPlottableData: Identifiable, RCVST_DataProvider_ElementHasDate {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The date the sample was taken.
         */
        let date: Date

        /* ############################################################## */
        /**
         The totals of the types of signups, for this sample.
         */
        var data: [RowSignupTypesPlottableData]
        
        /* ############################################################## */
        /**
         Initializer
         
         - parameter date: The sample date. Optional. Default is .distantPast.
         - parameter data: The totals of the types of signups. Optional. Default is an empty array.
         */
        init(date inDate: Date = .distantPast, data inData: [RowSignupTypesPlottableData] = []) {
            date = inDate
            data = inData
        }
    }
    
    /* ############################################################## */
    /**
     This returns all the samples in a simplified manner for signup types, suitable for plotting in a chart.
     This combines two samples into one (we sample every twelve hours, so this makes it daily).
     */
    var signupTypePlottable: [RowSignupPlottableData] {
        var ret = [RowSignupPlottableData]()
        
        let rows = allRows
        
        guard 1 < rows.count else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let sample1 = rows[index - 1]
            let sample2 = rows[index]
            let date = sample2.date
            let sample1RejectedValue = sample1.newRejectedRequests
            let sample2RejectedValue = sample2.newRejectedRequests
            let sample1AcceptedValue = sample1.newAcceptedRequests
            let sample2AcceptedValue = sample2.newAcceptedRequests
            let rejectedSignups = RowSignupTypesPlottableData(signupType: .rejectedSignups, value: sample1RejectedValue + sample2RejectedValue)
            let acceptedSignups = RowSignupTypesPlottableData(signupType: .acceptedSignups, value: sample1AcceptedValue + sample2AcceptedValue)
            ret.append(RowSignupPlottableData(date: date, data: [acceptedSignups, rejectedSignups]))
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff For Account Deletion Types -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################################################################################## */
    // MARK: This is used to define the types of deletions.
    /* ################################################################################################################################## */
    /**
     This enum defines the delete types we provide separately.
     */
    enum DeletionTypes: String {
        /* ############################################################## */
        /**
         Deleted active accounts (usually for inactivity for a long time).
         */
        case deletedActive
        
        /* ############################################################## */
        /**
         Deleted inactive accounts (usually for inactivity for a long time).
         */
        case deletedInactive
        
        /* ############################################################## */
        /**
         Accounts that deleted themselves.
         */
        case selfDeleted

        /* ############################################################## */
        /**
         The column name, localized.
         */
        var localizedString: String { "SLUG-DELETED-COLUMN-NAME-\(rawValue)".localizedVariant }
    }
    
    /* ################################################################################################################################## */
    // MARK: A Single Deletion Data Point
    /* ################################################################################################################################## */
    /**
     This struct is one data point (count of deletion types).
     */
    struct RowDeleteTypesPlottableData: Identifiable {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The type of signup being tracked.
         */
        let deletionType: DeletionTypes

        /* ############################################################## */
        /**
         The number of signups that fit this type.
         */
        let value: Int
        
        /* ############################################################## */
        /**
         A string that can be used as a legend key
         */
        var descriptionString: String {
            switch deletionType {
            case .deletedActive: return "SLUG-DELETED-ACTIVE-LEGEND-LABEL".localizedVariant
            case .deletedInactive: return "SLUG-DELETED-INACTIVE-LEGEND-LABEL".localizedVariant
            case .selfDeleted: return "SLUG-DELETED-SELF-LEGEND-LABEL".localizedVariant
            }
        }
    }
    
    /* ################################################################################################################################## */
    // MARK: A Collection of Data Points For One Deletion Types Sample.
    /* ################################################################################################################################## */
    /**
     This provides deletion type totals for one date.
     */
    struct RowDeletePlottableData: Identifiable, RCVST_DataProvider_ElementHasDate {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The date the sample was taken.
         */
        let date: Date

        /* ############################################################## */
        /**
         The totals of the types of deletions, for this sample.
         */
        var data: [RowDeleteTypesPlottableData]
        
        /* ############################################################## */
        /**
         Initializer
         
         - parameter date: The sample date. Optional. Default is .distantPast.
         - parameter data: The totals of the types of deletions. Optional. Default is an empty array.
         */
        init(date inDate: Date = .distantPast, data inData: [RowDeleteTypesPlottableData] = []) {
            date = inDate
            data = inData
        }
    }
    
    /* ############################################################## */
    /**
     This returns all the samples in a simplified manner for countable deletion types, suitable for plotting in a chart.
     This combines two samples into one (we sample every twelve hours, so this makes it daily).
     */
    var deleteTypePlottable: [RowDeletePlottableData] {
        var ret = [RowDeletePlottableData]()
        
        let rows = allRows
        
        guard 1 < rows.count else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let sample1 = rows[index - 1]
            let sample2 = rows[index]
            let date = sample2.date
            let sample1ActiveValue = sample1.newDeletedActive
            let sample2ActiveValue = sample2.newDeletedActive
            let sample1InactiveValue = sample1.newDeletedInactive
            let sample2InactiveValue = sample2.newDeletedInactive
            let sample1SelfValue = sample1.newSelfDeleted
            let sample2SelfValue = sample2.newSelfDeleted
            let deletedActive = RowDeleteTypesPlottableData(deletionType: .deletedActive, value: sample1ActiveValue + sample2ActiveValue)
            let deletedInactive = RowDeleteTypesPlottableData(deletionType: .deletedInactive, value: sample1InactiveValue + sample2InactiveValue)
            let deletedSelf = RowDeleteTypesPlottableData(deletionType: .selfDeleted, value: sample1SelfValue + sample2SelfValue)
            ret.append(RowDeletePlottableData(date: date, data: [deletedActive, deletedInactive, deletedSelf]))
        }
        
        return ret
    }
}

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff For New First-Time Logins -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################################################################################## */
    // MARK: A Collection of Data Points For One Signup Types Sample.
    /* ################################################################################################################################## */
    /**
     This provides signup type totals for one date.
     */
    struct RowFirstTimeLoginsPlottableData: Identifiable, RCVST_DataProvider_ElementHasDate {
        /* ############################################################## */
        /**
         Make me identifiable.
         */
        public var id = UUID()

        /* ############################################################## */
        /**
         The date the sample was taken.
         */
        let date: Date

        /* ############################################################## */
        /**
         The total number of new first-time logins, for this sample.
         */
        var data: Int
        
        /* ############################################################## */
        /**
         Initializer
         
         - parameter date: The sample date. Optional. Default is .distantPast.
         - parameter data: The totals of the new first-time logins. Optional. Default is 0.
         */
        init(date inDate: Date = .distantPast, data inData: Int = 0) {
            date = inDate
            data = inData
        }
    }
    
    /* ############################################################## */
    /**
     This returns all the samples in a simplified manner for new first-time logins, suitable for plotting in a chart.
     This combines two samples into one (we sample every twelve hours, so this makes it daily).
     */
    var newLoginsPlottable: [RowFirstTimeLoginsPlottableData] {
        var ret = [RowFirstTimeLoginsPlottableData]()
        
        let rows = allRows
        
        guard 1 < rows.count else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let sample1 = rows[index - 1]
            let sample2 = rows[index]
            ret.append(RowFirstTimeLoginsPlottableData(date: sample2.date, data: sample1.newFirstTimeLogins + sample2.newFirstTimeLogins))
        }
        
        return ret
    }
}
