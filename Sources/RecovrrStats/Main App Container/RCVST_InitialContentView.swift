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
 The main container view for everything else.
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
     The names to use for all the navigation items.
     */
    private static let _navigationNames: [String] = ["SLUG-USER-TOTALS-CHART-TITLE".localizedVariant,
                                                     "SLUG-SIGNUP-TOTALS-CHART-TITLE".localizedVariant,
                                                     "SLUG-CHART-3-TITLE".localizedVariant,
                                                     "SLUG-CHART-4-TITLE".localizedVariant,
                                                     "SLUG-CHART-5-TITLE".localizedVariant
                                                    ]

    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase

    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats. Everything from here, on, will be bound to this.
     */
    @State private var _data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     This has the data range we will be looking at.
     */
    @State private var _dataWindow = Date.distantPast...Date.distantFuture

    /* ################################################################## */
    /**
     The string that displays the data for the selected bar. Everything from here, on, will be bound to this.
     */
    @State private var _selectedValuesString: String = " "

    /* ################################################################## */
    /**
     The main navigation stack screen.
     */
    var body: some View {
        // This displays the value of the selected bar.
        Text(_selectedValuesString)
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .font(.subheadline)
            .foregroundStyle(.red)
        NavigationStack {
            List {
                NavigationLink(Self._navigationNames[0]) { RCVST_Chart1View(title: Self._navigationNames[0], data: $_data, dataWindow: $_dataWindow, selectedValuesString: $_selectedValuesString) }
                NavigationLink(Self._navigationNames[1]) { RCVST_Chart2View(title: Self._navigationNames[1], data: $_data, dataWindow: $_dataWindow, selectedValuesString: $_selectedValuesString) }
                NavigationLink(Self._navigationNames[2]) { RCVST_Chart3View(title: Self._navigationNames[2], data: $_data, dataWindow: $_dataWindow, selectedValuesString: $_selectedValuesString) }
                NavigationLink(Self._navigationNames[3]) { RCVST_Chart4View(title: Self._navigationNames[3], data: $_data, dataWindow: $_dataWindow, selectedValuesString: $_selectedValuesString) }
                NavigationLink(Self._navigationNames[4]) { RCVST_Chart5View(title: Self._navigationNames[4], data: $_data, dataWindow: $_dataWindow, selectedValuesString: $_selectedValuesString) }
            }
            .navigationTitle("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
            // Reacts to "pull to refresh," to reload the file.
            .refreshable { _data = RCVST_DataProvider(useMockData: false) }
        }
        .onAppear { _data = RCVST_DataProvider(useMockData: false) }
        // Forces updates, whenever we become active.
        .onChange(of: _scenePhase, initial: true) {
            if .active == _scenePhase,
               nil == _data {
                _data = RCVST_DataProvider(useMockData: false)
            } else if .background == _scenePhase {
                _data = nil
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - Pinch To Zoom Area -
/* ###################################################################################################################################### */
/**
 This is a control that integrates with the chart, and allows the user to pinch to magnify into the chart.
 */
struct ZoomControl: View {
    /* ################################################################## */
    /**
     This contains the data window, at the start of the gesture.
     */
    @State private var _firstRange: ClosedRange<Date> = Date.distantPast...Date.distantFuture
    
    /* ################################################################## */
    /**
     This is set to true, while we are in the middle of a gesture.
     */
    @State private var _isPinching: Bool = false
    
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats.
     */
    @Binding var data: RCVST_DataProvider?

    /* ################################################################## */
    /**
     This has the data range we will be looking at.
     */
    @Binding var dataWindow: ClosedRange<Date>

    /* ################################################################## */
    /**
     The control, itself.
     */
    var body: some View {
        ViewThatFits {
            Text("PINCH HERE")
                .padding()
        }
        .frame(
            maxWidth: .infinity,
            maxHeight: .infinity,
            alignment: .center
        )
        .background(Color.blue)
        .onAppear {
            guard var minDateTemp = data?.allRows.first?.date,
                  var maxDateTemp = data?.allRows.last?.date
            else { return }
            
            minDateTemp = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
            maxDateTemp = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
            
            dataWindow = minDateTemp...maxDateTemp
        }
        .gesture(
            MagnifyGesture()
                .onChanged { value in
                    guard let minimumClipDate = data?.allRows.first?.date,
                          let maximumClipDate = data?.allRows.last?.date
                    else { return }
                    
                    if !_isPinching {
                        _isPinching = true
                        _firstRange = dataWindow
                    }
                    
                    let minimumDate = minimumClipDate.addingTimeInterval(-43200)
                    let maximumDate = maximumClipDate.addingTimeInterval(43200)
                    
                    let range = (_firstRange.upperBound.timeIntervalSinceReferenceDate - _firstRange.lowerBound.timeIntervalSinceReferenceDate) / 2
                    let location = TimeInterval(value.startAnchor.x)
                    
                    let centerDateInSeconds = (location * (range * 2)) + minimumDate.timeIntervalSinceReferenceDate
                    let centerDate = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: centerDateInSeconds)).addingTimeInterval(43200)
                    
                    // No less than 1 day.
                    let newRange = max(86400, range / value.magnification)
                    
                    let newStartDate = Swift.min(maximumDate, Swift.max(minimumDate, centerDate.addingTimeInterval(-newRange)))
                    let newEndDate = Swift.max(minimumDate, Swift.min(maximumDate, centerDate.addingTimeInterval(newRange)))
                    
                    dataWindow = newStartDate...newEndDate
                }
                .onEnded { _ in _isPinching = false }
        )
    }
}
