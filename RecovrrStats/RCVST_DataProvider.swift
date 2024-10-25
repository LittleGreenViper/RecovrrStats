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
class RCVST_DataProvider: ObservableObject {
    /* ################################################################################################################################## */
    // MARK: Column Identifier Enum
    /* ################################################################################################################################## */
    /**
     This enum provides the column name strings.
     */
    enum Columns: String, CaseIterable {
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
        _fetchStats {
            guard let stats = $0 else { return }
            // We need to publish the change in the main thread.
            self.statusDataFrame = stats
        }
    }
}

/* ###################################################################################################################################### */
// MARK: The Data Row Nested Class
/* ###################################################################################################################################### */
extension RCVST_DataProvider {
    struct Row {
        // MARK: Stored Properties
        
        /* ############################################################## */
        /**
         The main data container that "owns" this row.
         */
        weak var dataProvider: RCVST_DataProvider?
        
        /* ############################################################## */
        /**
         The 0-based row index for this row. This is against the total rows in the data provider, not a subset.
         */
        let rowIndex: Int
        
        // MARK: Previous Sample Access
        
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

        // MARK: Raw Data
        
        /* ############################################################## */
        /**
         The date the sample was taken. Nil, if error.
         */
        var sampleDate: Date? { _rowData?[0] as? Date }
        
        /* ############################################################## */
        /**
         The total number of users (both active and inactive), at the time the sample was taken.
         */
        var totalUsers: Int { _rowData?[1] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The total number of new (inactive) users, at the time the sample was taken.
         */
        var newUsers: Int { _rowData?[2] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of users (both active and new), that have a nil location (never set one).
         */
        var neverSetLocation: Int { _rowData?[3] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests.
         */
        var totalRequests: Int { _rowData?[4] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests approved by the administrators.
         */
        var acceptedRequests: Int { _rowData?[5] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative total number of signup requests rejected by the administrators.
         */
        var rejectedRequests: Int { _rowData?[6] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of signup requests that have not been addressed by the administrators.
         */
        var openRequests: Int { _rowData?[7] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 24 hours.
         */
        var activeInLast24Hours: Int { _rowData?[8] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 7 days.
         */
        var activeInLastWeek: Int { _rowData?[9] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 30 days.
         */
        var activeInLast30Days: Int { _rowData?[10] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current number of active (not new) users that have signed in, within the last 90 days.
         */
        var activeInLast90Days: Int { _rowData?[11] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The current simple average last activity period for all active users, in days.
         */
        var averageLastActiveInDays: Int { _rowData?[12] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of active users that have been deleted by the administrators.
         */
        var deletedActive: Int { _rowData?[13] as? Int ?? 0 }

        /* ############################################################## */
        /**
         The cumulative number of new users that have been deleted by the administrators.
         */
        var deletedInactive: Int { _rowData?[14] as? Int ?? 0 }

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
        var changeInTotalUsers: Int { totalUsers - _previousTotalUsers }

        /* ############################################################## */
        /**
         The change in the total number of inactive users. Positive is users added, negative is users removed.
         */
        var changeInNewUsers: Int { newUsers - _previousNewUsers }

        /* ############################################################## */
        /**
         The change in the total number of inactive users. Positive is users added, negative is users removed.
         */
        var changeInActiveUsers: Int { activeUsers - _previousActiveUsers }

        /* ############################################################## */
        /**
         The change in the number of users (both active and new), that have a nil location.
         */
        var changeInNeverSetLocation: Int { neverSetLocation - _previousNeverSetLocation }

        /* ############################################################## */
        /**
         The number of signup requests since the last sample.
         */
        var newRequests: Int { totalRequests - _previousTotalRequests }

        /* ############################################################## */
        /**
         The number of signup requests approved by the administrators since the last sample.
         */
        var newAcceptedRequests: Int { acceptedRequests - _previousAcceptedRequests }

        /* ############################################################## */
        /**
         The number of signup requests rejected by the administrators since the last sample.
         */
        var newRejectedRequests: Int { rejectedRequests - _previousRejectedRequests }

        /* ############################################################## */
        /**
         The number of active users deleted by the administrators since the last sample.
         */
        var newDeletedActive: Int { deletedActive - _previousDeletedActive }

        /* ############################################################## */
        /**
         The number of inactive users deleted by the administrators since the last sample.
         */
        var newDeletedInactive: Int { deletedInactive - _previousDeletedInactive }

        /* ############################################################## */
        /**
         The number of users that have deleted themselves (as opposed to being deleted by admins), since the last sample.
         */
        var newSelfDeletedActive: Int { max (0, changeInActiveUsers - newDeletedActive) }
    }
}

/* ###################################################################################################################################### */
// MARK: Computed Properties
/* ###################################################################################################################################### */
extension RCVST_DataProvider {
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
        let startDate = statusDataFrame?.rows.first?[Columns.sample_date.rawValue] as? Date ?? Date()
        let endDate = statusDataFrame?.rows.last?[Columns.sample_date.rawValue] as? Date ?? Date()
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
     This simply access a single row by its 0-based index.
     
     - parameter inIndex: The 0-based row index (0..<count)
     
     - returns: An instance of Row, set up to access that row's data.
     */
    subscript(_ inIndex: Int) -> Row { Row(dataProvider: self, rowIndex: inIndex) }
    
    /* ################################################################## */
    /**
     This returns all the samples between two dates.
     
     - parameter startDate: The first date (inclusive)
     - parameter endDate: The last date (inclusive). Optional. If not provided, then we assume today.
     
     - returns: An array of Row instances, with the filtered rows. They are ordered from earliest to latest.
     */
    func rows(startDate inStartDate: Date, endDate inEndDate: Date = .now) -> [Row] {
        guard inEndDate > inStartDate,
              dateRange.contains(inStartDate),
              dateRange.contains(inEndDate),
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
                dataFrame.transformColumn(Columns.sample_date.rawValue) { (inUnixTime: Int) -> Date in Date(timeIntervalSince1970: TimeInterval(inUnixTime)) }
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
// MARK: CustomDebugStringConvertible Conformance
/* ###################################################################################################################################### */
extension RCVST_DataProvider: CustomDebugStringConvertible {
    /* ################################################################## */
    /**
     This string summarizes the data frame.
     */
    var debugDescription: String {
        let dateRangeString = "\n\t\(formattedStartDateTime)\n\t\t\tto\n\t\(formattedEndDateTime)"
        let returnStringArray = ["Columns:\n\t\(Columns.allCases.map(\.localizedString).joined(separator: "\n\t"))",
                                 "Number Of Samples: \(count)",
                                 "Date Range: \(dateRangeString)"
        ]
        
        return returnStringArray.joined(separator: "\n\n")
    }
}
