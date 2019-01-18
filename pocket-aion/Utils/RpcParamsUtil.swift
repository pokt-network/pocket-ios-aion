//
//  RpcParamsUtil.swift
//  pocket-aion
//
//  Created by Pabel Nunez Landestoy on 1/18/19.
//  Copyright © 2019 Pocket Network. All rights reserved.
//

import Foundation
import BigInt

public class RpcParamsUtil {
    
    public static func formatRpcParams(params: [Any]) -> [String]?{
        var results = [Any]()
        var resultStrArray = [String]()
        
        for objParam in params {
            var currStr: String?
            
            if let objParamArray = objParam as? [Any]{
                let objStrings = self.objectsAsRpcParams(objParams: objParamArray)
                guard let result = String.join(char: ",", array: objStrings) else{
                    return nil
                }
                currStr = "[\(result)]"
            } else{
                currStr = self.objectAsRpcParam(objParam: objParam)
            }
            results.append(currStr ?? "")
        }
        
        for item in results {
            resultStrArray.append(item as? String ?? "")
        }
        
        return resultStrArray
    }
    
    private static func objectsAsRpcParams(objParams: [Any]) ->[String]{
        var result = [String]()
        
        for objParam in objParams {
            if let objParamStr = objectAsRpcParam(objParam: objParam) {
                result.append(objParamStr)
            }
        }
        return result
    }
    
    private static func objectAsRpcParam(objParam: Any) -> String?{
        var currStr = ""
        
        if objParam is Bool ||
            objParam is Double ||
            objParam is Float ||
            objParam is Int ||
            objParam is Int64 ||// long
            objParam is UInt8 ||// byte
            objParam is Int16// short
        {
            guard let strValue = objParam as? String else{
                return nil
            }
            return strValue
        }else if objParam is String {
            currStr = "\"\(objParam)\""
        }else if objParam is BigInt {
            let objParamString = (objParam as! BigInt).toString(radix: 16)
            let formattedObjParam = HexStringUtil.prependZeroX(hex: objParamString)
            currStr = "\"\(formattedObjParam)\""
        }
        return currStr
    }
}
