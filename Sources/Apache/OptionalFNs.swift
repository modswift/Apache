//
// Copyright (C) 2017 ZeeZide GmbH, All Rights Reserved
// Created by Helge Hess on 23/01/2017.
//

import CAPR

// DBD test
// Apache optional functions have the prefix `apr_OFN_`, e.g.
// `apr_OFN_ap_dbd_acquire_t`.
// Note: func types with UnsafeMutablePointer<request_rec>? coredump swiftc,
//       e.g.: apr_OFN_ap_dbd_acquire_t

// our funcs need to declare the type, there is no automagic macro way ...
public func APR_RETRIEVE_OPTIONAL_FN<T>(_ name: String) -> T? {
  guard let fn = apr_dynamic_fn_retrieve(name) else { return nil }
  return unsafeBitCast(fn, to: T.self) // TBD: is there a better way?
}
