//
//  Document.swift
//  note
//
//  Created by chengfei on 2018/9/9.
//  Copyright © 2018 chengfeir. All rights reserved.
//

import Cocoa

extension FileWrapper {
    dynamic var fileExtension : String? {
        return self.preferredFilename?.components(separatedBy: ".").last
    }
    
    dynamic var thumbnailImage : NSImage {
        if let fileExtension = self.fileExtension {
            return NSWorkspace.shared().icon(forFileType: fileExtension)
        } else {
            return NSWorkspace.shared().icon(forFileType: "")
        }
    }
    
    func conformsToType(type: CFString) -> Bool {
        guard let fileExtension = self.fileExtension else {
            return false
        }
        
        guard let fileType = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExtension as CFString, nil)?.takeRetainedValue() else {
            return false
        }
        
        return UTTypeConformsTo(fileType, type)
    }

}


class Document: NSDocument {

    var text001 : NSAttributedString = NSAttributedString()
    
    var documentFileWrapper = FileWrapper(directoryWithFileWrappers: [:])

    @IBOutlet var attachmentsList : NSCollectionView!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class func autosavesInPlace() -> Bool {
        return true
    }

    // BEGIN osx_window_nib_name
    override var windowNibName: String? {
        //- Returns the nib file name of the document
        //- If you need to use a subclass of NSWindowController or if your
        // document supports multiple NSWindowControllers, you should remove
        // this property and override -makeWindowControllers instead.
        return "Document"
    }
    // END osx_window_nib_name

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

    override func read(from fileWrapper: FileWrapper,
                       ofType typeName: String) throws {
        
        // Ensure that we have additional file wrappers in this file wrapper
        guard let fileWrappers = fileWrapper.fileWrappers else {
            throw err(.cannotLoadFileWrappers)
        }
        
        // Ensure that we can access the document text
        guard let documentTextData =
            fileWrappers[NoteDocumentFileNames.TextFile.rawValue]?
                .regularFileContents else {
                    throw err(.cannotLoadText)
        }
        
        // BEGIN error_example
        // Load the text data as RTF
        guard let documentText = NSAttributedString(rtf: documentTextData,
                                                    documentAttributes: nil) else {
                                                        throw err(.cannotLoadText)
        }
        // END error_example
        
        // Keep the text in memory
        self.documentFileWrapper = fileWrapper
        
        self.text001 = documentText
    }
    
    // BEGIN file_wrapper_of_type
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        
        // BEGIN file_wrapper_of_type_rtf_load
        let textRTFData = try self.text001.data(
            from: NSRange(0..<self.text001.length),
            documentAttributes: [
                NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType
            ]
        )
        // END file_wrapper_of_type_rtf_load
        
        // If the current document file wrapper already contains a
        // text file, remove it - we'll replace it with a new one
        if let oldTextFileWrapper = self.documentFileWrapper
            .fileWrappers?[NoteDocumentFileNames.TextFile.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldTextFileWrapper)
        }
                
        // Save the text data into the file
        self.documentFileWrapper.addRegularFile(
            withContents: textRTFData,
            preferredFilename: NoteDocumentFileNames.TextFile.rawValue
        )
        
        // Return the main document's file wrapper - this is what will
        // be saved on disk
        return self.documentFileWrapper
    }
    // END file_wrapper_of_type
    
    @IBAction func addAttachment(_ sender: Any) {
        
    }
}

