//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import CAPR
import CApache

// This could be used, but remember that you usually get a pointer to the
// struct, not the struct itself. Hence you would need to do this:
//
//   let method = req?.pointee.oMethod
//
public extension request_rec {

  var oMethod      : String { return String(cString: method)        }
  var oURI         : String { return String(cString: uri)           }
  var oUnparsedURI : String { return String(cString: unparsed_uri)  }
  var oHandler     : String { return String(cString: handler)       }
  var oTheRequest  : String { return String(cString: the_request)   }
  var oProtocol    : String { return String(cString: self.protocol) }
  var oHostname    : String { return String(cString: hostname)      }
  var oPathInfo    : String { return String(cString: path_info)     }

  var oFilename : String? {
    guard let s = filename else { return nil };
    return String(cString: s)
  }
  var oCanonicalFilename : String? {
    guard let s = canonical_filename else { return nil };
    return String(cString: s)
  }
  var oContentEncoding : String? {
    guard let s = content_encoding else { return nil }
    return String(cString: s)
  }
  var oUser : String? {
    guard let s = user else { return nil }
    return String(cString: s)
  }
  var oApAuthType : String? {
    guard let s = ap_auth_type else { return nil }
    return String(cString: s)
  }
  var oArgs : String? {
    guard let s = args else { return nil }
    return String(cString: s)
  }
  
  var oContentType : String? {
    set {
      newValue?.withCString { cstr in
        ap_set_content_type(&self, apr_pstrdup(self.pool, cstr))
      }
    }
    get {
      guard let s = content_type else { return nil }
      return String(cString: s)
    }
  }
}

/* This breaks swiftc, again.
public extension request_rec : CustomStringConvertible {
  public var description : String {
    return "<Req: \(oMethod) \(uri)>"
  }
}
*/