//
//  PDFActivityItemSource.swift
//  ProjectSimple
//
//  Created by Thomas Cowern on 3/16/26.
//

import UIKit
import UniformTypeIdentifiers

// MARK: - Activity Item Source

class PDFActivityItemSource: NSObject, UIActivityItemSource {
    let fileURL: URL

    init(data: Data, projectName: String) {
        let sanitized = projectName.replacingOccurrences(of: " ", with: "_")
        let fileName = "\(sanitized)_Report.pdf"
        let exportDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("PDFExports", isDirectory: true)
        try? FileManager.default.createDirectory(at: exportDir, withIntermediateDirectories: true)
        self.fileURL = exportDir.appendingPathComponent(fileName)
        try? data.write(to: self.fileURL)
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return fileURL
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return fileURL
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return fileURL.deletingPathExtension().lastPathComponent.replacingOccurrences(of: "_", with: " ")
    }
}
