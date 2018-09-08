//
//  Document.swift
//  NotesTest
//
//  Created by chengfei on 2018/9/7.
//  Copyright © 2018 chengfeir. All rights reserved.
//

import Cocoa

class Document: NSDocument {
    //文本
    var text001 : NSAttributedString = NSAttributedString()
    // 附件
    var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override var windowNibName: NSNib.Name? {
        // Returns the nib file name of the document
        // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this property and override -makeWindowControllers instead.
        return NSNib.Name("Document")
    }

    override func data(ofType typeName: String) throws -> Data {
        // Insert code here to write your document to data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning nil.
        // You can also choose to override fileWrapperOfType:error:, writeToURL:ofType:error:, or writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    override func read(from data: Data, ofType typeName: String) throws {
        // Insert code here to read your document from the given data of the specified type. If outError != nil, ensure that you create and set an appropriate error when returning false.
        // You can also choose to override readFromFileWrapper:ofType:error: or readFromURL:ofType:error: instead.
        // If you override either of these, you should also override -isEntireFileLoaded to return false if the contents are lazily loaded.
        throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
    }

    // ofType typeName  UTI 字符串，描述文件类型
    /// 保存文件
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        // 转 data
        let textRTFData = try self.text001.data(
            from: NSRange(0..<self.text001.length),
            documentAttributes:
            [NSAttributedString.DocumentAttributeKey.documentType : NSAttributedString.DocumentType.rtf]
        )

        // 删旧的
        if let oldTextFileWrapper = self.documentFileWrapper.fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
        // 加新的
        self.documentFileWrapper.addRegularFile(withContents: textRTFData, preferredFilename: NoteDocumentFileNames.TextFile.rawValue)
        
        
        return self.documentFileWrapper
    }
    
    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        // 取 文件白装器
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(code: ErrorCode.CannotLoadFileWrappers)
        }
        
        // 取出 文档的文本
        guard let documentTextData = fileWrappers[NoteDocumentFileNames.TextFile.rawValue]?.regularFileContents else {
            throw err(code: .CannotLoadText)
        }
        
        // 加载 RTF 格式的文本数据
        guard let documentText = NSAttributedString(rtf: documentTextData, documentAttributes: nil) else {
            throw err(code: .CannotLoadText)
        }
        
        // 内容存到内存
        self.documentFileWrapper = fileWrapper
        
        self.text001 = documentText
        
    }
    
    
    
}

