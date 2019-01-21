//
//  BlockTag.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/7/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import BigInt

public class BlockTag {
    
    private var blockHeight: BigInt
    private var defaultBlock: DefaultBlock

    public enum DefaultBlock: String {
        
        case EARLIEST = "earliest"
        case LATEST = "latest"
        case NONE = "none"

        static func toString(int: BigInt) -> String {
            return String(int)
        }
    }
    
    public init(str: String) {
        self.blockHeight = BigInt(stringLiteral: str)
        self.defaultBlock = DefaultBlock.NONE
    }
    
    public init(block: DefaultBlock) {
        self.blockHeight = BigInt.init()
        self.defaultBlock = block
    }
    
    public func getBlockTagString() -> String? {
        if !self.blockHeight.isZero {
            return self.blockHeight.toString(radix: 16, lowercase: true);
        } else if(self.defaultBlock != DefaultBlock.NONE) {
            return self.defaultBlock.rawValue;
        }
        return nil;
    }
}

extension BigInt {
    
    public func isNegative() -> Bool {
        return false
    }
    
    public func toString(radix: Int = 10, lowercase: Bool = true) -> String {
        assert(2...36 ~= radix, "radix must be in range 2...36")
        
        let digitsStart = ("0" as Unicode.Scalar).value
        let lettersStart = ((lowercase ? "a" : "A") as Unicode.Scalar).value - 10
        func toLetter(_ x: UInt32) -> Unicode.Scalar {
            return x < 10
                ? Unicode.Scalar(digitsStart + x)!
                : Unicode.Scalar(lettersStart + x)!
        }
        
        let radix = BigInt(radix)
        var result: [Unicode.Scalar] = []
        
        var x = self
        while !x.isZero {
            let remainder: BigInt
            (x, remainder) = x.quotientAndRemainder(dividingBy: radix)
            result.append(toLetter(UInt32(remainder)))
        }
        
        let sign = isNegative() ? "-" : ""
        let rest = result.count == 0
            ? "0"
            : String(String.UnicodeScalarView(result.reversed()))
        return sign + rest
    }
}
