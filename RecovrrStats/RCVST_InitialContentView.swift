/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import TabularData
import CoreHaptics

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
     
     - parameter intensity: The 0 -> 1 intensity, with 0, being off, and 1 being max. Optional. Default is 0.25 (gentle selection).
     - parameter intensity: The 0 -> 1 sharpness, with 0, being soft, and 1 being hard. Optional. Default is 0 (very soft).
     */
    func triggerHaptic(intensity: Float, sharpness: Float)
}

/* ###################################################################################################################################### */
// MARK: Defaults
/* ###################################################################################################################################### */
extension RCVST_HapticHopper {
    /* ################################################################## */
    /**
     We add defaults, here.
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
     This is the actual dataframe wrapper for the stats.
     */
    @ObservedObject var data = RCVST_DataProvider()

    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        RootStackView(data: data)
    }
}

/* ###################################################################################################################################### */
// MARK: - The List of Charts -
/* ###################################################################################################################################### */
/**
 
 */
struct RootStackView: View, RCVST_UsesData {
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @State var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     */
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("SLUG-USER-TOTALS-CHART-TITLE".localizedVariant) { RCVST_Chart1View(data: data) }
                NavigationLink("SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant) { RCVST_Chart2View(data: data) }
                NavigationLink("SLUG-CHART-3-TITLE".localizedVariant) { RCVST_Chart3View(data: data) }
            }
            .navigationTitle("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
        }
    }
}
