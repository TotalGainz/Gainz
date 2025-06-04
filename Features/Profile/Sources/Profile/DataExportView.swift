//
//  DataExportView.swift
//  Gainz – Profile Feature
//
//  Created by AI-Assistant on 2025-06-03.
//
//  Presents options to export all workout + body data as either
//  CSV or JSON, surfaced through the system share sheet.
//
//  References:
//  – Privacy & data-export requirement in spec (DataExportView). explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
//  – MVVM pattern & ExportDataUseCase outlined in repo docs.explanation for o3 (UPDATED).txt](file-service://file-CnLa5rmYAZJgvi98KEwAKv)
//
//  HRV / velocity tracking intentionally excluded per product scope.
//

import SwiftUI
import Combine
import UniformTypeIdentifiers
import ServiceExport   // ExportDataUseCaseProtocol

// MARK: – Export Format

public enum ExportFormat: String, CaseIterable, Identifiable {
    case csv = "CSV"
    case json = "JSON"

    public var id: String { rawValue }
    public var uti: UTType {
        switch self {
        case .csv:  .commaSeparatedText
        case .json: .json
        }
    }
    public var fileExtension: String { rawValue.lowercased() }
}

// MARK: – View

public struct DataExportView: View {

    @StateObject private var viewModel: DataExportViewModel

    public init(useCase: ExportDataUseCaseProtocol) {
        _viewModel = StateObject(wrappedValue: DataExportViewModel(useCase: useCase))
    }

    public var body: some View {
        Form {
            Section(header: Text("Choose Format")) {
                Picker("Format", selection: $viewModel.selectedFormat) {
                    ForEach(ExportFormat.allCases) { format in
                        Text(format.rawValue).tag(format)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section {
                Button {
                    viewModel.exportTapped()
                } label: {
                    Label("Export \(viewModel.selectedFormat.rawValue)", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isExporting)
            } footer: {
                if viewModel.isExporting {
                    ProgressView()
                        .progressViewStyle(.linear)
                        .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Export Data")
        .fileExporter(
            isPresented: $viewModel.showExporter,
            document: viewModel.document,
            contentType: viewModel.selectedFormat.uti,
            defaultFilename: "gainz_export.\(viewModel.selectedFormat.fileExtension)"
        ) { result in
            viewModel.handleExporterCompletion(result)
        }
        .alert("Export Failed",
               isPresented: $viewModel.showError,
               actions: { Button("OK", role: .cancel) { } },
               message: { Text(viewModel.errorMessage ?? "Unknown error") })
    }
}

// MARK: – ViewModel

@MainActor
public final class DataExportViewModel: ObservableObject {

    // MARK: Published
    @Published var selectedFormat: ExportFormat = .csv
    @Published var isExporting: Bool = false
    @Published var showExporter: Bool = false
    @Published var showError: Bool = false
    @Published var document: ExportDocument?

    var errorMessage: String?

    // MARK: Dependencies
    private let useCase: ExportDataUseCaseProtocol

    // MARK: Init
    init(useCase: ExportDataUseCaseProtocol) {
        self.useCase = useCase
    }

    // MARK: Actions
    func exportTapped() {
        Task {
            do {
                isExporting = true
                let data = try await useCase.exportUserData(as: selectedFormat)
                document = ExportDocument(data: data,
                                          contentType: selectedFormat.uti)
                isExporting = false
                showExporter = true
            } catch {
                isExporting = false
                showError = true
                errorMessage = error.localizedDescription
            }
        }
    }

    func handleExporterCompletion(_ result: Result<URL, Error>) {
        if case .failure(let error) = result {
            showError = true
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: – FileDocument Wrapper

struct ExportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.data] }
    var data: Data
    var contentType: UTType

    init(data: Data, contentType: UTType) {
        self.data = data
        self.contentType = contentType
    }

    init(configuration: ReadConfiguration) throws {
        guard let d = configuration.file.regularFileContents else { throw CocoaError(.fileReadCorruptFile) }
        self.data = d
        self.contentType = configuration.contentType
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

// MARK: – Preview

#if DEBUG
import PreviewKit

extension ExportDataUseCaseProtocol where Self == PreviewExportUseCase {}
struct DataExportView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            DataExportView(useCase: PreviewExportUseCase())
        }
    }
}
#endif
