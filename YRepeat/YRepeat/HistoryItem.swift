//
//  HistoryItem.swift
//  YRepeat
//
//  Created by Dino Pelic on 15. 10. 2025..
//

import Foundation

struct HistoryItem: Codable, Identifiable {
    var id: UUID = UUID()
    var videoURL: String
    var videoId: String
    var videoTitle: String?
    var startTime: Double
    var endTime: Double
    var repeatCount: Int
    var savedAt: Date

    var startTimeFormatted: String {
        TimeHelpers.secondsToTime(startTime)
    }

    var endTimeFormatted: String {
        TimeHelpers.secondsToTime(endTime)
    }

    var repeatCountFormatted: String {
        repeatCount == 0 ? "∞" : "\(repeatCount)x"
    }
}
