//
//  RowSwipeActions.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/17/26.
//

import SwiftUI

struct RowSwipeActions: ViewModifier {
    let onDelete: () -> Void
    let onArchive: () -> Void
    let onEdit: () -> Void

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive, action: onDelete) {
                    Label("Delete", systemImage: "trash")
                }

                Button(action: onArchive) {
                    Label("Archive", systemImage: "archivebox")
                }
                .tint(.orange)
            }
            .swipeActions(edge: .leading) {
                Button(action: onEdit) {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.blue)
            }
    }
}

extension View {
    func rowSwipeActions(
        onDelete: @escaping () -> Void,
        onArchive: @escaping () -> Void,
        onEdit: @escaping () -> Void
    ) -> some View {
        modifier(
            RowSwipeActions(
                onDelete: onDelete,
                onArchive: onArchive,
                onEdit: onEdit
            )
        )
    }
}
