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
 This presents a simple navigation list, with callouts to the various charts.
 */
struct RootStackView: View, RCVST_HapticHopper {
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
        /* ################################################################## */
        /**
         Called when the window changes for some data. We use this to sync the windows.
         
         - parameter inData: The data item that had the change. We'll change all the others, to match.
         */
        func _reactToWindowChange(_ inData: (any DataProviderProtocol)?) {
            var dataItems = self._dataItems
            guard !dataItems.isEmpty,
                  let newRange = inData?.dataWindowRange,
                  !newRange.isEmpty
            else { return }
            for item in dataItems.enumerated() {
                dataItems[item.offset].dataWindowRange = newRange
            }

            self._dataItems = dataItems
        }
        
        var dataItems = [any DataProviderProtocol]()
        
        if var data = _data?.userDataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        if var data = _data?.signupsDataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        if var data = _data?.deletionsDataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        if var data = _data?.active1DataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        if var data = _data?.active7DataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        if var data = _data?.active30DataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        if var data = _data?.active90DataProvider {
            data.windowRangeCallback = _reactToWindowChange
            dataItems.append(data)
        }
        
        self._dataItems = dataItems // We set this at the end, so we don't keep refreshing the screen, every time we add a data item.
    }
    
    /* ################################################################## */
    /**
     This was inspired by [this SO answer](https://stackoverflow.com/a/71192821/879365).
     
     It acts a a "loader" for the chart view.
     
     - parameter for: The data we want displayed.
     - returns: A View, with the chart display.
     */
    @ViewBuilder
    private func _loadView(for inData: any DataProviderProtocol) -> some View {
        RCVST_UserDateBarChartDisplay(data: inData)
    }
    
    /* ################################################################## */
    /**
     The number of days, covered by the data window.
     */
    var title: String { "SLUG-MAIN-SCREEN-TITLE".localizedVariant }
    
    /* ################################################################## */
    /**
     The main navigation stack screen.
     */
    var body: some View {
        VStack {
            Text(self.title)
                .font(.headline)
            NavigationStack {
                NavigationLink("SLUG-SUMMARY-HEADER".localizedVariant) {
                    RCVST_SummaryView(data: self._data)
                        .onAppear { self.triggerHaptic(intensity: 1.0) }
                }
                
                List {
                    ForEach(self._dataItems, id: \.chartName) { inData in
                        Button {
                            withAnimation(.snappy(duration: 0.5)) {
                                self.triggerHaptic(intensity: 1.0)
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
                            RCVST_UserDateBarChartDisplay(data: inData)
                                .aspectRatio(1, contentMode: .fit)
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
                if .active == self._scenePhase,
                   nil == self._data {
                    RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in self._data = inDataProvider }
                } else if .background == self._scenePhase {
                    self._data = nil
                }
            }
        }
        .onAppear { self.prepareHaptics() }
    }
}
