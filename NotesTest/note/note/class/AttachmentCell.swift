//
//  AttachmentCell.swift
//  note
//
//  Created by chengfei on 2018/9/9.
//  Copyright © 2018 chengfeir. All rights reserved.
//

import Cocoa

@objc protocol AttachmentCellDelegate : NSObjectProtocol {
    func openSelectedAttachment(collectionItem : NSCollectionViewItem)
}

class AttachmentCell: NSCollectionViewItem {
    weak var delegate : AttachmentCellDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    override func mouseDown(with event: NSEvent) {
        if (event.clickCount == 2) {
            delegate?.openSelectedAttachment(collectionItem: self)
        }
    }
    
}
