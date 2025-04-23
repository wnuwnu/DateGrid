//
//  FlexibleCalendarView.swift
//  FlexibleCalender
//
//  Created by Heshan Yodagama on 10/22/20.
//

import SwiftUI

public struct DateGrid<DateView>: View where DateView: View {
    
    /// DateStack view
    /// - Parameters:
    ///   - interval:
    ///   - selectedMonth: date relevant to showing month, then you can extract the components
    ///   - content:
    public init(
        interval: DateInterval,
        selectedMonth: Binding<Date>,
        mode: CalendarMode,
        scrollToToday: Bool = false,
        @ViewBuilder content: @escaping (DateGridDate) -> DateView
    ) {
        self.viewModel = .init(interval: interval, mode: mode)
        self._selectedMonth = selectedMonth
        self.content = content
        self.scrollToToday = scrollToToday
    }
    
    //TODO: make Date generator class
    private var scrollToToday: Bool
    private let viewModel: DateGridViewModel
    private let content: (DateGridDate) -> DateView
    @Binding var selectedMonth: Date
    
    public var body: some View {
        
        TabView(selection: $selectedMonth) {
            ForEach(viewModel.monthsOrWeeks, id: \.self) { monthOrWeek in
                VStack {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 0) {
                        ForEach(viewModel.days(for: monthOrWeek), id: \.self) { date in
                            let dateGridDate = DateGridDate(date: date, currentMonth: monthOrWeek)
                            
                            let monthInterval = viewModel.calendar.dateInterval(of: .month, for: monthOrWeek)!
                            let startOfGrid = viewModel.calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)!.start
                            let endOfGrid = viewModel.calendar.dateInterval(of: .weekOfMonth, for: monthInterval.end)!.end
                            
                            if date >= startOfGrid && date < endOfGrid && date >= viewModel.interval.start && date <= viewModel.interval.end {
                                content(dateGridDate)
                                    
                            } else {
                                content(dateGridDate).hidden()
                            }
                            
                        }
                    }
                    Spacer()
                }
                .tag(monthOrWeek.startOfWeek(using: viewModel.calendar)) // 중요: 바인딩용 태그
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: viewModel.mode.estimateHeight)
        .onAppear {
            if scrollToToday {
                let today = Date()
                if let weekStart = viewModel.calendar.dateInterval(of: .weekOfYear, for: today)?.start {
                    let normalized = weekStart.startOfWeek(using: viewModel.calendar)
                    print(">>> Setting selectedMonth to: \(normalized)")
                    DispatchQueue.main.async {
                        selectedMonth = normalized
                    }
                }
            }
        }




        
//        TabView(selection: $selectedMonth) {
//            
//            MonthsOrWeeks(viewModel: viewModel, content: content)
//        }
//        .frame(height: viewModel.mode.estimateHeight, alignment: .center)
//        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
//        
//        .onAppear {
//            if scrollToToday {
//                let today = Date()
//                if let weekStart = viewModel.calendar.dateInterval(of: .weekOfYear, for: today)?.start {
//                    DispatchQueue.main.async {
//                        selectedMonth = weekStart
//                    }
//                    
//                    
//                }
//            }
//        }
    }
}

struct CalendarView_Previews: PreviewProvider {
    
    @State static var selectedMonthDate = Date()
    
    static var previews: some View {
        VStack {
            Text(selectedMonthDate.description)
            
            
            DateGrid(
                interval:
                        .init(
                            start: Date.getDate(from: "2025 03 01")!,
                            end: Date.getDate(from: "2025 05 31")!
                        ),
                selectedMonth: $selectedMonthDate,
                mode: .week(estimateHeight: 400),
                scrollToToday: true
            ) { dateGridDate in
               
//                NormalDayCell(date: dateGridDate.date)
                
                VStack{
                    
                    if #available(iOS 15.0, *) {
                        

                        Text(getWeekdayString(from: dateGridDate.date))
                        //                        .font(Font.sfProText.regular.font(size: 14))
                            .frame(width: 12, height: 17)
                    } else {
                        // Fallback on earlier versions
                    }
                    
                    Text(getDayString(from: dateGridDate.date))
//                        .font(Font.sfProText.regular.font(size: 14))
                        .frame(width: 24, height: 16)
                    
                }
            }
        }
        
    }
}

func getWeekdayString(from date: Date) -> String {
    getCommonDateFormatter(dateStyle: "E").string(from: date)
}

func getDayString(from date: Date) -> String {
    getCommonDateFormatter(dateStyle: "dd").string(from: date)
}

func getCommonDateFormatter(dateStyle:String = "yyyy-MM-dd") -> DateFormatter {
    let dateFormatter = DateFormatter()
    dateFormatter.locale = Locale(identifier: "ko_KR")
    dateFormatter.dateFormat = dateStyle
    dateFormatter.timeZone = TimeZone(identifier: "KST")
    dateFormatter.calendar = Calendar(identifier: .gregorian)
    return dateFormatter
}

struct MonthsOrWeeks<DateView>: View where DateView: View {
    let viewModel: DateGridViewModel
    let content: (DateGridDate) -> DateView
    
    var body: some View {
        ForEach(viewModel.monthsOrWeeks, id: \.self) { monthOrWeek in
            
            VStack {
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: numberOfDaysInAWeek), spacing: 0) {
                    
                    ForEach(viewModel.days(for: monthOrWeek), id: \.self) { date in
                        
                        let dateGridDate = DateGridDate(date: date, currentMonth: monthOrWeek)
                        if viewModel.calendar.isDate(date, equalTo: monthOrWeek, toGranularity: .month) {
                            content(dateGridDate)
                                .id(date)
                            
                        } else {
                            content(dateGridDate)
                                .hidden()
                        }
                    }
                }
                
                //Tab view frame alignment to .Top didn't work dtz y
                Spacer()
            }.tag(monthOrWeek)
        }
    }
    
    //MARK: constant and supportive methods
    private let numberOfDaysInAWeek = 7
}


extension Date {
    func startOfWeek(using calendar: Calendar = .current) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: self)?.start ?? self
    }
}
