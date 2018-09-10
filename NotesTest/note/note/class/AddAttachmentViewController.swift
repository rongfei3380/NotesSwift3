//
//  AddAttachmentViewController.swift
//  note
//
//  Created by chengfei on 2018/9/10.
//  Copyright © 2018 chengfeir. All rights reserved.
//

import Cocoa

protocol AddAttachmentDelegate {
    func addFile()
}


class AddAttachmentViewController: NSViewController {

    var delagate : AddAttachmentDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func addFile(_ sender: Any) {
        self.delagate?.addFile()
    }
}
