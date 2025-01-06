/*
 © Copyright 2024, Little Green Viper Software Development LLC
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
    @State private var _data: RCVST_DataProvider? {
        didSet {
            updateTotals()
            buildNavList()
        }
    }
    
    /* ################################################################## */
    /**
     This is built to populate the nav list.
     */
    @State private var _dataItems = [any DataProviderProtocol]()
    
    /* ################################################################## */
    /**
     The current (last sample) number of active users.
     */
    @State var latestActiveTotal: Int = 0
    
    /* ################################################################## */
    /**
     The current (last sample) number of inactive (new) users.
     */
    @State var latestInactiveTotal: Int = 0
    
    /* ################################################################## */
    /**
     */
    func updateTotals() {
        guard let latestAct = _data?.userDataProvider?.rows.last?.activeUsers,
              let latestInact = _data?.userDataProvider?.rows.last?.newUsers
        else { return }
        latestActiveTotal = latestAct
        latestInactiveTotal = latestInact
    }

    /* ################################################################## */
    /**
     The main navigation stack screen.
     */
    var body: some View {
        VStack {
            Text(String(format: "SLUG-MAIN-SCREEN-TITLE".localizedVariant, _data?.numberOfDays ?? 0))
                .font(.headline)
            Text(String(format: "SLUG-MAIN-CURRENT-ACTIVE".localizedVariant, latestActiveTotal))
                .foregroundColor(.green)
            Text(String(format: "SLUG-MAIN-CURRENT-INACTIVE".localizedVariant, latestInactiveTotal))
                .foregroundColor(.blue)
            NavigationStack {
                VStack(spacing: 8) {
                    List(_dataItems, id: \.chartName) { data in
                        NavigationLink {
                            view(for: data)
                        } label: {
                            Text(data.chartName)
                        }
                    }
                    // Reacts to "pull to refresh," to reload the file.
                    .refreshable {
                        RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in
                            _data = inDataProvider
                        }
                    }
                }
            }
        }
        .onAppear {
            RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in
                _data = inDataProvider
            }
        }
        // Forces updates, whenever we become active.
        .onChange(of: _scenePhase, initial: true) {
            if .active == _scenePhase,
               nil == _data {
                RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in
                    _data = inDataProvider
                }
            } else if .background == _scenePhase {
                _data = nil
            }
        }
    }
    
    /* ################################################################## */
    /**
     This was inspired by [this SO answer](https://stackoverflow.com/a/71192821/879365).
     It builds a list of items for the nav
     */
    func buildNavList() {
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
    func view(for inData: (any DataProviderProtocol)?) -> some View {
        if let data = inData {
            RCVST_UserDateBarChartDisplay(data: data)
        } else {
            Text("ERROR")
        }
    }
}
