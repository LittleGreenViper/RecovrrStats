import SwiftUI
import TabularData

@main
struct RCVST_App: App {
    private static let _g_statsURLString = "https://recovrr.org/recovrr/log/stats.csv"

    var body: some Scene {
        WindowGroup {
            RCVST_ContentView()
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
        
        do {
            var dataFrame = try DataFrame(contentsOfCSVFile: url)
            dataFrame.transformColumn("sample_date") { (inUnixTime: Int) -> Date in
                Date(timeIntervalSince1970: TimeInterval(inUnixTime))
            }
            
            #if DEBUG
                print("Stats Data: \(dataFrame.debugDescription)")
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
