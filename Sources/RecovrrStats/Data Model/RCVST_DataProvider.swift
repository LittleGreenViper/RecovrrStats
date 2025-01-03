/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import RVS_Generic_Swift_Toolbox

class RCVST_UserDataProvider: RCV_BaseDataProvider {
    /* ##################################################### */
    /**
     */
    var dataFrame: DataFrame?
    
    class _RCVST_UserDataRow: RCVST_Row {
        /* ############################################# */
        /**
         */
        override var plottableData: [any RCVS_DataSourceProtocol] {
            get {
                [
                    RCVST_Row._RCVST_UserDataPlottableData(description: "Active Users", color: .green, value: activeUsers, isSelected: isSelected),
                    RCVST_Row._RCVST_UserDataPlottableData(description: "New Users", color: .blue, value: newUsers, isSelected: isSelected)
                ]
            }
            
            set { _ = newValue }
        }
    }
    
    init(with inDataFrame: DataFrame) {
        var rowTypes = [_RCVST_UserDataRow]()
    
        for index in 0..<inDataFrame.rows.count {
            let row = inDataFrame.rows[index]
            let previousRow = 0 < index ? inDataFrame.rows[index - 1] : nil
            rowTypes.append(_RCVST_UserDataRow(dataRow: row, previousDataRow: previousRow))
        }

        super.init(rows: rowTypes, chartName: "User Types")
        dataFrame = inDataFrame
    }
}

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
     */
    static func factory(useDummyData inUseDummyData: Bool = false, completion inCompletion: @escaping (_: RCVST_DataProvider?) -> Void) {
        let _g_statsURLString = "https://recovrr.org/recovrr/log/stats.csv"

        let _g_mockData = """
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
         This fetches the current stats file, and delivers it as a dataframe.
         
         - parameter useMockData: If true, then we load mock data, instead of the actual file.
         - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats.
         */
        func _fetchStats(useMockData inUseMockData: Bool, completion inCompletion: ((DataFrame?) -> Void)?) {
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
            
            if inUseMockData,
               let data = _g_mockData,
               !data.isEmpty {
                #if DEBUG
                    print("Loading Mock CSV Data")
                #endif
                if let dataFrame = handleCSVData(data) {
                    inCompletion?(dataFrame)
                } else {
                    #if DEBUG
                        print("Data Frame Failed Mock Initialization")
                    #endif
                    inCompletion?(nil)
                }
            } else if let url = URL(string: _g_statsURLString) {
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
                    print("Unknown State. No Mock Data, No URL")
                #endif
                inCompletion?(nil)
            }
        }
        
        _fetchStats(useMockData: inUseDummyData) { inDataFrame in
            if let dataFrame = inDataFrame {
                inCompletion(RCVST_DataProvider(statusDataFrame: dataFrame))
            } else {
                inCompletion(nil)
            }
        }
    }

    /* ################################################################## */
    /**
     This stores the dataframe info.
     */
    var statusDataFrame: DataFrame

    /* ################################################################## */
    /**
     */
    init(statusDataFrame inDataFrame: DataFrame) {
        statusDataFrame = inDataFrame
    }
}
