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
    @State private var _position: CGFloat = 0

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
     */
    @Binding var magnification: CGFloat

    /* ################################################################## */
    /**
     The control, itself.
     */
    var body: some View {
        ViewThatFits(in: .horizontal) {
            GeometryReader { inGeometry in
                ViewThatFits {
                    Rectangle( )
                        .padding([.top, .bottom], 16)
                        .background(Color.yellow)
                        .frame(width: inGeometry.size.width * magnification, alignment: .leading)
                        .position(x: _position, y: 0)
                        .gesture(
                            TapGesture(count: 2).onEnded {
                                magnification = 1
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
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    guard let minDateTemp = data?.allRows.first?.date,
                                          let maxDateTemp = data?.allRows.last?.date
                                    else { return }
                                    
                                    let minDate = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
                                    let maxDate = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
                                    
                                    let minDateSeconds = minDate.timeIntervalSinceReferenceDate
                                    let maxDateSeconds = maxDate.timeIntervalSinceReferenceDate
                                    
                                    let dateRangeLower = dataWindow.lowerBound.timeIntervalSinceReferenceDate
                                    let dateRangeUpper = dataWindow.upperBound.timeIntervalSinceReferenceDate

                                    let totalDateRangeInSeconds = maxDateSeconds - minDateSeconds
                                    let dateRangeInSeconds = dateRangeUpper - dateRangeLower
                                    
                                    if dateRangeInSeconds < totalDateRangeInSeconds {
                                        let thumbSize = (inGeometry.size.width * magnification) / 2
                                        let areaSize = inGeometry.size.width
                                        let minX = inGeometry.frame(in: .local).minX + thumbSize
                                        let maxX = inGeometry.frame(in: .local).maxX - thumbSize
                                        let movement = (value.startLocation.x + value.translation.width)
                                        _position = min(maxX, max(minX, movement))
                                        let startingPosition = _position - minX
                                        
                                        let newStartingDateInSeconds = minDateSeconds + ((startingPosition * totalDateRangeInSeconds) / areaSize)
                                        let newMinDate = Date(timeIntervalSinceReferenceDate: newStartingDateInSeconds)
                                        let newMaxDate = newMinDate.addingTimeInterval(dateRangeInSeconds)
                                        
                                        dataWindow = newMinDate...newMaxDate
                                    }
                                }
                        )
                        .onAppear {
                            _position = inGeometry.frame(in: .local).midX
                        }
                }
            }
        }
            .padding([.top, .bottom], 20)
            .background(Color.blue)
            .onAppear {
                guard let minDateTemp = data?.allRows.first?.date,
                      let maxDateTemp = data?.allRows.last?.date
                else { return }
                
                let minDate = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
                let maxDate = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
                
                dataWindow = minDate...maxDate
            }
    }
}
