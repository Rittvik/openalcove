import SwiftUI
import Combine
import EventKit

public struct CalendarQuickView: View {
    @State private var currentDate = Date()
    @State private var upcomingEventTitle: String = "No upcoming meetings"
    @State private var upcomingEventTime: String = ""
    
    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()
    private let eventStore = EKEventStore()
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 1) {
                Text(currentDate, format: .dateTime.weekday(.wide))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red.opacity(0.9))
                    .textCase(.uppercase)
                Text(currentDate, format: .dateTime.day().month(.abbreviated))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(width: 80, alignment: .leading)
            
            Divider()
                .frame(height: 24)
                .background(Color.white.opacity(0.15))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(upcomingEventTitle)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .foregroundColor(.white.opacity(0.9))
                if !upcomingEventTime.isEmpty {
                    Text(upcomingEventTime)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            Spacer()
            
            Text(currentDate, format: .dateTime.hour().minute())
                .font(.system(size: 16, weight: .semibold, design: .default))
                .monospacedDigit()
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .onReceive(timer) { input in
            currentDate = input
        }
        .onAppear {
            fetchEvents()
        }
    }
    
    private func fetchEvents() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .authorized {
            loadNextEvent()
        } else {
            if #available(macOS 14.0, *) {
                eventStore.requestFullAccessToEvents { granted, _ in
                    if granted { DispatchQueue.main.async { self.loadNextEvent() } }
                }
            } else {
                eventStore.requestAccess(to: .event) { granted, _ in
                    if granted { DispatchQueue.main.async { self.loadNextEvent() } }
                }
            }
        }
    }
    
    private func loadNextEvent() {
        let calendars = eventStore.calendars(for: .event)
        let now = Date()
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: now) ?? now
        let predicate = eventStore.predicateForEvents(withStart: now, end: endOfDay, calendars: calendars)
        let events = eventStore.events(matching: predicate).sorted { $0.startDate < $1.startDate }
        
        if let next = events.first {
            upcomingEventTitle = next.title
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            upcomingEventTime = "At " + formatter.string(from: next.startDate)
        }
    }
}
