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
     The total number of samples.
     */
    var numberOfRows: Int { statusDataFrame?.rows.count ?? 0 }
    
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
     */
    var formattedStartDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: dateRange.lowerBound)
    }
    
    /* ################################################################## */
    /**
     */
    var formattedEndDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .none
        return dateFormatter.string(from: dateRange.upperBound)
    }
    
    /* ################################################################## */
    /**
     */
    var formattedStartDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: dateRange.lowerBound)
    }
    
    /* ################################################################## */
    /**
     */
    var formattedEndDateTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter.string(from: dateRange.upperBound)
    }

    /* ################################################################## */
    /**
     Upon initialization, we go out, and fetch the stats file.
     */
    required init() {
        fetchStats {
            guard let stats = $0 else { return }
            // We need to publish the change in the main thread.
            self.statusDataFrame = stats
        }
    }
    
    /* ################################################################## */
    /**
     This fetches the current stats file, and delivers it as a dataframe.
     
     - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats. This is always called in the main thread.
     */
    func fetchStats(completion inCompletion: ((DataFrame?) -> Void)?) {
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
                                 "Number Of Samples: \(numberOfRows)",
                                 "Date Range: \(dateRangeString)"
        ]
        
        return returnStringArray.joined(separator: "\n\n")
    }
}
