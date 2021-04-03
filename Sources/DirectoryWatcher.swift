//
//  FolderWatcher.swift
//  SwiftFormat
//
//  Created by Andrew on 03/04/2021.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

import Foundation

class DirectoryWatcher {
    
    let urls: [URL]
    let callback: ()->Void
    let dispatchQueue: DispatchQueue
    let dispatchSourceSignal: DispatchSourceSignal
    var dispatchSourceFileObjects: [DispatchSourceFileSystemObject]
        
    init(urls: [URL], callback: @escaping ()->Void) {
        self.urls = urls
        self.callback = callback
        self.dispatchQueue = DispatchQueue(label: "DirectoryWatcher", attributes: .concurrent)
        self.dispatchSourceSignal = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        self.dispatchSourceFileObjects = []
    }
    
    func run() {
        cancel()
        
        self.dispatchSourceFileObjects = urls.map { url in
            let fileDescriptor = open((url as NSURL).fileSystemRepresentation, O_EVTONLY)
            let directoryMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor,
                                                                                   eventMask: DispatchSource.FileSystemEvent.write,
                                                                                   queue: dispatchQueue)
            directoryMonitorSource.setEventHandler(handler: callback)
            directoryMonitorSource.setCancelHandler {
                close(directoryMonitorSource.handle)
            }
            
            directoryMonitorSource.resume()
            
            return directoryMonitorSource
        }
                
        self.dispatchSourceSignal.setEventHandler {
            self.cancel()
            exit(EXIT_SUCCESS)
        }
        self.dispatchSourceSignal.resume()

        // Waiting on Run Loop
        RunLoop.current.run()
    }
    
    func cancel() {
        for dispatchSource in dispatchSourceFileObjects {
            dispatchSource.cancel()
        }
        self.dispatchSourceSignal.cancel()
    }
}
