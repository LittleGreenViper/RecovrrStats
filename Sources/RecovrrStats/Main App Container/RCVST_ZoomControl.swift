/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Pinch To Zoom Area -
/* ###################################################################################################################################### */
/**
 This is a control that integrates with the chart, and allows the user to pinch to magnify into the chart.
 */
struct RCVST_ZoomControl: View, RCVST_HapticHopper {
    /* ################################################################## */
    /**
     This is our haptic engine, used to provide feedback.
     */
    @State var hapticEngine: CHHapticEngine?

    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @Binding var data: DataProviderProtocol

    /* ################################################################## */
    /**
     The control, itself.
     */
    var body: some View {
        ViewThatFits(in: .horizontal) {
            ZStack {
                GeometryReader { inGeometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                    if !data.isMaxed {
                        let width = abs(data.dataWindowRange.upperBound.distance(to: data.dataWindowRange.lowerBound) / data.totalDateRange.upperBound.distance(to: data.totalDateRange.lowerBound) * inGeometry.size.width)
                        let leftPosition = abs(data.totalDateRange.lowerBound.distance(to: data.dataWindowRange.lowerBound) / data.totalDateRange.upperBound.distance(to: data.totalDateRange.lowerBound) * inGeometry.size.width)
                        Rectangle()
                            .fill(Color.yellow)
                            .contentShape(Rectangle())
                            .frame(width: max(16, width), height: 16, alignment: .leading)
                            .cornerRadius(8)
                            .padding(.leading, leftPosition)
                    }
                }
            }
        }
        .frame(height: 18)
    }
    
    /* ################################################################## */
    /**
     This prepares our haptic engine.
     */
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let hapticEngineTemp = try? CHHapticEngine()
        else { return }
        
        hapticEngine = hapticEngineTemp
        
        try? hapticEngine?.start()
    }
}
