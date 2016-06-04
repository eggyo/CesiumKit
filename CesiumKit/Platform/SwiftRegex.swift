//
//  SwiftRegex.swift
//  SwiftRegex
//
//  Created by John Holdsworth on 26/06/2014.
//  Copyright (c) 2014 John Holdsworth.
//
//  $Id: //depot/SwiftRegex/SwiftRegex.swift#37 $
//
//  This code is in the public domain from:
//  https://github.com/johnno1962/SwiftRegex
//

import Foundation

var swiftRegexCache = Dictionary<String,NSRegularExpression>()

public class SwiftRegex: NSObject, Boolean {
    
    var target: NSString
    var regex: NSRegularExpression
    
    init(target:NSString, pattern:String, options: NSRegularExpressionOptions = NSRegularExpressionOptions(rawValue: 0)) {
        self.target = target
        if let regex = swiftRegexCache[pattern] {
            self.regex = regex
        } else {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options:options)
                swiftRegexCache[pattern] = regex
                self.regex = regex
            } catch let error as NSError {
                SwiftRegex.failure(message: "Error in pattern: \(pattern) - \(error)")
                self.regex = NSRegularExpression()
            }
        }
        super.init()
    }
    
    class func failure(message: String) {
        print("SwiftRegex: "+message)
        //assert(false,"SwiftRegex: failed")
    }
    
    final var targetRange: NSRange {
        return NSRange(location: 0,length: target.length)
    }
    
    final func substring(range: NSRange) -> String {
        if ( range.location != NSNotFound ) {
            return target.substring(with: range)
        } else {
            return ""
        }
    }
    
    public func doesMatch(options: NSMatchingOptions = NSMatchingOptions()) -> Bool {
        return range(options: options).location != NSNotFound
    }
    
    public func range(options: NSMatchingOptions = NSMatchingOptions()) -> NSRange {
        return regex.rangeOfFirstMatch(in: target as String, options: [], range: targetRange)
    }
    
    public func match(options: NSMatchingOptions = NSMatchingOptions()) -> String! {
        return substring(range: range(options: options)) as String
    }
    
    public func groups(options: NSMatchingOptions = NSMatchingOptions()) -> [String]! {
        return groupsForMatch(match: regex.firstMatch(in: target as String, options: options, range: targetRange) )
    }
    
    func groupsForMatch(match: NSTextCheckingResult!) -> [String]! {
        if match != nil {
            var groups = [String]()
            for groupno in 0...regex.numberOfCaptureGroups {
                if let group = substring(range: match.range(at: groupno)) as String! {
                    groups += [group]
                } else {
                    groups += ["_"] // avoids bridging problems
                }
            }
            return groups
        } else {
            return nil
        }
    }
    
    public subscript(groupno: Int) -> String! {
        get {
            return groups()[groupno]
        }
        set(newValue) {
            if let mutableTarget = target as? NSMutableString {
                for match in Array(matchResults().reversed()) {
                    let replacement = regex.replacementString(for: match as! NSTextCheckingResult,
                                                              in: target as String,
                                                              offset: 0,
                                                              template: newValue)
                    mutableTarget.replaceCharacters(in: match.range(groupno), with: replacement)
                }
            } else {
                SwiftRegex.failure(message: "Group modify on non-mutable")
            }
        }
    }
    
    func matchResults(options: NSMatchingOptions = NSMatchingOptions()) -> [AnyObject] {
        return regex.matches(in: target as String, options: options, range: targetRange)
    }
    
    public func ranges(options: NSMatchingOptions = NSMatchingOptions()) -> [NSRange] {
        return matchResults(options: options).map { $0.range }
    }
    
    public func matches(options: NSMatchingOptions = NSMatchingOptions()) -> [String] {
        return matchResults(options: options).map { self.substring(range: $0.range) }
    }
    
    public func allGroups(options: NSMatchingOptions = NSMatchingOptions()) -> [[String]] {
        return matchResults(options: options).map { self.groupsForMatch(match: $0 as! NSTextCheckingResult) }
    }
    
    public func dictionary(options: NSMatchingOptions = NSMatchingOptions()) -> Dictionary<String,String> {
        var out = Dictionary<String,String>()
        for match in matchResults(options: options) {
            out[substring(range: match.range(1)) as String] =
                substring(range: match.range(2)) as String
        }
        return out
    }
    
    func substituteMatches(options: NSMatchingOptions = NSMatchingOptions(), substitution: (NSTextCheckingResult, UnsafeMutablePointer<ObjCBool>) -> String) -> String {
            var out = "" //NSMutableString()
            var pos = 0
        
            regex.enumerateMatches(in: target as String, options: options, range: targetRange ) {
                (match: NSTextCheckingResult?, flags: NSMatchingFlags, stop: UnsafeMutablePointer<ObjCBool>) in
                
                let matchRange = match!.range
                out += self.substring(range: NSRange(location:pos, length:matchRange.location-pos))
                out += (substitution(match!, stop))
                pos = matchRange.location + matchRange.length
            }
            
            out += substring(range: NSRange(location:pos, length:targetRange.length-pos))
            
            return out
    }
    
    public var boolValue: Bool {
        return doesMatch()
    }
}

extension NSString {
    public subscript(pattern: String, options: NSRegularExpressionOptions) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern, options: options)
    }
}

extension NSString {
    public subscript(pattern: String) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern)
    }
}

extension String {
    public subscript(pattern: String, options: NSRegularExpressionOptions) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern, options: options)
    }
}

extension String {
    public subscript(pattern: String) -> SwiftRegex {
        return SwiftRegex(target: self, pattern: pattern)
    }
}

public func RegexMutable(string: NSString) -> NSMutableString {
    return NSMutableString(string:string as String)
}

