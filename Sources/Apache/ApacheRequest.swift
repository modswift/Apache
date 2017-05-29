//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

@_exported import CAPR
@_exported import CAPRUtil
@_exported import CApache

public typealias RequestRecPtr = UnsafeMutablePointer<request_rec>!

// TODO: 80 width

public extension ApacheRequest {
  
  /* Again, this crashes swiftc. whether class or struct. We cannot
     make this a pure Swift wrapper :-/
  var raw : UnsafeMutablePointer<request_rec>!
  init(raw: UnsafeMutablePointer<request_rec>!) { self.raw = raw }
  */
  
  public var method            : String  { return raw.pointee.oMethod            }
  public var uri               : String  { return raw.pointee.oURI               }
  public var unparsedURI       : String  { return raw.pointee.oUnparsedURI       }
  public var handler           : String  { return raw.pointee.oHandler           }
  public var theRequest        : String  { return raw.pointee.oTheRequest        }
  public var `protocol`        : String  { return raw.pointee.oProtocol          }
  public var hostname          : String  { return raw.pointee.oHostname          }
  public var filename          : String? { return raw.pointee.oFilename          }
  public var canonicalFilename : String? { return raw.pointee.oCanonicalFilename }
  public var contentEncoding   : String? { return raw.pointee.oContentEncoding   }
  public var user              : String? { return raw.pointee.oUser              }
  public var apAuthType        : String? { return raw.pointee.oApAuthType        }
  public var pathInfo          : String  { return raw.pointee.oPathInfo          }
  public var args              : String? { return raw.pointee.oArgs              }
  
  public var contentType : String? {
    set { raw.pointee.oContentType = newValue }
    get { return raw.pointee.oContentType }
  }
  
  public var headersIn     : APRTable { return APRTable(raw.pointee.headers_in)      }
  public var headersOut    : APRTable { return APRTable(raw.pointee.headers_out)     }
  public var errHeadersOut : APRTable { return APRTable(raw.pointee.err_headers_out) }
  public var trailersIn    : APRTable { return APRTable(raw.pointee.trailers_in)     }
  public var trailersOut   : APRTable { return APRTable(raw.pointee.trailers_out)    }
  public var subprocessEnv : APRTable { return APRTable(raw.pointee.subprocess_env)  }
  public var notes         : APRTable { return APRTable(raw.pointee.notes)           }
  public var bodyTable     : APRTable { return APRTable(raw.pointee.body_table)      }
  
  public var status        : apr_status_t       { return raw.pointee.status       }
  public var requestTime   : apr_time_t         { return raw.pointee.request_time }
  public var finfo         : apr_finfo_t        { return raw.pointee.finfo        }
  
  public var pool          : OpaquePointer!     { return raw.pointee.pool         }

  /* TODO:
   struct ap_conf_vector_t *per_dir_config;
   struct ap_conf_vector_t *request_config;
   */
  
  public var description : String {
    return "<Req: \(method) \(uri)>"
  }
}

public extension ApacheRequest { // Output
  
  public func puts(_ s: String) {
    ap_rputs(s, raw)
  }
  
}

public extension ApacheRequest { // Misc wrappers for http_core
  
  public var allowOptions        : Int32      { return ap_allow_options  (raw)    }
  public var allowOverrides      : Int32      { return ap_allow_overrides(raw)    }
  public var serverPort          : apr_port_t { return ap_get_server_port(raw)    }
  public var requestBodyLimit    : apr_off_t  { return ap_get_limit_req_body(raw) }
  public var xmlRequestBodyLimit : apr_size_t { return ap_get_limit_xml_body(raw) }
  
  public var isRecursionLimitExceeded : Bool {
    return ap_is_recursion_limit_exceeded(raw) != 0
  }
  
  // docs say: don't use this ;-> (cause Userdir)
  public var documentRoot    : String { return String(cString: ap_document_root(raw)) }
 
  public var remoteLoginName : String? {
    guard let s = ap_get_remote_logname(raw) else { return nil }
    return String(cString: s)
  }
  
  public var serverName : String { return String(cString: ap_get_server_name(raw)) }
  
  public var serverNameForURL : String {
    return String(cString: ap_get_server_name_for_url(raw))
  }
  
  public func doesConfigDefineExist(_ name: String) -> Bool {
    return ap_exists_config_define(name) != 0
  }
}

public extension ApacheRequest { // Auth wrappers for http_core
  
  public var authType : String? {
    guard let s = ap_auth_type(raw) else { return nil }
    return String(cString: s)
  }

  public var authName : String? { // the realm
    guard let s = ap_auth_name(raw) else { return nil }
    return String(cString: s)
  }
  
  public var satisfies : Int32 { // SATISFY_ANY, SATISFY_ALL, SATISFY_NOSPEC
    return ap_satisfies(raw)
  }
}

public extension ApacheRequest { // Logging
  
  public func log(file:    String = #file,
                  line:    Int    = #line,
                  level:   Int32  = APLOG_WARNING,
                  status:  apr_status_t? = nil,
                  _ s: String)
  {
    let lStatus = status ?? self.status
    
    apz_log_rerror_(file, Int32(line), -1 /*TBD*/, level, lStatus, raw, s)
  }
}
