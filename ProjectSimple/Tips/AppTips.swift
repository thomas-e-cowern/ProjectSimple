import TipKit
import SwiftUI

struct SwipeTaskTip: Tip {
    var title: Text {
        Text("Swipe to Manage Tasks")
    }

    var message: Text? {
        Text("Swipe right to edit, or swipe left to archive or delete.")
    }

    var image: Image? {
        Image(systemName: "hand.draw")
    }

    var options: [Option] {
        MaxDisplayCount(3)
    }
}

struct TapStatusTip: Tip {
    var title: Text {
        Text("Tap to Change Status")
    }

    var message: Text? {
        Text("Tap the status icon to cycle through Not Started, In Progress, and Completed.")
    }

    var image: Image? {
        Image(systemName: "circle.lefthalf.filled")
    }

    var options: [Option] {
        MaxDisplayCount(2)
    }
}

struct SearchFilterTip: Tip {
    var title: Text {
        Text("Filter by Priority")
    }

    var message: Text? {
        Text("Use the filter button to show only High, Medium, or Low priority tasks.")
    }

    var image: Image? {
        Image(systemName: "line.3.horizontal.decrease.circle")
    }

    var options: [Option] {
        MaxDisplayCount(2)
    }
}

struct AddStepTip: Tip {
    var title: Text {
        Text("Add a Step")
    }
    
    var message: Text? {
        Text("Enter some text and tap the plus button to add a new step to this task.")
    }
    
    var image: Image? {
        Image(systemName: "list.bullet.indent")
    }
    
    var options: [Option] {
        MaxDisplayCount(2)
    }
}
