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
import UIKit    // For building the "graph paper" background.

/* ###################################################################################################################################### */
// MARK: - Initial View -
/* ###################################################################################################################################### */
/**
 The main container view for everything else.
 */
struct RCVST_InitialContentView: View {
    /* ################################################################## */
    /**
     This generates a UIImage that has a "graph paper" pattern, composed of translucent white lines, with a transparent background.
     
     - parameter inSize: The size of the image.
     - parameter inLargeSquareSize: The size, in displayUnits, of the large squares. Default is 100 display units.
     - parameter inLineColor: The color of the lines. Default is translucent white.
     - returns: A new UIImage, with the pattern.
     */
    private static func _makeGraphPaperImage(size inSize: CGSize,
                                             largeSquareSize inLargeSquareSize: CGFloat = 100,
                                             lineColor inLineColor: UIColor = .white.withAlphaComponent(0.125)
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: inSize, format: UIGraphicsImageRendererFormat.default())
        
        let smallSquareSize = inLargeSquareSize / 10

        // We want the image to go past the edges, if necessary.
        let numLargeCols = Int((inSize.width + (inLargeSquareSize - 1)) / inLargeSquareSize)
        let numLargeRows = Int((inSize.height + (inLargeSquareSize - 1)) / inLargeSquareSize)
        
        let numSmallCols = numLargeCols * 10
        let numSmallRows = numLargeRows * 10
        
        return renderer.image { context in
            let cgContext = context.cgContext
            cgContext.setFillColor(UIColor.clear.cgColor)
            cgContext.fill(CGRect(origin: .zero, size: inSize))
            cgContext.setShouldAntialias(false)
            
            // Draw small grid lines
            cgContext.setStrokeColor(inLineColor.cgColor)
            cgContext.setLineWidth(0.25 / UIScreen.main.scale)
            
            for i in 0...numSmallCols {
                let x = CGFloat(i) * smallSquareSize
                cgContext.move(to: CGPoint(x: x, y: 0))
                cgContext.addLine(to: CGPoint(x: x, y: inSize.height))
            }
            
            for i in 0...numSmallRows {
                let y = CGFloat(i) * smallSquareSize
                cgContext.move(to: CGPoint(x: 0, y: y))
                cgContext.addLine(to: CGPoint(x: inSize.width, y: y))
            }
            
            cgContext.strokePath()
            
            // Draw large grid lines
            cgContext.setStrokeColor(inLineColor.cgColor)
            cgContext.setLineWidth(1.0 / UIScreen.main.scale)
            
            for i in 0...numLargeCols {
                let x = CGFloat(i) * inLargeSquareSize
                cgContext.move(to: CGPoint(x: x, y: 0))
                cgContext.addLine(to: CGPoint(x: x, y: inSize.height))
            }
            
            for i in 0...numLargeRows {
                let y = CGFloat(i) * inLargeSquareSize
                cgContext.move(to: CGPoint(x: 0, y: y))
                cgContext.addLine(to: CGPoint(x: inSize.width, y: y))
            }
            
            cgContext.strokePath()
        }
    }

    /* ################################################################## */
    /**
     Default init. We just use this to set the navbar to transparent.
     */
    init() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    /* ################################################################## */
    /**
     This is the layout for this screen.
     */
    var body: some View {
        ZStack {
            GeometryReader { inGeo in
                Image("GradientBackground")
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .ignoresSafeArea()
                    .frame(width: inGeo.size.width, height: inGeo.size.height)
                
                Image(uiImage: Self._makeGraphPaperImage(size: inGeo.size))
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .ignoresSafeArea()
                    .frame(width: inGeo.size.width, height: inGeo.size.height)
                RootStackView()
            }
        }
    }
}

/* ###################################################################################################################################### */
// MARK: - The List of Charts -
/* ###################################################################################################################################### */
/**
 This presents a simple list, with disclosures for the various charts and a summary.
 > NOTE: Zooming the chart will apply to all charts.
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
    @State private var _data: RCVST_DataProvider? { didSet { self._updateTotals() } }
    
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
        guard let latestAct = self._data?.userDataProvider?.rows.last?.activeUsers,
              let latestInact = self._data?.userDataProvider?.rows.last?.newUsers
        else { return }
        self._latestActiveTotal = latestAct
        self._latestInactiveTotal = latestInact
        self._buildNavList()
    }
    
    /* ################################################################## */
    /**
     This was inspired by [this SO answer](https://stackoverflow.com/a/71192821/879365).
     It builds a list of items for the nav
     */
    private func _buildNavList() {
        var dataItems = [any DataProviderProtocol]()
        
        if let data = self._data?.userDataProvider {
            dataItems.append(data)
        }
        if let data = self._data?.signupsDataProvider {
            dataItems.append(data)
        }
        if let data = self._data?.deletionsDataProvider {
            dataItems.append(data)
        }
        if let data = self._data?.active1DataProvider {
            dataItems.append(data)
        }
        if let data = self._data?.active7DataProvider {
            dataItems.append(data)
        }
        if let data = self._data?.active30DataProvider {
            dataItems.append(data)
        }
        if let data = self._data?.active90DataProvider {
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
     The main list stack screen.
     */
    var body: some View {
            VStack(spacing: 0) {
                Text("SLUG-MAIN-SCREEN-TITLE".localizedVariant)
                    .font(.headline)
                    .foregroundStyle(Color.white)

                List {
                    Button {
                        withAnimation(.snappy(duration: 0.5)) {
                            self.triggerHaptic(intensity: 0.5, sharpness: 1.0)
                            self._expandedChartName = self._expandedChartName == "SUMMARY" ? nil : "SUMMARY"
                        }
                    } label: {
                        HStack {
                            Text("SLUG-SUMMARY-HEADER".localizedVariant)
                            Spacer()
                            Image(systemName: self._expandedChartName == "SUMMARY" ? "chevron.down" : "chevron.right")
                        }
                    }
                    if self._expandedChartName == "SUMMARY" {
                        RCVST_SummaryView(data: self._data)
                    }
                    ForEach(self._dataItems, id: \.chartName) { inData in
                        Button {
                            withAnimation(.snappy(duration: 0.5)) {
                                self.triggerHaptic(intensity: 0.5, sharpness: 1.0)
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
                                .id(UUID())
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
                .background(Color.clear)
                .scrollContentBackground(.hidden)
                .onAppear {
                    self._expandedChartName = nil
                    RCVST_DataProvider.factory { inDataProvider in self._data = inDataProvider }
                }
                .refreshable {
                    self._expandedChartName = nil
                    RCVST_DataProvider.factory { inDataProvider in self._data = inDataProvider }
                }
            }
            .background(Color.clear)
            .onAppear { self.prepareHaptics() }
            .onChange(of: self._scenePhase, initial: true) {
                if .background == self._scenePhase {
                    self._expandedChartName = nil
                } else if .active == self._scenePhase {
                    self.prepareHaptics()
                }
        }
    }
}
