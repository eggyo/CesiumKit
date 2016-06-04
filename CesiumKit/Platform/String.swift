//
//  String.swift
//  CesiumKit
//
//  Created by Ryan Walklin on 28/11/14.
//  Copyright (c) 2014 Test Toast. All rights reserved.
//

import Foundation

enum ObjectSourceReferenceType {
    case BundleResource
    case NetworkURL
    case FilePath
}

extension String {
    subscript (r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound)
            
            return self[startIndex..<endIndex]
        }
    }
    
    func replace(existingString: String, _ newString: String) -> String {
        return (self as! NSString).replacingOccurrences(of: existingString, with: newString, options: .literalSearch, range: NSRange(location: 0, length: (self as! NSString).length))
    }
    
    func indexOf(findStr:String, startIndex: String.Index? = nil) -> String.Index? {
        let range = (self as! NSString).range(of: findStr, options: [], range: NSRange(location: 0, length: (self as! NSString).length), locale: nil)
        return self.index(startIndex ?? self.startIndex, offsetBy: range.location)
    }
    
}
// FIXME: move to cubemap
extension String {
    var referenceType: ObjectSourceReferenceType {
        if self.hasPrefix("/") {
            return .FilePath
        } else if self.hasPrefix("http") {
            return .NetworkURL
        }
        return .BundleResource
    }
    
    
    func urlForSource () -> NSURL? {
        switch self.referenceType {
        case .BundleResource:
            let bundle = NSBundle(identifier: "com.testtoast.CesiumKit") ?? NSBundle.main()
            #if os(OSX)
                return bundle.url(forImageResource: self)
            #elseif os(iOS)
                return bundle.URLForResource((self as NSString).stringByDeletingPathExtension, withExtension: (self as NSString).pathExtension)
            #endif
        case .FilePath:
            return NSURL(fileURLWithPath: self, isDirectory: false)
        case .NetworkURL:
            return NSURL(string: self)
        }
    }
    
    func loadImageForCubeMapSource () -> CGImage? {

        guard let sourceURL = urlForSource() else {
            return nil
        }
        do {
            let data = try NSData(contentsOf: sourceURL, options: [])
            return CGImage.from(data: data)
        } catch {
            return nil
        }

    }
    
}