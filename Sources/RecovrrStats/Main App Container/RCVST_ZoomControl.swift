/*
 © Copyright 2024, Little Green Viper Software Development LLC
*/

import SwiftUI

/* ###################################################################################################################################### */
// MARK: - Pinch To Zoom Area -
/* ###################################################################################################################################### */
/**
 This is a control that integrates with the chart, and allows the user to pinch to magnify into the chart.
 */
struct RCVST_ZoomControl: View {
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
                    let newRange = max(86400, range * value.magnification)
                    
                    let newStartDate = Swift.min(maximumDate, Swift.max(minimumDate, centerDate.addingTimeInterval(-newRange)))
                    let newEndDate = Swift.max(minimumDate, Swift.min(maximumDate, centerDate.addingTimeInterval(newRange)))
                    
                    dataWindow = newStartDate...newEndDate
                }
                .onEnded { _ in _isPinching = false }
        )
    }
}
