import SwiftUI
import UIKit
import UniformTypeIdentifiers

// Keep one UIKit picker alive while scene/audio state changes. Some Files
// providers label playable audio as generic data; validate the bytes after Open
// instead of leaving that provider's selection disabled by an audio-only filter.
struct AudioDocumentPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let multiple: Bool
    let completion: (Result<[URL], Error>) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(self) }
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [.item], asCopy: false)
        picker.allowsMultipleSelection = multiple
        picker.shouldShowFileExtensions = true
        picker.delegate = context.coordinator
        #if targetEnvironment(simulator)
        if ProcessInfo.processInfo.arguments.contains("--ci-picker-fixture") {
            picker.directoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent("LENOX Import UI", isDirectory: true)
        }
        #endif
        return picker
    }
    func updateUIViewController(_ picker: UIDocumentPickerViewController, context: Context) {
        // Do not rebuild the controller or mutate its selection configuration.
        context.coordinator.parent = self
    }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        var parent: AudioDocumentPicker
        private var completed = false
        init(_ parent: AudioDocumentPicker) { self.parent = parent }
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            finish(.success(urls))
        }
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            finish(.failure(CocoaError(.userCancelled)))
        }
        private func finish(_ result: Result<[URL], Error>) {
            guard !completed else { return }; completed = true
            parent.completion(result)
            parent.isPresented = false
        }
    }
}
