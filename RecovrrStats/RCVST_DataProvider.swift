/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

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
    @Published var statusDataFrame: DataFrame? {
        didSet {
            #if DEBUG
                print(debugDescription)
            #endif
        }
    }

    /* ################################################################## */
    /**
     Upon initialization, we go out, and fetch the stats file.
     */
    required init() {
        _fetchStats {
            guard let stats = $0 else { return }
            // We need to publish the change in the main thread.
            self.statusDataFrame = stats
        }
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
     
     - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats. This is always called in the main thread.
     */
    private func _fetchStats(completion inCompletion: ((DataFrame?) -> Void)?) {
        guard let url = URL(string: Self._g_statsURLString)
        else {
            inCompletion?(nil)
            return
        }
        // We don't need to do this in the main thread.
        DispatchQueue.global().async {
            do {
                var dataFrame = try DataFrame(contentsOfCSVFile: url)
                // We convert the integer timestamp to a more usable Date instance.
                dataFrame.transformColumn(_Columns.sample_date.rawValue) { (inUnixTime: Int) -> Date in Date(timeIntervalSince1970: TimeInterval(inUnixTime)) }
                #if DEBUG
                    print("Data Frame Successfully Initialized: \(dataFrame.debugDescription)")
                #endif
                DispatchQueue.main.async { inCompletion?(dataFrame) }
            } catch {
                #if DEBUG
                    print("Data Frame Initialization Error: \(error.localizedDescription)")
                #endif
                DispatchQueue.main.async { inCompletion?(nil) }
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: The Public Data Row Nested Class
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /// This provides a simple interface to the data for each row.
    struct Row {
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
        public var changeInTotalUsers: Int { totalUsers - _previousTotalUsers }

        /* ############################################################## */
        /**
         The change in the total number of inactive users. Positive is users added, negative is users removed.
         */
        public var changeInNewUsers: Int { newUsers - _previousNewUsers }

        /* ############################################################## */
        /**
         The change in the total number of inactive users. Positive is users added, negative is users removed.
         */
        public var changeInActiveUsers: Int { activeUsers - _previousActiveUsers }

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

        /* ############################################################## */
        /**
         The number of users that have deleted themselves (as opposed to being deleted by admins), since the last sample.
         */
        public var newSelfDeletedActive: Int { Swift.max(0, changeInActiveUsers - newDeletedActive) }
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
     */
    public var startIndex: Int { 0 }
    
    /* ################################################################## */
    /**
     */
    public var endIndex: Int { count - 1 }
}

/* ###################################################################################################################################### */
// MARK: - Adds Chart Plottable Stuff -
/* ###################################################################################################################################### */
public extension RCVST_DataProvider {
    /* ################################################################## */
    /**
     */
    struct RowUserTypesPlottableData: Identifiable {
        public var id = UUID()
        let userType: UserTypes
        let value: Int
    }
    
    /* ################################################################## */
    /**
     */
    struct RowPlottableData: Identifiable {
        public var id = UUID()
        let date: Date
        let data: [RowUserTypesPlottableData]
    }
    
    /* ################################################################################################################################## */
    // MARK: This is used to define the types of users.
    /* ################################################################################################################################## */
    /**
     This enum defines the user types we provide separately.
     */
    enum UserTypes: String {
        /* ###################################################### */
        /**
         Active users (have lkogged in, at least once)
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

    /* ############################################################## */
    /**
     */
    var userTypePlottable: [RowPlottableData] {
        var ret: [RowPlottableData] = allRows.compactMap { inRow in
            guard let date = inRow.sampleDate else { return nil }
            let activeUsers = RowUserTypesPlottableData(userType: .active, value: inRow.activeUsers)
            let newUsers = RowUserTypesPlottableData(userType: .new, value: inRow.newUsers)
            return RowPlottableData(date: date, data: [activeUsers, newUsers])
        }
        
        // This forces the bar chart to give more breathing room to the axis labels.
        if let first = ret.first?.date.addingTimeInterval(-43200),
           let last = ret.last?.date.addingTimeInterval(43200) {
            ret.insert(RCVST_DataProvider.RowPlottableData(date: first, data: []), at: 0)
            ret.append(RCVST_DataProvider.RowPlottableData(date: last, data: []))
        }

        return ret
    }
}
