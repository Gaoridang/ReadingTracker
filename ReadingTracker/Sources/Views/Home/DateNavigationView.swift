//
//  DateNavigationView.swift
//  ReadingTracker
//
//  Created by 이재준 on 6/27/25.
//


// DateNavigationView.swift
import SwiftUI

struct DateNavigationView: View {
    @Binding var currentDate: Date
    
    private var dates: [Date] {
        (-1...1).compactMap { offset in
            Calendar.current.date(byAdding: .day, value: offset, to: currentDate)
        }
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }
    
    var body: some View {
        HStack {
            // Year and Month on Left
            VStack(alignment: .leading, spacing: 2) {
                Text(String(Calendar.current.component(.year, from: currentDate)))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                
                Text(dateFormatter.string(from: currentDate))
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.black)
            }
            
            Spacer()
            
            // 3 Days on Right
            HStack(spacing: 16) {
                ForEach(dates, id: \.self) { date in
                    DateButton(
                        date: date,
                        isSelected: Calendar.current.isDate(date, inSameDayAs: currentDate),
                        action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                currentDate = date
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .frame(height: 80) // Fixed height to prevent jumping
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 50 {
                        // Swipe right - previous day
                        changeDay(by: -1)
                    } else if value.translation.width < -50 {
                        // Swipe left - next day
                        changeDay(by: 1)
                    }
                }
        )
    }
    
    private func changeDay(by offset: Int) {
        if let newDate = Calendar.current.date(byAdding: .day, value: offset, to: currentDate) {
            withAnimation(.easeInOut(duration: 0.2)) {
                currentDate = newDate
            }
        }
    }
}

struct DateButton: View {
    let date: Date
    let isSelected: Bool
    let action: () -> Void
    
    private var dayFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(dayFormatter.string(from: date))
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .black : .gray)
                
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isSelected ? .black : .gray)
                
                // Fixed height container for today indicator
                ZStack {
                    Color.clear
                        .frame(height: 8)
                    
                    if isToday {
                        Circle()
                            .fill(Color(hex: "4CAF50"))
                            .frame(width: 4, height: 4)
                    }
                }
            }
            .frame(minHeight: 60) // Ensure consistent height
            .opacity(isSelected ? 1.0 : 0.4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    DateNavigationView(currentDate: .constant(Date()))
        .background(Color.gray.opacity(0.1))
}