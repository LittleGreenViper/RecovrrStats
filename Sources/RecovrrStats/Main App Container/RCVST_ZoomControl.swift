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
     This has the number of days that we will display in the text item.
     */
    @State private var _days: Int = 0
    
    /* ################################################################## */
    /**
     This is set to true, while we are in the middle of a gesture.
     */
    @State private var _isPinching: Bool = false

    /* ################################################################## */
    /**
     This is the horizontal position of the "thumb," in the "slider."
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
     This is the selected magnification level of the data window.
     */
    @Binding var magnification: CGFloat

    /* ################################################################## */
    /**
     The control, itself.
     */
    var body: some View {
        ViewThatFits(in: .horizontal) {
            GeometryReader { inGeometry in
                ZStack {
                    Rectangle()
                        .padding([.top, .bottom], 12)
                        .background(Color(red: 1, green: 1, blue: 0))
                        .frame(width: inGeometry.size.width * magnification, alignment: .leading)
                        .onChange(of: magnification) {
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
                            
                            _days = Int((dateRangeInSeconds + 86399) / 86400)

                            if dateRangeInSeconds < totalDateRangeInSeconds {
                                let thumbSize = (inGeometry.size.width * magnification) / 2
                                let centerInSeconds = ((dateRangeUpper + dateRangeLower) / 2) - minDateSeconds
                                let centerPos = centerInSeconds / totalDateRangeInSeconds
                                let positionFactor = (centerPos * inGeometry.size.width) + inGeometry.frame(in: .local).minX
                                let minX = inGeometry.frame(in: .local).minX + thumbSize
                                let maxX = inGeometry.frame(in: .local).maxX - thumbSize
                                _position = min(maxX, max(minX, positionFactor))
                            } else {
                                _position = inGeometry.frame(in: .local).midX
                            }
                        }
                        .onAppear { _position = inGeometry.frame(in: .local).midX }
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
                    Text(String(format: "SLUG-SCROLLER-LABEL-FORMAT".localizedVariant, _days))
                        .allowsHitTesting(false)
                        .scaledToFill()
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                        .foregroundColor(.black)
                        .frame(height: inGeometry.size.height)
                        .font(.system(size: inGeometry.size.height, weight: .bold))
                }
            }
        }
            .padding([.top, .bottom], 12)
            .background(Color(red: 0.4, green: 0.7, blue: 1))
            .onAppear {
                guard let minDateTemp = data?.allRows.first?.date,
                      let maxDateTemp = data?.allRows.last?.date
                else { return }
                
                let minDate = max(Date.distantPast, minDateTemp.addingTimeInterval(-43200))
                let maxDate = min(Date.distantFuture, maxDateTemp.addingTimeInterval(43200))
                
                _days = Int(((maxDate.timeIntervalSinceReferenceDate - minDate.timeIntervalSinceReferenceDate) + 86399) / 86400)
                dataWindow = minDate...maxDate
            }
    }
}
