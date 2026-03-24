//
//  StepsSectionView.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/18/26.
//

import SwiftUI

struct StepsSectionView: View {
    @Binding var steps: [TaskStep]
    @Binding var newStepTitle: String

    var body: some View {
        Section("Steps") {
            ForEach($steps) { $step in
                TextField("Step", text: $step.title)
            }
            .onDelete { offsets in
                steps.remove(atOffsets: offsets)
            }
            .onMove { from, to in
                steps.move(fromOffsets: from, toOffset: to)
            }

            HStack {
                TextField("Add a step", text: $newStepTitle)

                Button {
                    let trimmed = newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !trimmed.isEmpty else { return }

                    steps.append(TaskStep(title: trimmed))
                    newStepTitle = ""
                } label: {
                    Image(systemName: "plus.circle.fill")
                }
                .disabled(newStepTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }
}
