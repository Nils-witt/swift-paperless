//
//  ShareViewController.swift
//  ShareExtension
//
//  Created by Paul Gessinger on 10.03.23.
//

import os
import Social
import SwiftUI
import UIKit

@MainActor
private func makePreviewImage() async -> Image? {
    let renderer = ImageRenderer(content:
        ZStack {
            Image(systemName: "doc.text.image")
                .resizable()
                .scaledToFill()
                .padding(10)
            Rectangle()
                .stroke(.white, lineWidth: 3)
                .background(Rectangle().fill(Color.primary))
                .rotationEffect(.degrees(45))
                .frame(width: 7, height: 110)
        }
        .padding(100)
    )
    renderer.scale = 3
    if let uiImage = renderer.uiImage {
        return .init(uiImage: uiImage)
    }
    return nil
}

class ShareViewController: UIViewController {
    @IBOutlet var container: UIView!

    let attachmentManager = AttachmentManager()

    var childView: UIViewController? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        Logger.shared.notice("Paperless share extension viewDidLoad fired")

        let shareView = ShareView(attachmentManager: attachmentManager,
                                  callback: {
                                      self.extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
                                  })

        childView = UIHostingController(rootView: shareView)
        guard let childView else {
            fatalError("Inconsistency")
        }
        addChild(childView)
        container.addSubview(childView.view)
        childView.didMove(toParent: self)

        Logger.shared.notice("Receiving shared items")
        if let item = extensionContext?.inputItems.first as? NSExtensionItem {
            if let attachments = item.attachments {
                attachmentManager.receive(attachments: attachments)
            } else {
                Logger.shared.warning("Attachment was nil")
            }
        } else {
            Logger.shared.warning("Did not receive any items")
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    override public func viewDidLayoutSubviews() {
        // offset is empirical and probably wrong
        let offset: CGFloat
        if traitCollection.horizontalSizeClass == .regular {
            offset = 40
        } else {
            offset = 80
        }
        childView?.view.frame = CGRect(x: container.bounds.origin.x, y: container.bounds.origin.y, width: container.bounds.width, height: container.bounds.height + offset)
    }
}
