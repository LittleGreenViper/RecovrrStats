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
         */
        case sample_date

        /* ############################################################## */
        /**
         */
        case total_users

        /* ############################################################## */
        /**
         */
        case new_users

        /* ############################################################## */
        /**
         */
        case never_set_location

        /* ############################################################## */
        /**
         */
        case total_requests

        /* ############################################################## */
        /**
         */
        case accepted_requests

        /* ############################################################## */
        /**
         */
        case rejected_requests

        /* ############################################################## */
        /**
         */
        case open_requests

        /* ############################################################## */
        /**
         */
        case active_1

        /* ############################################################## */
        /**
         */
        case active_7

        /* ############################################################## */
        /**
         */
        case active_30

        /* ############################################################## */
        /**
         */
        case active_90

        /* ############################################################## */
        /**
         */
        case active_avg

        /* ############################################################## */
        /**
         */
        case deleted_active

        /* ############################################################## */
        /**
         */
        case deleted_inactive
        
        /* ############################################################## */
        /**
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
    var debugDescription: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        
        let dateRangeString = "\n\t" + dateFormatter.string(from: dateRange.lowerBound) + "\n\t\t\tto\n\t" + dateFormatter.string(from: dateRange.upperBound)
        let returnStringArray = ["Columns:\n\t\(Columns.allCases.map(\.localizedString).joined(separator: "\n\t"))",
                                 "Number Of Samples: \(numberOfRows)",
                                 "Date Range: \(dateRangeString)"
        ]
        
        return returnStringArray.joined(separator: "\n\n")
    }
}
