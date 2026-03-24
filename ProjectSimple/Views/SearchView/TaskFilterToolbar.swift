//
//  TaskFilterToolbar.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/17/26.
//

import Foundation
import TipKit

struct TaskFilterToolbar<T: Tip>: ToolbarContent {
    @Binding var priorityFilter: TaskPriority?
    @Binding var categoryFilter: ProjectCategory?
    
    let searchFilterTip: T
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Menu {
                Section("Priority") {
                    Button {
                        priorityFilter = nil
                    } label: {
                        if priorityFilter == nil {
                            Label("All Priorities", systemImage: "checkmark")
                        } else {
                            Text("All Priorities")
                        }
                    }
                    
                    ForEach(TaskPriority.allCases, id: \.self) { priority in
                        Button {
                            priorityFilter = priority
                            searchFilterTip.invalidate(reason: .actionPerformed)
                        } label: {
                            if priorityFilter == priority {
                                Label(priority.rawValue, systemImage: "checkmark")
                            } else {
                                Text(priority.rawValue)
                            }
                        }
                    }
                }
                
                Section("Category") {
                    Button {
                        categoryFilter = nil
                    } label: {
                        if categoryFilter == nil {
                            Label("All Categories", systemImage: "checkmark")
                        } else {
                            Text("All Categories")
                        }
                    }
                    
                    ForEach(ProjectCategory.allCases, id: \.self) { category in
                        Button {
                            categoryFilter = category
                            searchFilterTip.invalidate(reason: .actionPerformed)
                        } label: {
                            if categoryFilter == category {
                                Label(category.rawValue, systemImage: "checkmark")
                            } else {
                                Label(category.rawValue, systemImage: category.icon)
                            }
                        }
                    }
                }
            } label: {
                Image(systemName: hasActiveFilter
                      ? "line.3.horizontal.decrease.circle.fill"
                      : "line.3.horizontal.decrease.circle")
            }
            .popoverTip(searchFilterTip)
            .accessibilityLabel(filterAccessibilityLabel)
            .accessibilityHint("Double tap to change filters")
        }
    }
    
    private var hasActiveFilter: Bool {
        priorityFilter != nil || categoryFilter != nil
    }
    
    private var filterAccessibilityLabel: String {
        hasActiveFilter ? "Filters applied" : "No filters applied"
    }
}
