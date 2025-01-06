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
     */
    @State private var _startLocation: Double?
    
    /* ################################################################## */
    /**
     This is our haptic engine, used to provide feedback.
     */
    @State var hapticEngine: CHHapticEngine?

    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @Binding var data: any DataProviderProtocol

    /* ################################################################## */
    /**
     The control, itself.
     */
    var body: some View {
        ViewThatFits(in: .horizontal) {
                ZStack {
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                    if data.dataWindowRange != data.totalDateRange {
                        GeometryReader { inGeometry in
                            let frame = inGeometry.frame(in: .local)
                            let geoWidth = frame.size.width
                            let globalMagnificationFactor = Double(geoWidth) / data.totalDateRange.lowerBound.distance(to: data.totalDateRange.upperBound)
                            let timeRange = data.dataWindowRange.lowerBound.distance(to: data.dataWindowRange.upperBound)
                            let width = CGFloat(max(16, timeRange * globalMagnificationFactor))
                            let leftSide = data.totalDateRange.lowerBound.distance(to: data.dataWindowRange.lowerBound) * globalMagnificationFactor
                        Rectangle()
                            .fill(Color.accentColor)
                            .cornerRadius(9)
                            .contentShape(Rectangle())
                            .frame(width: width, height: 15)
                            .position(x: leftSide + (width / 2), y: 9)
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        if data.dataWindowRange != data.totalDateRange {
                                            triggerHaptic(intensity: 0.5, sharpness: 0.5)
                                            data.setDataWindowRange(data.totalDateRange)
                                        }
                                    }
                                    .simultaneously(with:   // We combine it with the drag, so we don't get hesitation.
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { inValue in
                                                if 0 != inValue.translation.width {
                                                    _startLocation = _startLocation ?? data.dataWindowRange.lowerBound.timeIntervalSinceReferenceDate
                                                    if let startLocation = _startLocation {
                                                        let dateChangeInSeconds = Int((Double(inValue.location.x - inValue.startLocation.x) / globalMagnificationFactor) / 86400) * 86400
                                                        let newLowerBound = startLocation + Double(dateChangeInSeconds)
                                                        let finalLowerBound = max(data.totalDateRange.lowerBound.timeIntervalSinceReferenceDate,
                                                                                  min(data.totalDateRange.upperBound.timeIntervalSinceReferenceDate - timeRange,
                                                                                      newLowerBound
                                                                                     )
                                                        )
                                                        let finalUpperBound = finalLowerBound + timeRange
                                                        triggerHaptic()
                                                        data.setDataWindowRange(Date(timeIntervalSinceReferenceDate: finalLowerBound)...Date(timeIntervalSinceReferenceDate: finalUpperBound))
                                                    }
                                                }
                                            }
                                            .onEnded { _ in _startLocation = nil }
                                        )
                                )
                    }
                }
            }
        }
        .frame(height: 18)
        .onAppear { prepareHaptics() }
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
