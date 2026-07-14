import AVFoundation
import SwiftUI

struct CameraPreviewView: NSViewRepresentable {
    let session: AVCaptureSession
    @Binding var isMirrored: Bool

    func makeNSView(context: Context) -> PreviewNSView {
        let view = PreviewNSView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.wantsLayer = true
        updateMirror(view)
        return view
    }

    func updateNSView(_ nsView: PreviewNSView, context: Context) {
        updateMirror(nsView)
    }

    private func updateMirror(_ view: PreviewNSView) {
        let transform = isMirrored
            ? CGAffineTransformMakeScale(-1, 1)
            : .identity
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        view.previewLayer.setAffineTransform(transform)
        CATransaction.commit()
    }
}

class PreviewNSView: NSView {
    let previewLayer = AVCaptureVideoPreviewLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.addSublayer(previewLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layout() {
        super.layout()
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        previewLayer.frame = bounds
        CATransaction.commit()
    }
}
