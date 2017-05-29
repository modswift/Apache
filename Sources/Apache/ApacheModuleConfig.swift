//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import CAPR
import CApache

public protocol ApacheModuleConfig : class {

  func merge(with new: Self) -> Self?
  
}

public extension ApacheModuleConfig {

  static func merge(base: Self?, new: Self?) -> Self? {
    // print("merge dir cfg: \(base) \(new)")
    if base == nil { return new  }
    if new  == nil { return base }
    return base!.merge(with: new!)
  }
  
  static func merge(_ pool: OpaquePointer?,
                    _ base: UnsafeMutableRawPointer?,
                    _ new:  UnsafeMutableRawPointer?)
              -> UnsafeMutableRawPointer?
  {
    let baseCfg = Self.fromOpaque(base)
    let newCfg  = Self.fromOpaque(new)
    let merged  = Self.merge(base: baseCfg, new: newCfg)
    // TODO: dealloc in pool
    return merged?.passRetained()
  }
  
  static func fromOpaque(_ ptr : UnsafeMutableRawPointer?) -> Self? {
    guard let ptr = ptr else { return nil }
    return Unmanaged<Self>.fromOpaque(ptr).takeUnretainedValue()
  }
  
  func passRetained() -> UnsafeMutableRawPointer {
    return Unmanaged.passRetained(self).toOpaque()
  }
  
}

public final class ApacheDictionaryConfig
                 : ApacheModuleConfig, CustomStringConvertible
{
  
  public var values = [ String : String ]()
  
  public func merge(with new: ApacheDictionaryConfig) 
              -> ApacheDictionaryConfig? 
  {
    let merged = ApacheDictionaryConfig()
    merged.values = values
    for (k, v) in new.values {
      merged.values.updateValue(v, forKey: k)
    }
    // print("merge \(self) + \(new) dir cfg: \(merged)")
    return merged
  }
  
  public subscript(_ key : String) -> String? {
    get { return values[key] }
    set { values[key] = newValue }
  }
  
  
  // MARK: - Logging
  
  public var description : String {
    return "<ApacheConfig: \(values)>"
  }


  // MARK: - Callbacks
  
  public static func create(_ pool: OpaquePointer?,
                            _ dirname: UnsafeMutablePointer<Int8>?)
                     -> UnsafeMutableRawPointer?
  {
    //let path = dirname != nil ? String(cString: dirname!) : nil
    
    let cfg = ApacheDictionaryConfig()
    // print("create dir cfg, path: \(path ?? "-")")
    
    // TODO: dealloc in pool
    
    return cfg.passRetained()
  }
}