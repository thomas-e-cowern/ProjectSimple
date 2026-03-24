import Testing
import PDFKit
@testable import ProjectSimple

struct PDFGeneratorTests {

    // MARK: - Helpers

    private func makeSampleProject(
        taskCount: Int = 3,
        name: String = "Test Project",
        description: String = "A test project description"
    ) -> PDFProjectInfo {
        let tasks = (0..<taskCount).map { i in
            PDFTaskInfo(
                title: "Task \(i + 1)",
                details: i == 0 ? "Some details for the first task" : "",
                dueDate: Date.now,
                status: ["Not Started", "In Progress", "Completed"][i % 3],
                priority: ["High", "Medium", "Low"][i % 3],
                priorityColorName: ["red", "orange", "green"][i % 3]
            )
        }
        return PDFProjectInfo(
            name: name,
            descriptionText: description,
            category: "Work",
            startDate: .now,
            endDate: Calendar.current.date(byAdding: .month, value: 1, to: .now)!,
            completionPercentage: 0.33,
            completedCount: 1,
            inProgressCount: 1,
            notStartedCount: 1,
            tasks: tasks
        )
    }

    private func pdfText(from data: Data) -> String {
        PDFDocument(data: data)?.string ?? ""
    }

    // MARK: - Basic Generation

    @Test func generatePDFReturnsNonEmptyData() {
        let project = makeSampleProject()
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        #expect(!data.isEmpty)
    }

    @Test func generatePDFStartsWithPDFHeader() {
        let project = makeSampleProject()
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        let header = String(data: data.prefix(5), encoding: .ascii)
        #expect(header == "%PDF-")
    }

    @Test func generatePDFContainsProjectName() {
        let project = makeSampleProject(name: "UniqueProjectName")
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        let text = pdfText(from: data)
        #expect(text.contains("UniqueProjectName"))
    }

    @Test func generatePDFContainsTaskTitles() {
        let project = makeSampleProject(taskCount: 3)
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        let text = pdfText(from: data)
        #expect(text.contains("Task 1"))
        #expect(text.contains("Task 2"))
        #expect(text.contains("Task 3"))
    }

    @Test func generatePDFContainsCategoryLabel() {
        let project = makeSampleProject()
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        let text = pdfText(from: data)
        #expect(text.contains("Work"))
    }

    @Test func generatePDFContainsProgressSummary() {
        let project = makeSampleProject()
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        let text = pdfText(from: data)
        #expect(text.contains("33%"))
    }

    @Test func generatePDFContainsDescription() {
        let project = makeSampleProject(description: "My unique description here")
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        let text = pdfText(from: data)
        #expect(text.contains("My unique description here"))
    }

    // MARK: - Edge Cases

    @Test func generatePDFWithNoTasks() {
        let project = PDFProjectInfo(
            name: "Empty Project",
            descriptionText: "",
            category: "Other",
            startDate: .now,
            endDate: .now,
            completionPercentage: 0,
            completedCount: 0,
            inProgressCount: 0,
            notStartedCount: 0,
            tasks: []
        )
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        #expect(!data.isEmpty)
        let header = String(data: data.prefix(5), encoding: .ascii)
        #expect(header == "%PDF-")
    }

    @Test func generatePDFWithEmptyDescription() {
        let project = makeSampleProject(description: "")
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        #expect(!data.isEmpty)
    }

    @Test func generatePDFWithManyTasksProducesLargerData() {
        let project = makeSampleProject(taskCount: 50)
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        #expect(!data.isEmpty)
        #expect(data.count > 5000)
    }

    @Test func generatePDFWithFullCompletion() {
        let tasks = [
            PDFTaskInfo(title: "Done 1", details: "", dueDate: .now,
                        status: "Completed", priority: "High", priorityColorName: "red"),
            PDFTaskInfo(title: "Done 2", details: "", dueDate: .now,
                        status: "Completed", priority: "Low", priorityColorName: "green"),
        ]
        let project = PDFProjectInfo(
            name: "All Done",
            descriptionText: "Everything complete",
            category: "Personal",
            startDate: .now,
            endDate: .now,
            completionPercentage: 1.0,
            completedCount: 2,
            inProgressCount: 0,
            notStartedCount: 0,
            tasks: tasks
        )
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: project)
        #expect(!data.isEmpty)
        let text = pdfText(from: data)
        #expect(text.contains("100%"))
    }

    // MARK: - Temporary File Writing

    @Test func writePDFToTemporaryFileCreatesFile() {
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: makeSampleProject())
        let url = writePDFToTemporaryFile(data: data, projectName: "Test Project")
        #expect(url != nil)
        #expect(FileManager.default.fileExists(atPath: url!.path))
        try? FileManager.default.removeItem(at: url!)
    }

    @Test func writePDFToTemporaryFileHasPDFExtension() {
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: makeSampleProject())
        let url = writePDFToTemporaryFile(data: data, projectName: "My Project")
        #expect(url?.pathExtension == "pdf")
        if let url { try? FileManager.default.removeItem(at: url) }
    }

    @Test func writePDFToTemporaryFileSanitizesName() {
        let generator = PDFGenerator()
        let data = generator.generatePDF(for: makeSampleProject())
        let url = writePDFToTemporaryFile(data: data, projectName: "My Great Project")
        #expect(url?.lastPathComponent == "My_Great_Project_Report.pdf")
        if let url { try? FileManager.default.removeItem(at: url) }
    }
}
