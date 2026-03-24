import WidgetKit
import SwiftUI

@main
struct OverdueTasksWidgetBundle: WidgetBundle {
    var body: some Widget {
        OverdueTasksWidget()
        HomeScreenWidget()
    }
}
