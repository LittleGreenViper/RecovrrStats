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
     */
    @State private var _magnification: CGFloat = 1

    /* ################################################################## */
    /**
     */
    @State private var _position: CGFloat = 1

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
        ViewThatFits(in: .horizontal) {
            GeometryReader { inGeometry in
                ViewThatFits {
                    Rectangle( )
                        .padding([.top, .bottom], 20)
                        .background(Color.yellow)
                        .frame(width: inGeometry.size.width * _magnification, alignment: .leading)
                        .position(x: _position, y: 0)
                        .gesture(
                            TapGesture(count: 2).onEnded {
                                _magnification = 1
                                guard let minDateTemp = data?.allRows.first?.date,
                                      let maxDateTemp = data?.allRows.last?.date
                                else { return }
                                
                                let minDate = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
                                let maxDate = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
                                dataWindow = minDate...maxDate
                                _position = inGeometry.frame(in: .local).midX
                            }
                            )
                        .gesture(
                            DragGesture(minimumDistance: 2)
                                .onChanged { value in
                                    guard let minDateTemp = data?.allRows.first?.date,
                                          let maxDateTemp = data?.allRows.last?.date
                                    else { return }
                                    
                                    let minDate = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
                                    let maxDate = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
                                    
                                    let totalDateRangeInSeconds = maxDate.timeIntervalSinceReferenceDate - minDate.timeIntervalSinceReferenceDate
                                    let dateRangeInSeconds = dataWindow.upperBound.timeIntervalSinceReferenceDate - dataWindow.lowerBound.timeIntervalSinceReferenceDate
                                    
                                    if dateRangeInSeconds < totalDateRangeInSeconds {
                                        let size = inGeometry.size.width * _magnification
                                        let minX = inGeometry.frame(in: .local).minX + (size / 2)
                                        let maxX = inGeometry.frame(in: .local).maxX - (size / 2)
                                        _position = min(maxX, max(minX, value.startLocation.x + value.translation.width))
                                        let startingPosition = (_position - (size / 2)) - minX
                                        
                                        let multiplier = startingPosition / (maxX - minX)
                                        let newStartingDateInSeconds = minDate.timeIntervalSinceReferenceDate + (multiplier * totalDateRangeInSeconds)
                                        let newMinDate = Date(timeIntervalSinceReferenceDate: newStartingDateInSeconds)
                                        let newMaxDate = newMinDate.addingTimeInterval(dateRangeInSeconds)
                                        
                                        dataWindow = newMinDate...newMaxDate
                                    }
                                }
                        )
                        .onAppear {
                            _position = inGeometry.size.width / 2
                        }
                }
            }
        }
            .padding([.top, .bottom], 40)
            .background(Color.blue)
            .onAppear {
                guard let minDateTemp = data?.allRows.first?.date,
                      let maxDateTemp = data?.allRows.last?.date
                else { return }
                
                let minDate = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
                let maxDate = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
                
                dataWindow = minDate...maxDate
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
                        let multiplier = CGFloat(_firstRange.upperBound.timeIntervalSinceReferenceDate - _firstRange.lowerBound.timeIntervalSinceReferenceDate) / (maximumDate.timeIntervalSinceReferenceDate - minimumDate.timeIntervalSinceReferenceDate)
                        
                        let range = (_firstRange.upperBound.timeIntervalSinceReferenceDate - _firstRange.lowerBound.timeIntervalSinceReferenceDate) / 2
                        let location = TimeInterval(value.startAnchor.x)
                        
                        let centerDateInSeconds = (location * (range * 2)) + minimumDate.timeIntervalSinceReferenceDate
                        let centerDate = Calendar.current.startOfDay(for: Date(timeIntervalSinceReferenceDate: centerDateInSeconds)).addingTimeInterval(43200)
                        
                        // No less than 1 day.
                        let newRange = max(86400, range * value.magnification * 1.2)
                        
                        _magnification = min(1.0, value.magnification * multiplier)
                        
                        let newStartDate = Swift.min(maximumDate, Swift.max(minimumDate, centerDate.addingTimeInterval(-newRange)))
                        let newEndDate = Swift.max(minimumDate, Swift.min(maximumDate, centerDate.addingTimeInterval(newRange)))
                        
                        dataWindow = newStartDate...newEndDate
                    }
                    .onEnded { _ in _isPinching = false }
           )
    }
}
