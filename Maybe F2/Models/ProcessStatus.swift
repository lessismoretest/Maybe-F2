import Foundation

struct ProcessStatus {
    var totalCount: Int = 0
    var completedCount: Int = 0
    var isProcessing: Bool = false
    var startTime: Date?
    var estimatedTimeRemaining: TimeInterval?
    
    var progress: Double {
        guard totalCount > 0 else { return 0 }
        return Double(completedCount) / Double(totalCount)
    }
    
    mutating func start(totalCount: Int) {
        self.totalCount = totalCount
        self.completedCount = 0
        self.isProcessing = true
        self.startTime = Date()
        self.estimatedTimeRemaining = nil
    }
    
    mutating func complete() {
        self.completedCount += 1
        updateEstimatedTime()
    }
    
    mutating func stop() {
        self.isProcessing = false
        self.startTime = nil
        self.estimatedTimeRemaining = nil
    }
    
    private mutating func updateEstimatedTime() {
        guard let startTime = startTime,
              completedCount > 0 else { return }
        
        let elapsedTime = Date().timeIntervalSince(startTime)
        let averageTimePerItem = elapsedTime / Double(completedCount)
        let remainingItems = totalCount - completedCount
        estimatedTimeRemaining = averageTimePerItem * Double(remainingItems)
    }
}

extension TimeInterval {
    var formattedTime: String {
        let minutes = Int(self) / 60
        let seconds = Int(self) % 60
        if minutes > 0 {
            return "\(minutes)分\(seconds)秒"
        } else {
            return "\(seconds)秒"
        }
    }
} 