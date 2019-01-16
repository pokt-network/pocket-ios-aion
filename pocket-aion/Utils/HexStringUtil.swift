//
//  HexStringUtil.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/16/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation

public class HexStringUtil {
    
    private static let ZERO_X = "0x";
    
    public static func prependZeroX(hex: String) -> String{
        if (self.hasZeroHexPrefix(hex: hex)) {
            return hex
        } else {
            return ZERO_X + hex
        }
    }
    
    public static func removeLeadingZeroX(hex: String) -> String? {
        if hasZeroHexPrefix(hex: hex) {
            if hex.count > ZERO_X.count {
                return String(hex.dropLast(2))
            }else{
                return nil
            }
        }else{
            return hex
        }
    }
    
    public static func hasZeroHexPrefix(hex: String) -> Bool{

        if hex.hasPrefix(ZERO_X) {
            return true
        }
        return false
    }
}
