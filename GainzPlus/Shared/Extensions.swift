import Foundation
import SwiftUI

// MARK: - Int time formatting
extension Int {
    var formattedAsTime: String {
        let m = self / 60
        let s = self % 60
        return String(format: "%d:%02d", m, s)
    }

    var minuteLabel: String {
        switch self {
        case 60:  return "1 MIN"
        case 90:  return "1.5 MIN"
        case 120: return "2 MIN"
        default:  return "\(self / 60) MIN"
        }
    }
}

// MARK: - Double percentage
extension Double {
    var asPercent: String {
        String(format: "%.0f%%", self * 100)
    }
}

// MARK: - Card.CardType color
extension Card.CardType {
    var color: Color {
        switch self {
        case .phrasalVerb: return .teal
        case .idiom:       return Color(red: 0.78, green: 0.96, blue: 0.35) // accent green
        case .custom:      return .purple
        case .fact:        return .orange
        }
    }
}

// MARK: - View helpers
extension View {
    func cardBackground() -> some View {
        self.background(Color.black.opacity(0.001)) // hit test fix
    }
}

// MARK: - TypeBadge
struct TypeBadge: View {
    let type: Card.CardType

    var body: some View {
        Text(type.badgeLabel)
            .font(.system(.caption2, design: .monospaced))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 8).fill(type.color.opacity(0.15)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(type.color.opacity(0.3), lineWidth: 1))
            .foregroundStyle(type.color)
    }
}
