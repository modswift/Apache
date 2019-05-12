//
// Copyright (C) 2017-2019 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

@_exported import CAPR
@_exported import CAPRUtil
@_exported import CApache

public typealias RequestRecPtr = UnsafeMutablePointer<request_rec>?

// TODO: 80 width

public extension ApacheRequest {
  
  /* Again, this crashes swiftc. whether class or struct. We cannot
     make this a pure Swift wrapper :-/
     TODO(2019-05-12): check whether this is still true in Swift 5
  var raw : UnsafeMutablePointer<request_rec>!
  init(raw: UnsafeMutablePointer<request_rec>!) { self.raw = raw }
  */
  
  @inlinable
  var method            : String  { return raw.pointee.oMethod            }
  @inlinable
  var uri               : String  { return raw.pointee.oURI               }
  @inlinable
  var unparsedURI       : String  { return raw.pointee.oUnparsedURI       }
  @inlinable
  var handler           : String  { return raw.pointee.oHandler           }
  @inlinable
  var theRequest        : String  { return raw.pointee.oTheRequest        }
  @inlinable
  var `protocol`        : String  { return raw.pointee.oProtocol          }
  @inlinable
  var hostname          : String  { return raw.pointee.oHostname          }
  @inlinable
  var filename          : String? { return raw.pointee.oFilename          }
  @inlinable
  var canonicalFilename : String? { return raw.pointee.oCanonicalFilename }
  @inlinable
  var contentEncoding   : String? { return raw.pointee.oContentEncoding   }
  @inlinable
  var user              : String? { return raw.pointee.oUser              }
  @inlinable
  var apAuthType        : String? { return raw.pointee.oApAuthType        }
  @inlinable
  var pathInfo          : String  { return raw.pointee.oPathInfo          }
  @inlinable
  var args              : String? { return raw.pointee.oArgs              }
  
  @inlinable
  var contentType : String? {
    set { raw.pointee.oContentType = newValue }
    get { return raw.pointee.oContentType }
  }
  
  @inlinable
  var headersIn     : APRTable { return APRTable(raw.pointee.headers_in)      }
  @inlinable
  var headersOut    : APRTable { return APRTable(raw.pointee.headers_out)     }
  @inlinable
  var errHeadersOut : APRTable { return APRTable(raw.pointee.err_headers_out) }
  @inlinable
  var trailersIn    : APRTable { return APRTable(raw.pointee.trailers_in)     }
  @inlinable
  var trailersOut   : APRTable { return APRTable(raw.pointee.trailers_out)    }
  @inlinable
  var subprocessEnv : APRTable { return APRTable(raw.pointee.subprocess_env)  }
  @inlinable
  var notes         : APRTable { return APRTable(raw.pointee.notes)           }
  @inlinable
  var bodyTable     : APRTable { return APRTable(raw.pointee.body_table)      }
  
  @inlinable
  var status        : apr_status_t       { return raw.pointee.status       }
  @inlinable
  var requestTime   : apr_time_t         { return raw.pointee.request_time }
  @inlinable
  var finfo         : apr_finfo_t        { return raw.pointee.finfo        }
  
  @inlinable
  var pool          : OpaquePointer!     { return raw.pointee.pool         }

  /* TODO:
   struct ap_conf_vector_t *per_dir_config;
   struct ap_conf_vector_t *request_config;
   */
  
  var description : String {
    return "<Req: \(method) \(uri)>"
  }
}

public extension ApacheRequest { // Output
  
  @inlinable
  func puts(_ s: String) { ap_rputs(s, raw) }
  
}

public extension ApacheRequest { // Misc wrappers for http_core
  
  @inlinable
  var allowOptions        : Int32      { return ap_allow_options  (raw)    }
  @inlinable
  var allowOverrides      : Int32      { return ap_allow_overrides(raw)    }
  @inlinable
  var serverPort          : apr_port_t { return ap_get_server_port(raw)    }
  @inlinable
  var requestBodyLimit    : apr_off_t  { return ap_get_limit_req_body(raw) }
  @inlinable
  var xmlRequestBodyLimit : apr_size_t { return ap_get_limit_xml_body(raw) }
  
  @inlinable
  var isRecursionLimitExceeded : Bool {
    return ap_is_recursion_limit_exceeded(raw) != 0
  }
  
  // docs say: don't use this ;-> (cause Userdir)
  @inlinable
  var documentRoot    : String { return String(cString: ap_document_root(raw)) }
 
  @inlinable
  var remoteLoginName : String? {
    guard let s = ap_get_remote_logname(raw) else { return nil }
    return String(cString: s)
  }
  
  @inlinable
  var serverName : String { return String(cString: ap_get_server_name(raw)) }
  
  @inlinable
  var serverNameForURL : String {
    return String(cString: ap_get_server_name_for_url(raw))
  }
  
  @inlinable
  func doesConfigDefineExist(_ name: String) -> Bool {
    return ap_exists_config_define(name) != 0
  }
}

public extension ApacheRequest { // Auth wrappers for http_core
  
  @inlinable
  var authType : String? {
    guard let s = ap_auth_type(raw) else { return nil }
    return String(cString: s)
  }

  @inlinable
  var authName : String? { // the realm
    guard let s = ap_auth_name(raw) else { return nil }
    return String(cString: s)
  }
  
  @inlinable
  var satisfies : Int32 { // SATISFY_ANY, SATISFY_ALL, SATISFY_NOSPEC
    return ap_satisfies(raw)
  }
}

public extension ApacheRequest { // Logging
  
  @inlinable
  func log(file   : String = #file,
           line   : Int    = #line,
           level  : Int32  = APLOG_WARNING,
           status : apr_status_t? = nil,
           _ s    : String)
  {
    let lStatus = status ?? self.status
    
    apz_log_rerror_(file, Int32(line), -1 /*TBD*/, level, lStatus, raw, s)
  }
}
