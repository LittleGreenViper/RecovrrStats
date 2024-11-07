/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

/* ###################################################################################################################################### */
// MARK: - Array Extension For Arrays of Rows -
/* ###################################################################################################################################### */
extension Array where Element == RCVST_DataProvider.Row {
    /* ################################################################## */
    /**
     This returns the sample closest to the given date.
     
     - parameter inDate: The date we want to compare against.
     
     - returns: The sample that is closest to (above or below) the given date.
     */
    func nearestTo(_ inDate: Date) -> RCVST_DataProvider.Row? {
        var ret: RCVST_DataProvider.Row?
        
        forEach {
            guard let currentDate = $0.sampleDate,
                  let compDate = ret?.sampleDate
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
public class RCVST_DataProvider: ObservableObject {
    /* ################################################################## */
    /**
     The URL string to the stats file.
     */
    private static let _g_statsURLString = "https://recovrr.org/recovrr/log/stats.csv"
    
    /* ################################################################## */
    /**
     This stores the dataframe info.
     */
    @Published var statusDataFrame: DataFrame?

    /* ################################################################## */
    /**
     Upon initialization, we go out, and fetch the stats file.
     */
    required init() {
        _fetchStats { inResults in DispatchQueue.main.async { self.statusDataFrame = inResults } }
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
     
     - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats.
     */
    private func _fetchStats(completion inCompletion: ((DataFrame?) -> Void)?) {
        // We don't need to do this in the main thread.
        DispatchQueue.global().async {
            guard let url = URL(string: Self._g_statsURLString)
            else {
                inCompletion?(nil)
                return
            }
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
        }
    }
}

/* ###################################################################################################################################### */
// MARK: The Public Data Row Nested Class
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /// This provides a simple interface to the data for each row.
    struct Row: Identifiable {
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
        private var _previousTotalUsers: Int { _previousRowData?[1] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of new (inactive) users, for the previous sample.
         */
        private var _previousNewUsers: Int { _previousRowData?[2] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of active users, for the previous sample.
         */
        private var _previousActiveUsers: Int { _previousTotalUsers - _previousNewUsers }

        /* ############################################################## */
        /**
         The current number of users (both active and new), for the previous sample.
         */
        private var _previousNeverSetLocation: Int { _previousRowData?[3] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests, for the previous sample.
         */
        private var _previousTotalRequests: Int { _previousRowData?[4] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests approved by the administrators, for the previous sample.
         */
        private var _previousAcceptedRequests: Int { _previousRowData?[5] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests rejected by the administrators, for the previous sample.
         */
        private var _previousRejectedRequests: Int { _previousRowData?[6] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of active users that have been deleted by the administrators, for the previous sample.
         */
        private var _previousDeletedActive: Int { _previousRowData?[13] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of new users that have been deleted by the administrators, for the previous sample.
         */
        private var _previousDeletedInactive: Int { _previousRowData?[14] as? Int ?? 0 }

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
         The date the sample was taken. Nil, if error.
         */
        public var sampleDate: Date? { _rowData?[0] as? Date }
        
        /* ############################################################## */
        /**
         The total number of users (both active and inactive), at the time the sample was taken.
         */
        public var totalUsers: Int { _rowData?[1] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of new (inactive) users, at the time the sample was taken.
         */
        public var newUsers: Int { _rowData?[2] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of users (both active and new), that have a nil location (never set one).
         */
        public var neverSetLocation: Int { _rowData?[3] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests.
         */
        public var totalRequests: Int { _rowData?[4] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests approved by the administrators.
         */
        public var acceptedRequests: Int { _rowData?[5] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests rejected by the administrators.
         */
        public var rejectedRequests: Int { _rowData?[6] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of signup requests that have not been addressed by the administrators.
         */
        public var openRequests: Int { _rowData?[7] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 24 hours.
         */
        public var activeInLast24Hours: Int { _rowData?[8] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 7 days.
         */
        public var activeInLastWeek: Int { _rowData?[9] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 30 days.
         */
        public var activeInLast30Days: Int { _rowData?[10] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 90 days.
         */
        public var activeInLast90Days: Int { _rowData?[11] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current simple average last activity period for all active users, in days.
         */
        public var averageLastActiveInDays: Int { _rowData?[12] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of active users that have been deleted by the administrators.
         */
        public var deletedActive: Int { _rowData?[13] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of new users that have been deleted by the administrators.
         */
        public var deletedInactive: Int { _rowData?[14] as? Int ?? 0 }

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
        public var changeInNeverSetLocation: Int { neverSetLocation - _previousNeverSetLocation }

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
        let startDate = statusDataFrame?.rows.first?[_Columns.sample_date.rawValue] as? Date ?? .now
        let endDate = statusDataFrame?.rows.last?[_Columns.sample_date.rawValue] as? Date ?? .now
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
     
     - parameter startDate: The first date (inclusive). Optional. If not provided, then all rows until `endDate` will be returned.
     - parameter endDate: The last date (inclusive). Optional. If not provided, then we assume everything until the last.
     
     - returns: An array of Row instances, with the filtered rows. They are ordered from earliest to latest.
     */
    func rows(startDate inStartDate: Date = .distantPast, endDate inEndDate: Date = .distantFuture) -> [Row] {
        guard inEndDate >= inStartDate,
              let dataFrameRows = statusDataFrame?.rows,
              !dataFrameRows.isEmpty
        else { return [] }
        
        let filterRange = inStartDate...inEndDate
        var ret = [Row]()
        var index = 0
        
        dataFrameRows.forEach { inRow in
            if let date = inRow[0] as? Date,
               filterRange.contains(date) {
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
    struct RowUserPlottableData: Identifiable {
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
        
        guard !rows.isEmpty else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let dailySample = rows[index]
            guard let date = dailySample.sampleDate else { break }
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
    struct RowSignupPlottableData: Identifiable {
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
        
        guard !rows.isEmpty else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let sample1 = rows[index - 1]
            let sample2 = rows[index]
            guard let date = sample1.sampleDate else { break }
            let rejectedSignups = RowSignupTypesPlottableData(signupType: .rejectedSignups, value: sample1.newRejectedRequests + sample2.newRejectedRequests)
            let acceptedSignups = RowSignupTypesPlottableData(signupType: .acceptedSignups, value: sample1.newAcceptedRequests + sample2.newAcceptedRequests)
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
    // MARK: A Single Signup Data Point
    /* ################################################################################################################################## */
    /**
     This struct is one data point (count of signup types).
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
    // MARK: A Collection of Data Points For One Signup Types Sample.
    /* ################################################################################################################################## */
    /**
     This provides signup type totals for one date.
     */
    struct RowDeletePlottableData: Identifiable {
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
        
        guard !rows.isEmpty else { return ret }

        for index in stride(from: 1, to: rows.count, by: 2) {
            let sample1 = rows[index - 1]
            let sample2 = rows[index]
            guard let date = sample1.sampleDate else { break }
            let deletedActive = RowDeleteTypesPlottableData(deletionType: .deletedActive, value: sample1.newDeletedActive + sample2.newDeletedActive)
            let deletedInactive = RowDeleteTypesPlottableData(deletionType: .deletedInactive, value: sample1.newDeletedInactive + sample2.newDeletedInactive)
            ret.append(RowDeletePlottableData(date: date, data: [deletedActive, deletedInactive]))
        }
        
        return ret
    }
}
