import SwiftUI
import TabularData

/* ###################################################################################################################################### */
// MARK: - Stats Data Provider -
/* ###################################################################################################################################### */
/**
 This class reads in and processes the stats data.
 */
class RCVST_DataProvider: ObservableObject {
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
        fetchStats {
            guard let stats = $0 else { return }
            // We need to publish the change in the main thread.
            DispatchQueue.main.async { self.statusDataFrame = stats }
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
        // We don't need to do this in the main thread.
        DispatchQueue.global().async {
            do {
                var dataFrame = try DataFrame(contentsOfCSVFile: url)
                // We convert the integer timestamp to a more usable Date instance.
                dataFrame.transformColumn("sample_date") { (inUnixTime: Int) -> Date in Date(timeIntervalSince1970: TimeInterval(inUnixTime)) }
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
// MARK: CustomDebugStringConvertible Conformance
/* ###################################################################################################################################### */
extension RCVST_DataProvider: CustomDebugStringConvertible {
    var debugDescription: String {
        statusDataFrame?.columns.count.description ?? "ERROR"
    }
}
