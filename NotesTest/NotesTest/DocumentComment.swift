//
//  DocumentComment.swift
//  NotesTest
//
//  Created by chengfei on 2018/9/8.
//  Copyright © 2018 chengfeir. All rights reserved.
//

import Foundation


enum ErrorCode : Int {
    /// 根本无法找到文档
    case CannotAccessDocument
    
    /// 无法访问文档中的任何文件包装器
    case CannotLoadFileWrappers
    
    /// 无法加载 Text.rtf 文件
    case CannotLoadText
    
    /// 无法访问 attachments 文件夹
    case CannotAccessAttachments
    
    /// 无法保存 Text.rtf 文件
    case CannotSaveText
    
    /// 无法保存附件文件
    case CannotSaveAttachment
    
}

enum NoteDocumentFileNames : String {
    case TextFile = "Text.rft"
    
    case AttachmentsDirectory = "Attachments"
}

let ErrorDomain = "NotesErrorDomain"

func err(code : ErrorCode, _ userInfo:[NSObject : AnyObject]? = nil) -> NSError {
    return NSError(domain:ErrorDomain, code: code.rawValue, userInfo: userInfo as? [String : Any])
}
