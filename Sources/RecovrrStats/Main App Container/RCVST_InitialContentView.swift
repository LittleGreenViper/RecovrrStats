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
import TabularData
import CoreHaptics

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
 This presents a simple list, with disclosures for the various charts. The Summary page is a separate screen, but the charts are shown in this screen.
 > NOTE: Zooming the chart will apply to all charts.
 */
struct RootStackView: View, RCVST_HapticHopper {
    /* ################################################################################################################################## */
    // MARK: Simple Hashable Enum For Navigation Tracking
    /* ################################################################################################################################## */
    /**
     We need a simple hashable enum to push onto the stack.
     */
    enum RCVSTDestination: Hashable {
        /* ############################################################## */
        /**
         We bring in the summary screen, with this one.
         */
        case summary(data: RCVST_DataProvider?)
    }

    /* ################################################################## */
    /**
     Used to allow the summary to return to this screen.
     */
    @State private var _path = NavigationPath()
    
    /* ################################################################## */
    /**
     This is used to give us haptic feedback for dragging.
     */
    @State var hapticEngine: CHHapticEngine?

    /* ################################################################## */
    /**
     Tracks scene activity.
     */
    @Environment(\.scenePhase) private var _scenePhase
    
    /* ################################################################## */
    /**
     This is the actual dataframe wrapper for the stats. Everything from here, on, will be bound to this.
     */
    @State private var _data: RCVST_DataProvider? { didSet { _updateTotals() } }
    
    /* ################################################################## */
    /**
     This is built to populate the nav list.
     */
    @State private var _dataItems = [any DataProviderProtocol]()
    
    /* ################################################################## */
    /**
     The current (last sample) number of active users.
     */
    @State private var _latestActiveTotal: Int = 0
    
    /* ################################################################## */
    /**
     The current (last sample) number of inactive (new) users.
     */
    @State private var _latestInactiveTotal: Int = 0
    
    /* ################################################################## */
    /**
     This is used to track which chart is open.
     */
    @State private var _expandedChartName: String?

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

    /* ################################################################## */
    /**
     This updates the active/new totals.
     */
    private func _updateTotals() {
        guard let latestAct = _data?.userDataProvider?.rows.last?.activeUsers,
              let latestInact = _data?.userDataProvider?.rows.last?.newUsers
        else { return }
        _latestActiveTotal = latestAct
        _latestInactiveTotal = latestInact
        _buildNavList()
    }
    
    /* ################################################################## */
    /**
     This was inspired by [this SO answer](https://stackoverflow.com/a/71192821/879365).
     It builds a list of items for the nav
     */
    private func _buildNavList() {
        var dataItems = [any DataProviderProtocol]()
        
        if let data = _data?.userDataProvider {
            dataItems.append(data)
        }
        if let data = _data?.signupsDataProvider {
            dataItems.append(data)
        }
        if let data = _data?.deletionsDataProvider {
            dataItems.append(data)
        }
        if let data = _data?.active1DataProvider {
            dataItems.append(data)
        }
        if let data = _data?.active7DataProvider {
            dataItems.append(data)
        }
        if let data = _data?.active30DataProvider {
            dataItems.append(data)
        }
        if let data = _data?.active90DataProvider {
            dataItems.append(data)
        }
        
        self._dataItems = dataItems
    }
    
    /* ################################################################## */
    /**
     This was inspired by [this SO answer](https://stackoverflow.com/a/71192821/879365).
     
     It acts a a "loader" for the chart view.
     
     - parameter for: The data we want displayed.
     - returns: A View, with the chart display.
     */
    @ViewBuilder
    private func _loadView(for inData: (any DataProviderProtocol)?) -> some View {
        if let data = inData {
            RCVST_UserDateBarChartDisplay(data: data)
        } else {
            Text("ERROR")
        }
    }
    
    /* ################################################################## */
    /**
     The main navigation stack screen.
     */
    var body: some View {
        VStack {
            Text("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
                .font(.headline)

            NavigationStack(path: self.$_path) {
                Button("SLUG-SUMMARY-HEADER".localizedVariant) {
                    self.triggerHaptic(intensity: 1.0)
                    self._path.append(RCVSTDestination.summary(data: self._data))
                }
                .navigationDestination(for: RCVSTDestination.self) { destination in
                    switch destination {
                    case .summary(let data):
                        RCVST_SummaryView(path: self.$_path, data: data)
                    }
                }
                List {
                    Section {
                        ForEach(self._dataItems, id: \.chartName) { inData in
                            Button {
                                withAnimation(.snappy(duration: 0.5)) {
                                    self.triggerHaptic(intensity: 0.25, sharpness: 1.0)
                                    self._expandedChartName = self._expandedChartName == inData.chartName ? nil : inData.chartName
                                }
                            } label: {
                                HStack {
                                    Text(inData.chartName)
                                    Spacer()
                                    Image(systemName: self._expandedChartName == inData.chartName ? "chevron.down" : "chevron.right")
                                }
                            }
                            if self._expandedChartName == inData.chartName {
                                self._loadView(for: inData)
                                    .id(UUID()) // Forces the chart to fully redraw
                                    .aspectRatio(1, contentMode: .fit)
                            }
                        }
                    }
                }
                .onAppear {
                    self._expandedChartName = nil
                    RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in self._data = inDataProvider }
                }
                .refreshable {
                    self._expandedChartName = nil
                    RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in self._data = inDataProvider }
                }
            }
            .onChange(of: self._scenePhase, initial: true) {
                self._expandedChartName = nil
                if .active == self._scenePhase {
                    self.prepareHaptics()
                    if nil == self._data {
                        RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in self._data = inDataProvider }
                    }
                } else if .background == self._scenePhase {
                    self._data = nil
                }
            }
        }
        .onAppear { self.prepareHaptics() }
    }
}
