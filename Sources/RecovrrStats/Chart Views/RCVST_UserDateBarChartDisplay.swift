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
import Charts
import CoreHaptics

/* ###################################################################################################################################### */
// MARK: - Chart Legend View -
/* ###################################################################################################################################### */
/**
 This displays a horizontal row of legend elements for a chart.
 */
struct RCVST_ChartLegend: View {
    /* ############################################# */
    /**
     This contains the built legend elements from which we'll build our display.
     */
    @State private var _legendElements: [RCVS_LegendElement]

    /* ############################################# */
    /**
     This returns a horizontal row of titles, preceded by dots. All will be the color they represent.
     */
    var body: some View {
        HStack(spacing: 8) {
            ForEach(_legendElements) { inLegendElement in
                HStack(spacing: 2) {
                    Circle()
                        .fill(inLegendElement.color)
                        .frame(width: 8)

                    Text(inLegendElement.name)
                        .font(.system(size: 10))
                        .italic()
                        .foregroundStyle(inLegendElement.color)
                }
            }
        }
    }
    
    /* ############################################# */
    /**
     Initializer

     - parameter legendElements: an array of legend elements that will be used to build the view.
     */
    init(legendElements inLegendElements: [RCVS_LegendElement]) {
        _legendElements = inLegendElements
    }
}

/* ###################################################################################################################################### */
// MARK: - Helps With Haptics -
/* ###################################################################################################################################### */
/**
 We declare this, to provide a default haptic implementation.
 */
protocol RCVST_HapticHopper: View {
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
    func triggerHaptic(intensity inIntensity: Float = 0.3, sharpness inSharpness: Float = 0) {
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

/* ######################################################### */
// MARK: - The Chart View -
/* ######################################################### */
/**
 This is a simple bar chart that displays a set of bars, across a number of days, and the Y-axis will represent whatever data is passed in.
 
 X-axis is date, and Y-axis is arbitrary (but probably usually users).
 */
struct RCVST_UserDateBarChartDisplay: View, RCVST_HapticHopper {
    /* ##################################################### */
    /**
     (Stored Property) This is the actual data that we'll be providing to the chart.
     
     It's somewhat mutable (we can set observational state, like marking rows as selected, or setting a "window" of dates to examine).
     */
    @State var data: any DataProviderProtocol { didSet { dayCount = data.numberOfDays } }
    
    // MARK: Private Properties

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar.
     
     This is attached to the text item that we added for the drag gesture.
     */
    @State private var _selectedValuesString: String = " "  // It needs to always be filled with something, so it doesn't vertically collapse (making the chart jump).

    /* ################################################################## */
    /**
     The value being selected by the user, while dragging.
     
     Setting this, changes the text that is displayed in the text item at the top, and also selects/deselects the row, in the model.
     */
    @State private var _selectedValue: RCVST_Row? {
        didSet {
            if let selectedValue = _selectedValue,
               !selectedValue.plottableData.isEmpty {
                data.selectRow(selectedValue)
                _selectedValuesString = data.selectionString
            } else {
                _selectedValuesString = " "
                data.deselectAllRows()
            }
        }
    }

    /* ################################################################## */
    /**
     This contains the data window, at the start of the gesture. We use this to calculate the magnification, and center of the pinch.
     */
    @State private var _firstRange: ClosedRange<Date>? { didSet { if oldValue != _firstRange { _selectedValue = nil } } }    // Make sure to nuke any selection.
    
    /* ################################################################## */
    /**
     The number of days, covered by the data window.
     */
    @Binding var dayCount: Int

    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?

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

    // MARK: Computed Properties

    /* ##################################################### */
    /**
     (Computed Property) The main chart view. It is a simple bar chart, with each bar, segregated vertically, in some cases.
     */
    var body: some View {
        GeometryReader { inGeometry in
            ScrollView {
                GroupBox(data.chartName) {
                    // We need to add a `VStack`, so that the text item, the legend, the scrubber, and chart play well together.
                    VStack {
                        // This displays the value of the selected bar. It is one line of red text, so we make it small enough to fit.
                        Text(_selectedValuesString)
                            .font(.system(size: 400 > inGeometry.frame(in: .local).width ? 13 : 20))
                            .minimumScaleFactor(0.5)
                            .foregroundStyle(RCVS_LegendSelectionColor)
                        
                        // This builds bars. The date determines the X-axis, and the Y-axis has the number of each type of user, stacked.
                        Chart(data.windowedRows as? [RCVST_Row] ?? []) { inRow in // Note that we use the `windowedRows` computed property. This comes into play, when we implement pinch-to-zoom.
                            ForEach(inRow.plottableData) { inPlottableData in
                                BarMark(
                                    x: .value("Date", inRow.sampleDate, unit: .day),    // The date is the same, for each component. Each bar represents one day.
                                    y: .value(inPlottableData.description, inPlottableData.value) // The components "stack," with subsequent ones being placed above previous ones.
                                )
                                // Each bar component gets a color, assigned by the enum.
                                .foregroundStyle(inPlottableData.color)
                            }
                        }
                        .padding(.trailing, 20)
                        
                        // The following adornments are covered in more detail in [the SwiftUI documentation](https://developer.apple.com/documentation/charts/customizing-axes-in-swift-charts).
                        
                        // This moves the Y-axis labels over to the leading edge, and displays them, so that their trailing edges are against the chart edge (so they don't overlap the chart).
                        // Default, is for the Y-axis to display against the trailing edge, with the values displayed with their leading edge against the chart's trailing edge.
                        .chartYAxis {
                            // This cycles through all of the value labels on the Y-axis, giving each level of the Y-axis a chance to strut its stuff.
                            // The closure parameter is an instance of [`AxisValue`](https://developer.apple.com/documentation/charts/axisvalue), representing the Y-axis value. We ignore this.
                            AxisMarks(preset: .aligned, position: .leading, values: data.yAxisCountValues()) { _ in  // We use the data provider utility function to give us a bunch of axis steps. We want 4 of them, in this case (default). This also fixes the scale, for pinch-to-zoom.
                                AxisGridLine()                                  // This draws a gridline, horizontally across the chart, from the leading edge of the chart, to the trailing edge. Default is a solid thin line.
                                AxisTick()                                      // This adds a short "tick" between the value label and the leading edge of the chart. Default is about 4 display units, solid thin line.
                                AxisValueLabel(anchor: .trailing)               // This draws the value for this Y-axis level, as a label. It is set to anchor its trailing edge to the axis tick.
                            }
                        }
                        .chartYAxisLabel(data.yAxisLabel)                       // This displays the axis title, above the upper, left corner of the chart, over the Y-axis labels.
                        
                        // This moves the X-axis labels down, and centers them on the tick marks. It also sets up a range of values to display, and aligns them with the start of the data range.
                        // Default, is for the X-axis to display to the right of the tickmark, and the gridlines seem to radiate from the middle.
                        .chartXAxis {
                            AxisMarks(preset: .aligned, position: .bottom, values: data.xAxisDateValues()) { inValue in  // We use the data provider utility function to give us a bunch of axis steps. We want 6 of them, in this case (default). It also tells the chart what domain to use.
                                if let dateString = inValue.as(Date.self)?.formatted(Date.FormatStyle().month(.abbreviated).day(.twoDigits)) {  // Fetch the date as a formatted string.
                                    AxisGridLine()                              // This draws a gridline, vertically down the chart, from the top of the chart, to the bottom. Default is a thin, dashed line.
                                    AxisTick(stroke: StrokeStyle())             // This adds a short "tick" between the value label and the leading edge of the chart. Adding the `stroke` parameter, with a default `StrokeStyle` instance, makes it a solid (as opposed to dashed) line.
                                    AxisValueLabel(dateString, anchor: .top)    // This draws the value for this X-axis date, as a label. It is set to anchor its top to the axis tick.
                                }
                            }
                        }
                        .chartXAxisLabel(data.xAxisLabel, alignment: .center)   // This displays the axis title, under the labels, which are under the center of the X-axis.
                        
                        // This implements tap/swipe to select.
                        // We start, by covering the chart with an overlay.
                        .chartOverlay { inChart in              // The chart instance is passed in.
                            GeometryReader { inGeom in          // We need to know the dimensions of the overlay.
                                Rectangle()                     // The overlay will be a rectangle
                                    .fill(Color.clear)          // It is filled with clear, so we can see the chart through it.
                                    .contentShape(Rectangle())  // We need to explicitly give it a shape.
                                
                                    .gesture(                   // This is the gesture context that is attached to the overlay(For both double-tap, and selection).
                                        // This gesture will set the data window to full spread, if double-tapped.
                                        TapGesture(count: 2)
                                            .onEnded {
                                                if data.dataWindowRange != data.totalDateRange {
                                                    _selectedValue = nil
                                                    triggerHaptic(intensity: 0.5, sharpness: 0.5)
                                                    data.setDataWindowRange(data.totalDateRange)
                                                }
                                            }
                                            .simultaneously(with:   // We combine it with the drag, so we don't get hesitation.
                                                // This is the actual gesture that tracks our tap/drag. We will only be paying attention to horizontal dragging (X-axis).
                                                DragGesture(minimumDistance: 0)             // It's a drag gesture, but specifying a `minimumDistance` of 0, makes it a tap/drag gesture.
                                                // This is where the magic happens. This closure is called, whenever the gesture moves.
                                                    .onChanged { inValue in                 // `inValue` contains the current gesture state.
                                                        if let frame = inChart.plotFrame {  // We need the chart's frame, as we'll be figuring out our X-axis value, based on that.
                                                            // We query the chart for the X-axis value, corresponding to the local position, given by the gesture value. We clip the gesture, to within the chart dimensions.
                                                            guard let date = inChart.value(atX: max(0, min(inChart.plotSize.width, inValue.location.x - inGeom[frame].origin.x)), as: Date.self) else { return }
                                                            // Setting this property updates the selection
                                                            _selectedValue = data.windowedRows.nearestTo(date) as? RCVST_Row
                                                            triggerHaptic()
                                                        }
                                                    }
                                                    .onEnded { _ in _selectedValue = nil }
                                            )
                                        )
                                    
                                    .gesture(                   // This is the gesture context that is attached to the overlay (for the pinch-to-zoom).
                                        // This is the actual gesture that handles magnification.
                                        MagnifyGesture()
                                            // This is where the magic happens. This closure is called, whenever the gesture changes.
                                            .onChanged { inValue in
                                                _firstRange = _firstRange ?? data.dataWindowRange   // We take a snapshot of the initial range, when we start, so we aren't changing the goalposts as we go.
                                                
                                                if let firstRange = _firstRange {
                                                    // What we are doing here, is applying our initial range, to figure out where the center of the zoom will be, and we'll be setting the new range, to either side of that.
                                                    let rangeInSeconds = (firstRange.upperBound.timeIntervalSinceReferenceDate - firstRange.lowerBound.timeIntervalSinceReferenceDate) / 2
                                                    let centerDateInSeconds = (TimeInterval(inValue.startAnchor.x) * (rangeInSeconds * 2)) + firstRange.lowerBound.timeIntervalSinceReferenceDate
                                                    let centerDate = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: centerDateInSeconds)).addingTimeInterval(43200)
                                                    
                                                    // No less than 2 days (by setting to 1 day for halfsies). The 1.2 is to "slow down" the magnification a bit, so it's not too intense.
                                                    let newRange = max(86400, (rangeInSeconds * 1.2) / inValue.magnification)
                                                    triggerHaptic()
                                                    // By changing this, we force a redraw of the chart, with the new limits.
                                                    data.setDataWindowRange((centerDate.addingTimeInterval(-newRange)...centerDate.addingTimeInterval(newRange)).clamped(to: data.totalDateRange))
                                                }
                                            }
                                            .onEnded { _ in _firstRange = nil } // We reset the initial range, when we're done.
                                    )
                            }
                        }
                        
                        RCVST_ChartLegend(legendElements: data.legend)          // The chart legend.
                        RCVST_ZoomControl(data: $data)                          // This shows a scrubber, if we are zoomed in.
                    }
                }
                // We want our box to be basically square, based on the width of the screen.
                .frame(
                    minWidth: inGeometry.size.width * 0.8,
                    maxWidth: .infinity,
                    minHeight: inGeometry.size.width,
                    maxHeight: .infinity,
                    alignment: .top
                )
                .padding([.leading, .trailing], 20)
            }
        }
        .onAppear { prepareHaptics() }
        .onDisappear { dayCount = Int(data.totalDateRange.lowerBound.distance(to: data.totalDateRange.upperBound) / 86400) }
    }
}
