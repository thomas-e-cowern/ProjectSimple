//
//  CancelToolbarItem.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/17/26.
//

import SwiftUI

struct CancelToolbarItem: ToolbarContent {
    @Environment(\.dismiss) private var dismiss

    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }
    }
}
