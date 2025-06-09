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
        _dataItems = [any DataProviderProtocol]()
        if let data = _data?.userDataProvider {
            _dataItems.append(data)
        }
        if let data = _data?.signupsDataProvider {
            _dataItems.append(data)
        }
        if let data = _data?.deletionsDataProvider {
            _dataItems.append(data)
        }
        if let data = _data?.active1DataProvider {
            _dataItems.append(data)
        }
        if let data = _data?.active7DataProvider {
            _dataItems.append(data)
        }
        if let data = _data?.active30DataProvider {
            _dataItems.append(data)
        }
        if let data = _data?.active90DataProvider {
            _dataItems.append(data)
        }
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
            RCVST_UserDateBarChartDisplay(data: data, dayCount: $dayCount)
        } else {
            Text("ERROR")
        }
    }
    
    /* ################################################################## */
    /**
     The number of days, covered by the data window.
     */
    @State var dayCount: Int?
    
    /* ################################################################## */
    /**
     The number of days, covered by the data window.
     */
    var title: String {
        if let dayCount = dayCount {
            return String(format: "SLUG-MAIN-SCREEN-TITLE-FORMAT".localizedVariant, dayCount)
        } else {
            return "SLUG-MAIN-SCREEN-TITLE".localizedVariant
        }
    }

    /* ################################################################## */
    /**
     The main navigation stack screen.
     */
    var body: some View {
        VStack {
            Text(title)
                .font(.headline)
            Text(String(format: "SLUG-MAIN-CURRENT-ACTIVE".localizedVariant, _latestActiveTotal))
                .foregroundColor(.green)
                .font(.caption)
            Text(String(format: "SLUG-MAIN-CURRENT-INACTIVE".localizedVariant, _latestInactiveTotal))
                .foregroundColor(.blue)
                .font(.caption)
            NavigationStack {
                List {
                    NavigationLink("SLUG-SUMMARY-HEADER".localizedVariant) { RCVST_SummaryView(data: self._data) }
                    ForEach(_dataItems, id: \.chartName) { inData in NavigationLink(inData.chartName) { _loadView(for: inData) } }
                }
                    // Reacts to "pull to refresh," to reload the file.
                    .refreshable { RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in _data = inDataProvider } }
            }
        }
            // Makes sure that we load up, immediately.
        .onAppear {
            dayCount = nil
            RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in
                _data = inDataProvider
            }
        }
            // Forces updates, whenever we become active.
            .onChange(of: _scenePhase, initial: true) {
                if .active == _scenePhase,
                   nil == _data {
                    RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in _data = inDataProvider }
                } else if .background == _scenePhase {
                    _data = nil
                }
            }
    }
}
