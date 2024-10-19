import SwiftUI
import TabularData

/* ###################################################################################################################################### */
// MARK: - Main App -
/* ###################################################################################################################################### */
/**
 This is the main stats viewr app.
 
 It is a class, to make setting up the data frame easier.
 */
@main
class RCVST_App: App {
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
     */
    required init() {
        fetchStats {
            self.statusDataFrame = $0
            #if DEBUG
                print("Stats Data: \(self.statusDataFrame.debugDescription)")
            #endif
        }
    }
    
    /* ################################################################## */
    /**
     */
    var body: some Scene {
        WindowGroup {
            RCVST_ContentView(dataFrame: self.statusDataFrame)
        }
    }
    
    /* ################################################################## */
    /**
     This fetches the current stats file, and delivers it as a dataframe.
     
     - parameter completion: A simple completion proc, with a single argument of dataframe, containing the stats. This can be called in non-main threads.
     */
    func fetchStats(completion inCompletion: ((DataFrame?) -> Void)?) {
        guard let url = URL(string: Self._g_statsURLString)
        else {
            inCompletion?(nil)
            return
        }
        
        do {    // We convert the integer timestamp to a more usable Date instance.
            var dataFrame = try DataFrame(contentsOfCSVFile: url)
            dataFrame.transformColumn("sample_date") { (inUnixTime: Int) -> Date in
                Date(timeIntervalSince1970: TimeInterval(inUnixTime))
            }
            
            inCompletion?(dataFrame)
        } catch {
            #if DEBUG
                print("Data Frame Initialization Error: \(error.localizedDescription)")
            #endif
            inCompletion?(nil)
        }
    }
}
