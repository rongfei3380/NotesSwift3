//
//  Document.swift
//  note
//
//  Created by chengfei on 2018/9/9.
//  Copyright © 2018 chengfeir. All rights reserved.
//

import Cocoa
import MapKit

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
    
    var popover : NSPopover?
    

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

    override func windowControllerDidLoadNib(_ windowController: NSWindowController) {
        self.attachmentsList.register(forDraggedTypes: [NSURLPboardType])
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
                
        let thumbnailImageData =
            self.iconImageDataWithSize(size: CGSize(width: 512, height: 512))!
        let thumbnailWrapper =
            FileWrapper(regularFileWithContents: thumbnailImageData as Data)
        
        let quicklookPreview =
            FileWrapper(regularFileWithContents: textRTFData)
        
        let quickLookFolderFileWrapper =
            FileWrapper(directoryWithFileWrappers: [
                NoteDocumentFileNames.QuickLookTextFile.rawValue: quicklookPreview,
                NoteDocumentFileNames.QuickLookThumbnail.rawValue: thumbnailWrapper
                ])
        
        quickLookFolderFileWrapper.preferredFilename
            = NoteDocumentFileNames.QuickLookDirectory.rawValue
        
        // Remove the old QuickLook folder if it existed
        if let oldQuickLookFolder = self.documentFileWrapper
            .fileWrappers?[NoteDocumentFileNames.QuickLookDirectory.rawValue] {
            self.documentFileWrapper.removeFileWrapper(oldQuickLookFolder)
        }
        
        // Add the new QuickLook folder
        self.documentFileWrapper.addFileWrapper(quickLookFolderFileWrapper)
        // END file_wrapper_of_type_quicklook
        
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
    
    private var attachmentsDirectoryWrapper : FileWrapper? {
        guard let fileWrappers = self.documentFileWrapper.fileWrappers else {
            NSLog("Attempting to access document's contents, but none found!")
            return nil
        }
        
        var attachmentsDirectoryWrapper = fileWrappers[NoteDocumentFileNames.AttachmentsDirectory.rawValue]
        
        if attachmentsDirectoryWrapper == nil {
            attachmentsDirectoryWrapper = FileWrapper(directoryWithFileWrappers: [:])
            
            attachmentsDirectoryWrapper?.preferredFilename = NoteDocumentFileNames.AttachmentsDirectory.rawValue
            
            self.documentFileWrapper.addFileWrapper(attachmentsDirectoryWrapper!)
        }
        
        
        return attachmentsDirectoryWrapper
    }
    
    
    func addAttachmentAtURL(url : NSURL) throws {
        guard attachmentsDirectoryWrapper != nil else {
            throw err(.cannotAccessAttachments)
        }
        
        self.willChangeValue(forKey: "attachedFiles")
        
        let newAttachment = try FileWrapper(url: url as URL, options: FileWrapper.ReadingOptions.immediate)
        
        attachmentsDirectoryWrapper?.addFileWrapper(newAttachment)
        self.updateChangeCount(.changeDone)
        self.didChangeValue(forKey: "attachedFiles")
    }
    
    dynamic var attachedFiles : [FileWrapper]? {
        if let attachmentsFileWrappers = self.attachmentsDirectoryWrapper?.fileWrappers {
            let attachments = Array(attachmentsFileWrappers.values)
            return attachments
        } else {
            return nil
        }
    }
    
    @IBAction func addAttachment(_ sender: NSButton) {
        if let viewController = AddAttachmentViewController(nibName: "AddAttachmentViewController", bundle: Bundle.main) {
            viewController.delagate = self
            
            self.popover = NSPopover()
            self.popover?.behavior = .transient
            self.popover?.contentViewController = viewController
            self.popover?.show(relativeTo: sender.bounds, of: sender, preferredEdge: NSRectEdge.maxY)
        }
    }
    
    func iconImageDataWithSize(size : CGSize) -> NSData? {
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let entireImageRect = CGRect(origin: CGPoint.zero, size: size)
        
        // 白色背景填充
        let backgroudRect = NSBezierPath(rect: entireImageRect)
        NSColor.white.setFill()
        backgroudRect.fill()
        
        if (self.attachedFiles?.count)! >= 1{
            // 渲染文本和第一个附件
            let attachmentImage = self.attachedFiles?[0].thumbnailImage
            let result = entireImageRect.divided(atDistance: entireImageRect.size.height/2.0, from: CGRectEdge.minYEdge)
            self.text001.draw(in: result.slice)
            attachmentImage?.draw(in: result.remainder)
        } else {
            self.text001.draw(in: entireImageRect)
        }
        
        let bitmapRepresentation = NSBitmapImageRep(focusedViewRect: entireImageRect)
        
        image.unlockFocus()
        
        return bitmapRepresentation?.representation(using: .PNG, properties: [:]) as NSData?
    }
}

extension Document : AddAttachmentDelegate {
    func addFile() {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        
        panel.begin { (result) -> Void in
            if result == NSModalResponseOK, let resultURL = panel.urls.first {
                do {
                    try self.addAttachmentAtURL(url: resultURL as NSURL)
                    self.attachmentsList.reloadData()
                } catch let error as NSError {
                    if let window = self.windowForSheet {
                        NSApp.presentError(error, modalFor: window, delegate: nil, didPresent: nil, contextInfo: nil)
                    } else {
                        NSApp.presentError(error)
                    }
                }

            }
        }
    }
}

extension Document : NSCollectionViewDataSource {
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.attachedFiles?.count ?? 0
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let attachment = self.attachedFiles![indexPath.item]
        
        let item = collectionView.makeItem(withIdentifier: "AttachmentCell", for: indexPath) as! AttachmentCell
        
        item.imageView?.image = attachment.thumbnailImage
        item.textField?.stringValue = attachment.fileExtension ?? ""
        item.delegate = self
        
        return item
    }
    
}

extension Document : AttachmentCellDelegate {
    func openSelectedAttachment(collectionItem: NSCollectionViewItem) {
        guard let selectedIndex = self.attachmentsList.indexPath(for: collectionItem)?.item else {
            return
        }
        
        guard let attachment = self.attachedFiles?[selectedIndex] else {
            return
        }
        
        self.autosave(withImplicitCancellability: false) { (error) in
            
            if attachment.conformsToType(type: kUTTypeJSON), let data = attachment.regularFileContents, let json = try? JSONSerialization.jsonObject(with: data, options: JSONSerialization.ReadingOptions.mutableLeaves) as? NSDictionary{
                if  let lat = json?["lat"] as? CLLocationDegrees,
                    let lon = json?["long"] as? CLLocationDegrees{
                    
                    let coordinate = CLLocationCoordinate2DMake(lat, lon)
//                    创建地标
                    let placemark = MKPlacemark.init(coordinate: coordinate, addressDictionary: nil)
                    //                    使用地标创建 地图项目
                    let mapItem = MKMapItem.init(placemark: placemark)
                    // 在地图项目中打开
                    mapItem.openInMaps(launchOptions: nil)
                    
                }
                
            } else {
                var url = self.fileURL
                url = url?.appendingPathComponent(NoteDocumentFileNames.AttachmentsDirectory.rawValue, isDirectory: true)
                url = url?.appendingPathComponent(attachment.preferredFilename!)
                if let path = url?.path {
                    NSWorkspace.shared().openFile(path, withApplication: nil, andDeactivate: true)
                }
            }
            
            
        }
    }
}

extension Document : NSCollectionViewDelegate {
    func collectionView(_ collectionView: NSCollectionView, validateDrop draggingInfo: NSDraggingInfo, proposedIndexPath proposedDropIndexPath: AutoreleasingUnsafeMutablePointer<NSIndexPath>, dropOperation proposedDropOperation: UnsafeMutablePointer<NSCollectionViewDropOperation>) -> NSDragOperation {
        return NSDragOperation.copy
    }
    func collectionView(_ collectionView: NSCollectionView,
                        acceptDrop draggingInfo: NSDraggingInfo,
                        indexPath: IndexPath,
                        dropOperation: NSCollectionViewDropOperation) -> Bool {
        let pasteboard = draggingInfo.draggingPasteboard()
        
        if pasteboard.types?.contains(NSURLPboardType) == true,
            let url = NSURL(from : pasteboard){
            do {
                try self.addAttachmentAtURL(url: url)
                
                attachmentsList.reloadData()
                return true
            } catch let error as NSError {
                self.presentError(error)
                return false
            }
        }
        return false
    }
}

