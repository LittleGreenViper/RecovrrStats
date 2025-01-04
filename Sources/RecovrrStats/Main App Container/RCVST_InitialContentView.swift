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
    @State private var _data: RCVST_DataProvider? { didSet { updateTotals() } }
    
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
            NavigationStack {
                VStack(spacing: 8) {
                    Text(String(format: "SLUG-MAIN-CURRENT-ACTIVE".localizedVariant, latestActiveTotal))
                        .foregroundColor(.green)
                    Text(String(format: "SLUG-MAIN-CURRENT-INACTIVE".localizedVariant, latestInactiveTotal))
                        .foregroundColor(.blue)
                    List {
                        if let data = _data?.userDataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                        if let data = _data?.signupsDataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                        if let data = _data?.deletionsDataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                        if let data = _data?.active1DataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                        if let data = _data?.active7DataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                        if let data = _data?.active30DataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                        if let data = _data?.active90DataProvider {
                            NavigationLink(data.chartName) {
                                RCVST_UserDateBarChartDisplay(data: data)
                            }
                        }
                    }
                    .navigationTitle("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
                    // Reacts to "pull to refresh," to reload the file.
                    .refreshable {
                        RCVST_DataProvider.factory(useDummyData: false) { inDataProvider in
                            _data = inDataProvider
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
    }
}
