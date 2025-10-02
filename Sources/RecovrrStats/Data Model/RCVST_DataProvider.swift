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
// MARK: - Stats Data Provider -
/* ###################################################################################################################################### */
/**
 This class reads in and processes the stats data.
 */
public class RCVST_DataProvider {
    /* ################################################################################################################################## */
    // MARK: Column Name Enum
    /* ################################################################################################################################## */
    /**
     This provides enums for internal use.
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

    /* ##################################################### */
    /**
     This is the URI of our CSV stats file.
     */
    static let _g_statsURLString = "https://recovrr.org/recovrr/log/stats.csv"

    /* ##################################################### */
    /**
     This factory function will generate new model instances, and call a completion closure, after fetching the necessary data.

     - parameter inCompletion: A tail completion block, that receives a new model instance. This may be called in any thread.
     */
    static func factory(completion inCompletion: @escaping (_: RCVST_DataProvider?) -> Void) {
        /* ################################################################## */
        /**
         This fetches the current stats file, and delivers it as a dataframe.

         - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats.
         */
        func _fetchStats(completion inCompletion: ((DataFrame?) -> Void)?) {
            /* ############################################################## */
            /**
             Converts CSV data to a DataFrame.
             
             - parameter inData: The CSV data to be converted to a DataFrame
             */
            func handleCSVData(_ inData: Data) -> DataFrame? {
                if var dataFrame = try? DataFrame(csvData: inData) {
                    // We convert the integer timestamp to a more usable Date instance.
                    dataFrame.transformColumn(Columns.sample_date.rawValue) { (inUnixTime: Int) -> Date in Date(timeIntervalSince1970: TimeInterval(inUnixTime)) }
                    #if DEBUG
                        print("Data Frame Successful Initialization")
                    #endif
                    return dataFrame
                } else {
                    return nil
                }
            }
            
            if let url = URL(string: self._g_statsURLString) {
                let urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData)

                #if DEBUG
                    print("CSV URL Request: \(urlRequest.url?.absoluteString ?? "ERROR")")
                #endif
                
                URLSession.shared.dataTask(with: urlRequest) { inData, inResponse, error in
                    guard let response = inResponse as? HTTPURLResponse,
                          let data = inData,
                          nil == error,
                          !data.isEmpty
                    else {
                        #if DEBUG
                            print("Failed Initial Dataframe Setup")
                        #endif
                        inCompletion?(nil)
                        return
                    }
                    
                    switch response.statusCode {
                    case 200..<300:
                        if let dataFrame = handleCSVData(data) {
                            inCompletion?(dataFrame)
                        } else {
                            #if DEBUG
                                print("Data Frame Failed Initialization")
                            #endif
                            inCompletion?(nil)
                        }

                    default:
                        #if DEBUG
                            print("Data Frame Load Returned Status Code \(response.statusCode)")
                        #endif
                        inCompletion?(nil)
                    }
                }.resume()
            } else {
                #if DEBUG
                    print("Unknown State. No URL")
                #endif
                inCompletion?(nil)
            }
        }
        
        _fetchStats { inDataFrame in
            if let dataFrame = inDataFrame {
                inCompletion(RCVST_DataProvider(statusDataFrame: dataFrame))
            } else {
                inCompletion(nil)
            }
        }
    }
    
    /* ################################################################## */
    /**
     I don't like singletons, but this seems to be the best way to deal with the need for a common window range.
     
     We'll set this, whenever we set the window range, and then read it back. That ensures that all the data providers have the same window range.
     */
    static var singletonWindowRange: ClosedRange<Date> = .distantPast ... .distantPast
    
    /* ################################################################## */
    /**
     This has the total range.
     */
    static var singletonTotalWindowRange: ClosedRange<Date> = .distantPast ... .distantPast

    /* ################################################################## */
    /**
     This is used to access the observable object.
     
     It is implicit, because Bad Things Happen, if not available.
     */
    static var shared: RCVST_DataProvider!
    
    /* ################################################################## */
    /**
     This finds the last index of the main dataframe rows, based on our endDate.
     */
    private var _lastIndex: Int {
        for item in self.statusDataFrame.rows.enumerated() where (item.element["sample_date"] as? Date ?? .now) > self.endDate {
            return max(0, item.offset - 1)
        }
        
        return self.statusDataFrame.rows.count - 1
    }
    
    /* ################################################################## */
    /**
     This "slices" the dataframe rows, to include any end date.
     */
    private var _rows: DataFrame.Rows {
        let subset = self.statusDataFrame.prefix(self._lastIndex)
        return DataFrame(subset).rows
    }

    /* ################################################################## */
    /**
     Returns true, if the last sample was a full day (at noon). We do two samples per day.
     */
    var lastSampleWasNoon: Bool { 0 == self.statusDataFrame.rows.count % 2 }
    
    /* ################################################################## */
    /**
     This is the "start date" of the dataframe.
     */
    var startDate: Date { self.statusDataFrame.rows.first?["sample_date"] as? Date ?? .now }

    /* ################################################################## */
    /**
     This is the "end date" of the dataframe.
     */
    var endDate: Date { self.statusDataFrame.rows.last?["sample_date"] as? Date ?? .now }

    /* ################################################################## */
    /**
     This is the total date range of the sample set.
     */
    var dateRange: ClosedRange<Date> { return self.startDate...self.endDate }
    
    /* ################################################################## */
    /**
     This stores the dataframe info.
     */
    var numberOfDays: Int { return (self._rows.count + 1) / 2 }

    /* ################################################################## */
    /**
     This stores the dataframe info.
     */
    var statusDataFrame: DataFrame

    /* ################################################################## */
    /**
     A data provider instance, tuned to user types.
     */
    var userDataProvider: RCVST_UserTypesDataProvider?
    
    /* ################################################################## */
    /**
     A data provider instance, tuned to signup resolutions.
     */
    var signupsDataProvider: RCVST_SignupsDataProvider?
    
    /* ################################################################## */
    /**
     A data provider instance, tuned to deletions.
     */
    var deletionsDataProvider: RCVST_DeletionsDataProvider?
    
    /* ################################################################## */
    /**
     A data provider instance, tuned to users active within the last 24 hours.
     */
    var active1DataProvider: RCVST_UserActivityDataProvider?
    
    /* ################################################################## */
    /**
     A data provider instance, tuned to users active within the last week.
     */
    var active7DataProvider: RCVST_UserActivityDataProvider?
    
    /* ################################################################## */
    /**
     A data provider instance, tuned to users active within the last 30 days.
     */
    var active30DataProvider: RCVST_UserActivityDataProvider?
    
    /* ################################################################## */
    /**
     A data provider instance, tuned to users active within the last 90 days.
     */
    var active90DataProvider: RCVST_UserActivityDataProvider?
    
    /* ################################################################## */
    /**
     Default initializer. We set up our data providers, here.
     
     - parameter inDataFrame: The actual data frame that was fetched and intialized, from the CSV data.
     */
    init(statusDataFrame inDataFrame: DataFrame) {
        self.statusDataFrame = inDataFrame
        self.userDataProvider = RCVST_UserTypesDataProvider(with: inDataFrame, chartName: "SLUG-USER-TOTALS-CHART-TITLE".localizedVariant)
        self.signupsDataProvider = RCVST_SignupsDataProvider(with: inDataFrame, chartName: "SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant)
        self.deletionsDataProvider = RCVST_DeletionsDataProvider(with: inDataFrame, chartName: "SLUG-CHART-4-TITLE".localizedVariant)
        self.active1DataProvider = RCVST_UserActivityDataProvider(with: inDataFrame, days: 1)
        self.active7DataProvider = RCVST_UserActivityDataProvider(with: inDataFrame, days: 7)
        self.active30DataProvider = RCVST_UserActivityDataProvider(with: inDataFrame, days: 30)
        self.active90DataProvider = RCVST_UserActivityDataProvider(with: inDataFrame, days: 90)
        
        Self.shared = self
    }
    
    /* ################################################################## */
    /**
     This is the total number of active users, at the end of the sample
     */
    var totalUsers: Int { self._rows.last?["total_users"] as? Int ?? 0 }
    
    /* ################################################################## */
    /**
     This is the total number of active users, at the end of the sample
     */
    var totalActive: Int { self.totalUsers - totalInactive }

    /* ################################################################## */
    /**
     This is the total number of inactive users, at the end of the sample
     */
    var totalInactive: Int { self._rows.last?["new_users"] as? Int ?? 0 }

    /* ################################################################## */
    /**
     This is the total number of signup requests, since the start of data.
     */
    var totalRequests: Int { self._rows.last?["total_requests"] as? Int ?? 0 }

    /* ################################################################## */
    /**
     This is the total number of accepted signup requests, since the start of data.
     */
    var totalApprovals: Int { self._rows.last?["accepted_requests"] as? Int ?? 0 }
    
    /* ################################################################## */
    /**
     This is the total number of rejected signup requests, since the start of data.
     */
    var totalRejections: Int { self._rows.last?["rejected_requests"] as? Int ?? 0 }
    
    /* ################################################################## */
    /**
     The total number of admin deleted active accounts, since the start of data.
     */
    var totalAdminActiveDeleted: Int { (self._rows.last?["deleted_active"] as? Int ?? 0) }
    
    /* ################################################################## */
    /**
     The total number of admin deleted inactive accounts, since the start of data.
     */
    var totalAdminInactiveDeleted: Int { (self._rows.last?["deleted_inactive"] as? Int ?? 0) }
    
    /* ################################################################## */
    /**
     The total number of admin deleted accounts, since the start of data.
     */
    var totalAdminDeleted: Int { self.totalAdminActiveDeleted + self.totalAdminInactiveDeleted }

    /* ################################################################## */
    /**
     The average number of signups per day (simple average), since the start of data
     */
    var averageSignupsPerDay: Double { Double(self.totalRequests) / (Double(self._rows.count) / 2) }
    
    /* ################################################################## */
    /**
     The average number of rejected signups per day (simple average), since the start of data
     */
    var averageRejectedSignupsPerDay: Double { Double(self.totalRejections) / (Double(self._rows.count) / 2) }
    
    /* ################################################################## */
    /**
     The average number of rejected signups per day (simple average), since the start of data
     */
    var averageAcceptedSignupsPerDay: Double { Double(self.totalApprovals) / (Double(self._rows.count) / 2) }
    
    /* ################################################################## */
    /**
     The average number of deletions (both active and inactive) per day (simple average), since the start of data
     */
    var averageDeletionsPerDay: Double { Double(self.totalAdminDeleted) / (Double(self._rows.count) / 2) }
    
    /* ################################################################## */
    /**
     The average "growth" per day, since the start of the data.
     */
    var averageGrowthPerDay: Double { self.averageAcceptedSignupsPerDay - self.averageDeletionsPerDay }
}

/* ###################################################################################################################################### */
// MARK: Hashable and Equatable Conformance
/* ###################################################################################################################################### */
extension RCVST_DataProvider: Hashable {
    /* ################################################################## */
    /**
     Equatable Conformance
     
     - parameter lhs: The lafthand side
     - parameter rhs: The righthand side
     - returns: True, if the two match.
     */
    public static func == (lhs: RCVST_DataProvider, rhs: RCVST_DataProvider) -> Bool { ObjectIdentifier(lhs) == ObjectIdentifier(rhs) }
    
    /* ################################################################## */
    /**
     Hashable Conformance
     
     parameter inOutHasher: The customer for our hash dealer.
     */
    public func hash(into inOutHasher: inout Hasher) { inOutHasher.combine(ObjectIdentifier(self)) }
}
