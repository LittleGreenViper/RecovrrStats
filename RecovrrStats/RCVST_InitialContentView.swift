/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Generic Data Display Module View -
/* ###################################################################################################################################### */
/**
 This allows us to "genericize" the view structs.
 */
protocol RCVST_DataDisplay: View {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    var data: RCVST_DataProvider? { get set }
    
    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     */
    var selectedValuesString: String { get set }
}

/* ###################################################################################################################################### */
// MARK: - Helps With Haptics -
/* ###################################################################################################################################### */
/**
 We declare this, to provide a default haptic implementation.
 */
protocol RCVST_HapticHopper {
    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging. REQUIRED
     */
    var hapticEngine: CHHapticEngine? { get }

    /* ################################################################## */
    /**
     This prepares our haptic engine. REQUIRED
     */
    func prepareHaptics()
    
    /* ################################################################## */
    /**
     This triggers the haptic. OPTIONAL
     
     - parameter intensity: The 0 -> 1 intensity, with 0, being off, and 1 being max. Optional for protocol default. Default is 0.25 (gentle selection).
     - parameter sharpness: The 0 -> 1 sharpness, with 0, being soft, and 1 being hard. Optional for protocol default. Default is 0 (soft).
     */
    func triggerHaptic(intensity: Float, sharpness: Float)
}

/* ###################################################################################################################################### */
// MARK: Defaults
/* ###################################################################################################################################### */
extension RCVST_HapticHopper {
    /* ################################################################## */
    /**
     This provides a basic haptic trigger function. Probably all we need.
     */
    func triggerHaptic(intensity inIntensity: Float = 0.25, sharpness inSharpness: Float = 0) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }
        var events = [CHHapticEvent]()

        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: inIntensity)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: inSharpness)
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        events.append(event)

        guard let pattern = try? CHHapticPattern(events: events, parameters: []),
              let player = try? hapticEngine?.makePlayer(with: pattern)
        else { return }
        
        try? player.start(atTime: 0)
    }
}

/* ###################################################################################################################################### */
// MARK: - This just means we use the data property -
/* ###################################################################################################################################### */
/**
 This simply requires that the implementation have a data paremeter, with our data provider type.
 */
protocol RCVST_UsesData {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    var data: RCVST_DataProvider? { get set }
}

/* ###################################################################################################################################### */
// MARK: - Initial View -
/* ###################################################################################################################################### */
/**
 */
struct RCVST_InitialContentView: View {
    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View { RootStackView() }
}

/* ###################################################################################################################################### */
// MARK: - The List of Charts -
/* ###################################################################################################################################### */
/**
 This presents a simple navigation list, with callouts to the various charts.
 */
struct RootStackView: View {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State private var _data: RCVST_DataProvider? = RCVST_DataProvider()

    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     The main navigation stack screen.
     */
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) { RCVST_Chart1View(title: "SLUG-USER-TOTALS-CHART-TITLE".localizedVariant, data: _data) }
                NavigationLink("SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant) { RCVST_Chart2View(title: "SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant, data: _data) }
                NavigationLink("SLUG-CHART-3-TITLE".localizedVariant) { RCVST_Chart3View(title: "SLUG-CHART-3-TITLE".localizedVariant, data: _data) }
                NavigationLink("SLUG-CHART-4-TITLE".localizedVariant) { RCVST_Chart4View(title: "SLUG-CHART-4-TITLE".localizedVariant, data: _data) }
            }
            .navigationTitle("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
            // Reacts to "pull to refresh," to reload the file.
            .refreshable {
                _data = RCVST_DataProvider()
            }
        }
        // Forces updates, whenever we become active.
        .onChange(of: _scenePhase, initial: true) {
            if .active == _scenePhase,
               nil == _data {
                _data = RCVST_DataProvider()
            } else if .background == _scenePhase {
                _data = nil
            }
        }
    }
}
