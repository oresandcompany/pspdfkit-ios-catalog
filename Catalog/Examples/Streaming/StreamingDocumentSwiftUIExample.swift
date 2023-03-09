//
//  Copyright © 2019-2023 PSPDFKit GmbH. All rights reserved.
//
//  The PSPDFKit Sample applications are licensed with a modified BSD license.
//  Please see License for details. This notice may not be removed from this file.
//

import PSPDFKit
import PSPDFKitUI
import SwiftUI

/// The streaming document example can download documents on a page-by-page basis,
/// so opening is pretty much instant.
///
/// Please see the header comment of `StreamingDocumentExample` for a list of caveats.
class StreamingDocumentSwiftUIExample: Example {

    override init() {
        super.init()

        title = "SwiftUI Streaming a document on-demand from a web-server"
        contentDescription = "Demonstrates a way to load parts of a document on demand in SwiftUI."
        category = .swiftUI
        priority = 20
    }

    override func invoke(with delegate: ExampleRunnerDelegate) -> UIViewController? {
        let streamingHelper = StreamingDocumentGenerator()
        let streamingDocument = streamingHelper.streamingDocument
        let swiftUIView = SwiftUIStreamingDocumentExampleView(streamingDocument: streamingDocument)
        let hostingController = UIHostingController(rootView: swiftUIView, largeTitleDisplayMode: .never)
        streamingHelper.showExampleAlertIfNeeded(on: hostingController)
        return hostingController
    }
}

final class SwiftUIStreamingDocumentExampleViewModel: ObservableObject {
    @Published var document: StreamingDocument

    // We need the internal wrapped view controller to update individual pages
    weak var controller: PDFViewController?

    init(fetchableDocument: StreamingDocument) {
        self.document = fetchableDocument
    }
}

private struct SwiftUIStreamingDocumentExampleView: View {
    @ObservedObject var viewModel: SwiftUIStreamingDocumentExampleViewModel

    init(streamingDocument: StreamingDocument) {
        viewModel = SwiftUIStreamingDocumentExampleViewModel(fetchableDocument: streamingDocument)
    }

    var body: some View {
        return VStack {
            PDFView(document: viewModel.document)
                .pageMode(.automatic)
                .spreadFitting(.fill)
                .pageLabelEnabled(false)
                .thumbnailBarMode(.scrollable)
                .useParentNavigationBar(true) // Access outer navigation bar from the catalog
                .updateConfiguration { builder in
                    builder.overrideClass(PDFViewController.self, with: StreamingPDFViewController.self)
                    builder.overrideClass(PDFPageView.self, with: StreamingPageView.self)

                    // These are optional, only if you need streaming thumbnails.
                    builder.overrideClass(ThumbnailBar.self, with: StreamingThumbnailBar.self)
                    builder.overrideClass(ThumbnailViewController.self, with: StreamingThumbnailViewController.self)
                }
                .updateControllerConfiguration { controller in
                    viewModel.controller = controller
                    let clearCacheItem = UIBarButtonItem(title: "Clear Cache", image: nil, primaryAction: UIAction(title: "", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in

                        guard let streamingController = controller as? StreamingPDFViewController else { return }

                        SDK.shared.cache.clear()
                        try? FileManager.default.removeItem(at: viewModel.document.streamingDefinition.downloadFolder)
                        // Create a new document to force reload the file download status.
                        let document = StreamingDocument(streamingDefinition: viewModel.document.streamingDefinition)
                        streamingController.document = document
                        viewModel.document = document
                        streamingController.downloadFile(pageIndex: 0)

                    }), menu: nil)
                    let exitItem = UIBarButtonItem(title: "Exit", image: nil, primaryAction: UIAction(title: "", image: nil, identifier: nil, discoverabilityTitle: nil, attributes: [], state: .off, handler: { [weak controller] _ in
                        controller?.navigationController?.popViewController(animated: true)
                    }), menu: nil)

                    controller.navigationItem.setLeftBarButtonItems([exitItem, clearCacheItem], for: .document, animated: false)
                    controller.navigationItem.leftItemsSupplementBackButton = false
                }
                .onDidDismiss { controller in
                    guard let streamingController = controller as? StreamingPDFViewController else { return }
                    streamingController.stopDownloadingFiles()
                }
        }
        // Prevent jumping of the content as we show/hide the navigation bar
        .edgesIgnoringSafeArea(.all)
    }
}
