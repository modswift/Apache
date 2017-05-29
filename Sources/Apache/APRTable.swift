//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import CAPR

// Apache Table Wrapper

// TODO: make a collection etc

public class APRTable {
  
  public let table : OpaquePointer!
  
  public init(_ table: OpaquePointer!) {
    self.table = table
  }
  
  public subscript(_ key : String) -> String? {
    // case-insensitive!
    // set - needs a pool
    set {
      if let v = newValue {
        apr_table_set(table, key, v)
      }
      else {
        apr_table_unset(table, key)
      }
    }
    get {
      guard let v = apr_table_get(table, key) else { return nil }
      return String(cString: v)
    }
  }
  
  public var isEmpty : Bool {
    return apr_is_empty_table(table) != 0
  }
  
  public func removeAll() {
    apr_table_clear(table)
  }
  
  public func removeValue(forKey key: String) {
    apr_table_unset(table, key)
  }
}
