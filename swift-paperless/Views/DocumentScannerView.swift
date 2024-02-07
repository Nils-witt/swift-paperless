import SwiftUI
import VisionKit
import PDFKit

struct DocumentScannerView: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    let onCompletion: (_ result: Result<[URL], Error>) -> Void
    
    static var isAvailable: Bool {
        VNDocumentCameraViewController.isSupported
    }
    
    class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        @Binding var isPresented: Bool
        let completionHandler: (_ result: Result<[URL], Error>) -> Void
        
        init(isPresented: Binding<Bool>, onCompletion: @escaping (_ result: Result<[URL], Error>) -> Void) {
            _isPresented = isPresented
            completionHandler = onCompletion
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            do {
                let url = try createPDF(from: scan)
                isPresented = false
                DispatchQueue.main.async {
                    self.completionHandler(.success([url]))
                }
            } catch {
                isPresented = false
                DispatchQueue.main.async {
                    self.completionHandler(.failure(error))
                }
            }
        }
        
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            isPresented = false
        }
        
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            isPresented = false
            DispatchQueue.main.async {
                self.completionHandler(.failure(error))
            }
        }
        
        private func createPDF(from scan: VNDocumentCameraScan) throws -> URL {
            let pdfDocument = PDFDocument()
            for i in 0..<scan.pageCount {
                if let pdfPage = PDFPage(image: scan.imageOfPage(at: i)) {
                    pdfDocument.insert(pdfPage, at: i)
                } else {
                    throw DocumentScannerError.pdfCreatePageFailed
                }
            }
            
            let date = Date().formatted(date: .numeric, time: .standard)
            
            let url = FileManager.default.temporaryDirectory
                .appending(component: "Scan \(date)")
                .appendingPathExtension("pdf")
            
            if pdfDocument.write(to: url) {
                return url
            } else {
                throw DocumentScannerError.pdfWriteFailed
            }
        }
    }
    
    enum DocumentScannerError: LocalizedError {
        case pdfWriteFailed
        case pdfCreatePageFailed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onCompletion: onCompletion)
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }
    
    func updateUIViewController(_: UIViewControllerType, context _: Context) {}
}