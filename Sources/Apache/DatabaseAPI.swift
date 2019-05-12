//
// Copyright (C) 2017-2019 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import CApache

// TODO:
// - throw errors
//
// TBD:
// - move out to own package?
// - maybe drop the protocols, kinda overkill as there is only one imp
//   and other stuff will build on top of this and come with own
//   protocols.


// apr_dbd_results_t is opaque

public extension ApacheRequest {
  
  // Note: func types with UnsafeMutablePointer<request_rec>? coredump swiftc
  // own typealias w/o request_rec
  fileprivate typealias aprz_OFN_ap_dbd_acquire_t = @convention(c)
    ( UnsafeMutableRawPointer? ) -> UnsafeMutablePointer<ap_dbd_t>?
  
  func dbdAcquire(pool: OpaquePointer? = nil) -> DBDConnectionType? {
    let ap_dbd_acquire : aprz_OFN_ap_dbd_acquire_t? =
                           APR_RETRIEVE_OPTIONAL_FN("ap_dbd_acquire")
    if ap_dbd_acquire == nil {
      print("\(#function): missing ap_dbd_acquire func (mod_dbd not loaded?)")
      return nil
    }
    guard let dbd = ap_dbd_acquire?(self.raw)
     else {
      print("\(#function): ap_dbd_acquire() failed")
      return nil
     }
    
    return DBDConnection(connection: dbd, pool: pool ?? self.pool)
  }
  
}


// MARK: - Generic Interfaces

public protocol DBDConnectionType {
  func select(_ sql: String) -> DBDResultsType?
}

public protocol DBDResultsType { // this does not fly: ": IteratorProtocol {"
  
  func next() -> DBDRowType?
  
  var columnCount : Int { get }
  var count       : Int { get }

  subscript(name index: Int) -> String? { get }
}

public protocol DBDRowType {
  
  /**
   * Return a raw C pointer for the result of the given column index.
   */
  subscript(raw  index: Int) -> UnsafePointer<Int8>! { get }
  
  /**
   * Return the column as a String.
   */
  subscript(index: Int) -> String? { get }

}


// MARK: - Typesafe Wrapper

/**
 * The core idea is that SQL does return typesafe tuples as per select. What if
 * we could use generics to expand to exactly that:
 * Summary: I don't think it is possible as we can't reflect on the type? Well?
 *          We could provide multiple signatures? select<T1,T2,T3,T4>
 *
 * This is what I'd want:
 *
 *     db.select<(Int,String,String)>
 *         ("SELECT id::int,name::text,login::text FROM account")
 *     { tuple in ... }
 *
 * or if we have a model
 *
 *     db.select(Attr.ID, Attr.Name, Attr.Login) { tuple in }
 *
 */

public protocol DBDDecodableType {
  static func from(rawDBValue: UnsafePointer<Int8>?) -> Self
}
extension String : DBDDecodableType {
  public static func from(rawDBValue: UnsafePointer<Int8>?) -> String {
    guard let cstr = rawDBValue else { fatalError("DB type mismatch") }
    return String(cString: cstr)
  }
}
extension Int : DBDDecodableType {
  public static func from(rawDBValue: UnsafePointer<Int8>?) -> Int {
    guard let v = Int(String.from(rawDBValue: rawDBValue)) else {
      fatalError("DB type mismatch")
    }
    return v
  }
}
extension Optional where Wrapped : DBDDecodableType {
  // this is not picked
  // For this: you’ll need conditional conformance. Swift 4, hopefully
  public static func from(rawDBValue: UnsafePointer<Int8>?) 
                     -> Optional<Wrapped> 
  {
    guard let raw = rawDBValue else { return .none }
    return Wrapped.from(rawDBValue: raw)
  }
}
extension Optional : DBDDecodableType {
  public static func from(rawDBValue v: UnsafePointer<Int8>?) 
                     -> Optional<Wrapped> 
  {
    guard let c = Wrapped.self as? DBDDecodableType.Type
     else { return nil }
    
    return c.from(rawDBValue: v) as? Wrapped
  }
}

public extension DBDConnectionType {
  // Note: there would need to be one func for each argument-count (I think)

  /**
   * Select columns in a type-safe way.
   *
   * Example, not how the type is derived from what the closure expects:
   *
   *     dbd.select("SELECT * FROM pets") { (name : String, count : Int?) in
   *       req.puts("<li>\(name) (\(count))</li>")
   *     }
   */
  func select<T0, T1>(_ sql: String, cb : ( T0, T1 ) -> Void)
         where T0 : DBDDecodableType, T1 : DBDDecodableType
  {
    guard let results = select(sql) else { return }
    
    while let result = results.next() {
      cb(T0.from(rawDBValue: result[raw: 0]),
         T1.from(rawDBValue: result[raw: 1]))
    }
  }
  func select<T0>(_ sql: String, cb : ( T0 ) -> Void)
         where T0 : DBDDecodableType
  {
    guard let results = select(sql) else { return }
    
    while let result = results.next() {
      cb(T0.from(rawDBValue: result[raw: 0]))
    }
  }
  func select<T0, T1, T2>(_ sql: String, cb : ( T0, T1, T2 ) -> Void)
         where T0 : DBDDecodableType, T1 : DBDDecodableType,
               T2 : DBDDecodableType
  {
    guard let results = select(sql) else { return }
    
    while let result = results.next() {
      cb(T0.from(rawDBValue: result[raw: 0]),
         T1.from(rawDBValue: result[raw: 1]),
         T2.from(rawDBValue: result[raw: 2]))
    }
  }
  
}


// MARK: - Model Based Typesafe Wrapper

public struct Attribute<T: DBDDecodableType> {
  
  public let name : String
  
  public init(name: String) {
    self.name = name
  }
  
  public func from(rawDBValue: UnsafePointer<Int8>?) -> T {
    // This is not strictly necessary, but a 'real' attribute class may want to
    // transform the value somehow.
    return T.from(rawDBValue: rawDBValue)
  }
}

public extension DBDConnectionType {

  /**
   * The idea here is that you rarely want to select full tables aka models.
   * E.g. you may just want to have the first & lastname of a Person. Yet,
   * we still want to use strongly typed data on the client side.
   *
   * Example:
   *
   *     struct Model {
   *       struct Pet {
   *         static let name  = Attribute<String>(name: "name")
   *         static let count = Attribute<Int>   (name: "count")
   *       }
   *     }
   *     dbd.select(Model.Pet.name, Model.Pet.count, from: "pets") { 
   *       name, count in // types are derived from Attribute
   *       req.puts("<tr><td>\(name)</td><td>\(count)</td></tr>")
   *     }
   */
  func select<T0, T1>(_ a0: Attribute<T0>, _ a1: Attribute<T1>,
                      from: String, where w: String? = nil,
                      cb: ( T0, T1 ) -> Void)
  {
    var sql = "SELECT \(a0.name), \(a1.name) FROM \(from)"
    if let w = w { sql += " WHERE \(w)" }
    
    guard let results = select(sql) else { return }
    
    while let result = results.next() {
      cb(a0.from(rawDBValue: result[raw: 0]),
         a1.from(rawDBValue: result[raw: 1]))
    }
  }
  
}


// MARK: - Concrete Implementation of DBD protocols

fileprivate class DBDConnection : DBDConnectionType {
  
  let pool : OpaquePointer
  let con  : UnsafeMutablePointer<ap_dbd_t>
  
  init(connection: UnsafeMutablePointer<ap_dbd_t>, pool: OpaquePointer) {
    self.pool = pool
    self.con = connection
  }
  
  func select(_ sql: String) -> DBDResultsType? {
    var res : OpaquePointer? = nil // UnsafePointer<apr_dbd_results_t>
    
    let rc = apr_dbd_select(con.pointee.driver, pool, con.pointee.handle,
                            &res, sql, 0)
    guard rc == APR_SUCCESS, res != nil else { return nil }
    
    return DBDResults(connection: con, results: res!, pool: pool)
  }
  
  func message(for error: Int32) -> String? {
    let cstr = apr_dbd_error(con.pointee.driver, con.pointee.handle, error)
    return cstr != nil ? String(cString: cstr!) : nil
  }
}

fileprivate class DBDResults : DBDResultsType {

  let pool : OpaquePointer
  let con  : UnsafeMutablePointer<ap_dbd_t>
  let res  : OpaquePointer
  
  init(connection: UnsafeMutablePointer<ap_dbd_t>,
       results: OpaquePointer, pool: OpaquePointer)
  {
    self.pool = pool
    self.con = connection
    self.res = results
  }
  
  func next() -> DBDRowType? {
    var row : OpaquePointer? = nil // UnsafePointer<apr_dbd_row_t>
    let rc  = apr_dbd_get_row(con.pointee.driver, pool, res, &row, -1)
    guard rc == APR_SUCCESS, row != nil else { return nil }
    
    return DBDRow(connection: con, row: row!)
  }
  
  var columnCount : Int {
    return Int(apr_dbd_num_cols(con.pointee.driver, res))
  }
  var count : Int {
    return Int(apr_dbd_num_tuples(con.pointee.driver, res))
  }
  
  subscript(name index: Int) -> String? {
    guard let cstr = apr_dbd_get_name(con.pointee.driver, res, Int32(index))
     else { return nil }
    return String(cString: cstr)
  }
}

fileprivate class DBDRow : DBDRowType {
  
  let con : UnsafeMutablePointer<ap_dbd_t>
  let row : OpaquePointer // UnsafePointer<apr_dbd_row_t>
  
  init(connection: UnsafeMutablePointer<ap_dbd_t>, row: OpaquePointer) {
    self.con = connection
    self.row = row
  }
  
  subscript(raw index: Int) -> UnsafePointer<Int8>! {
    return apr_dbd_get_entry(con.pointee.driver, row, Int32(index))
  }
  subscript(index: Int) -> String? {
    guard let cstr = self[raw: index] else { return nil }
    return String(cString: cstr)
  }
}


// MARK: - Extensions to the Raw API

public extension ap_dbd_t {
  
  func select(_ sql: String, _ pool: OpaquePointer,
              _ res: UnsafeMutablePointer<OpaquePointer?>!)
    -> Int32
  {
    // var res : OpaquePointer? = nil // UnsafePointer<apr_dbd_results_t>
    return apr_dbd_select(driver, pool, handle, res, sql, 0)
  }
}

