// Date+Relative.swift
// PawHaven

import Foundation

extension Date {
    /// "2 days ago", "just now", etc.
    var relativeDisplay: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: self, relativeTo: .now)
    }

    /// "Today", "Yesterday", or "Mar 15"
    var shortDisplay: String {
        if Calendar.current.isDateInToday(self)     { return "Today" }
        if Calendar.current.isDateInYesterday(self) { return "Yesterday" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: self)
    }

    /// "9:41 AM"
    var timeDisplay: String {
        let f = DateFormatter()
        f.timeStyle = .short
        f.dateStyle = .none
        return f.string(from: self)
    }
}
