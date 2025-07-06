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
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase
    
    /* ################################################################## */
    /**
     The height f the control, in display units.
     */
    private static let _frameHeightInDisplayUnits = CGFloat(18)
    
    /* ################################################################## */
    /**
     The initial location, at the start of the drag.
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
    @Binding var data: any DataProviderProtocol { didSet { self.dayCount = self.data.numberOfDays } }
    
    /* ################################################################## */
    /**
     The number of days, covered by the data window.
     */
    @Binding var dayCount: Int?

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
                    if self.data.dataWindowRange != data.totalDateRange {
                        GeometryReader { inGeometry in
                            let frame = inGeometry.frame(in: .local)
                            let geoWidth = frame.size.width
                            let globalMagnificationFactor = Double(geoWidth) / self.data.totalDateRange.lowerBound.distance(to: self.data.totalDateRange.upperBound)
                            let timeRange = self.data.dataWindowRange.lowerBound.distance(to: self.data.dataWindowRange.upperBound)
                            let width = CGFloat(max(16, timeRange * globalMagnificationFactor))
                            let leftSide = self.data.totalDateRange.lowerBound.distance(to: self.data.dataWindowRange.lowerBound) * globalMagnificationFactor
                        Rectangle()
                            .fill(Color.accentColor)
                            .cornerRadius(9)
                            .contentShape(Rectangle())
                            .frame(width: width, height: 15)
                            .position(x: leftSide + (width / 2), y: 9)
                            .gesture(
                                TapGesture(count: 2)
                                    .onEnded {
                                        if self.data.dataWindowRange != self.data.totalDateRange {
                                            self.triggerHaptic(intensity: 0.5, sharpness: 0.5)
                                            self.data.setDataWindowRange(self.data.totalDateRange)
                                        }
                                    }
                                    .simultaneously(with:   // We combine it with the drag, so we don't get hesitation.
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { inValue in
                                                if 0 != inValue.translation.width || 0 != inValue.translation.height {
                                                    self._startLocation = self._startLocation ?? self.data.dataWindowRange.lowerBound.timeIntervalSinceReferenceDate
                                                    if let startLocation = _startLocation {
                                                        let isXAxis = abs(inValue.location.x - inValue.startLocation.x) > abs(inValue.location.y - inValue.startLocation.y)
                                                        let maxChange = isXAxis ? Double(inValue.location.x - inValue.startLocation.x) : Double(inValue.location.y - inValue.startLocation.y)
                                                        let dateChangeInSeconds = Int((maxChange / globalMagnificationFactor) / 86400) * 86400
                                                        let newLowerBound = startLocation + Double(dateChangeInSeconds)
                                                        let finalLowerBound = max(self.data.totalDateRange.lowerBound.timeIntervalSinceReferenceDate,
                                                                                  min(self.data.totalDateRange.upperBound.timeIntervalSinceReferenceDate - timeRange,
                                                                                      newLowerBound
                                                                                     )
                                                        )
                                                        let finalUpperBound = finalLowerBound + timeRange
                                                        self.triggerHaptic()
                                                        self.data.setDataWindowRange(Date(timeIntervalSinceReferenceDate: finalLowerBound)...Date(timeIntervalSinceReferenceDate: finalUpperBound))
                                                    }
                                                }
                                            }
                                        .onEnded { _ in self._startLocation = nil }
                                        )
                                )
                    }
                }
            }
        }
        .frame(height: Self._frameHeightInDisplayUnits)
        .onAppear { self.prepareHaptics() }
        .onChange(of: self._scenePhase, initial: true) {
            if .active == self._scenePhase {
                self.prepareHaptics()
            }
        }
    }
    
    /* ################################################################## */
    /**
     This prepares our haptic engine.
     */
    func prepareHaptics() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics,
              let hapticEngineTemp = try? CHHapticEngine()
        else { return }
        
        self.hapticEngine = hapticEngineTemp
        
        try? hapticEngineTemp.start()
    }
}
