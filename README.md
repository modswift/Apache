<h2>Swift Apache
  <img src="http://zeezide.com/img/mod_swift.svg"
       align="right" width="128" height="128" />
</h2>

![Apache 2](https://img.shields.io/badge/apache-2-yellow.svg)
![Swift3](https://img.shields.io/badge/swift-3-blue.svg)
![Swift4](https://img.shields.io/badge/swift-4-blue.svg)
![Swift5](https://img.shields.io/badge/swift-5-blue.svg)
![macOS](https://img.shields.io/badge/os-macOS-green.svg?style=flat)
![tuxOS](https://img.shields.io/badge/os-tuxOS-green.svg?style=flat)

A Swift API for Apache. This wraps the CApache system package and
provides Swift convenience on top of that.
This package is part of the [mod_swift](http://mod-swift.org/) effort.

Apache provides a very low level API towards Apache,
for something more convenient, 
checkout [ApacheExpress](http://apacheexpress.io/).


### Using the Apache package

*NOTE*: This *requires* a mod_swift installation. W/o it, it will
        fail to built CApache!

If you setup a new module from scratch, use:

    swift apache init

Otherwise setup your Package.swift to include Apache:

```Swift
import PackageDescription

let package = Package(
  name: "MyTool",
	
  dependencies: [
    .Package(url: "git@github.com:modswift/Apache.git", from: "0.5.0"),
  ]
)
```


# Building an Apache module

Simply invoke

    swift apache build

This wraps Swift Package Manager to build your package
and then produce a proper module which can be loaded
into Apache.

To run a test Apache instance, use:

    swift apache serve

Access the Apache using: http://localhost:8042/.


### Example


Check `mods_baredemo` for a low level Apache module which uses
the APIs of this package.

A simple Apache handler:

```swift
func HelloHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  let req = ApacheRequest(raw: p!)
  guard req.handler == "helloswift" else { return DECLINED }
  req.puts("Hello World!")
  return OK
}
```

An Apache handler using the database:

```swift
func DatabaseHandler(p: UnsafeMutablePointer<request_rec>?) -> Int32 {
  let req = ApacheRequest(raw: p!)
  guard req.handler == "dbswift" else { return DECLINED }
  
  guard let dbd = req.dbdAcquire() else {
    req.puts("Could not access database!")
    return 500
  }
  
  dbd.select("SELECT name, count FROM pets") { (name : String, count : Int?) in
    req.puts("\(name): \(count)\n")
  }

  return OK
}
```

Apache Configuration for both:

```
<Location /helloworld>
  SetHandler helloswift
</Location>

<Location /database>
  SetHandler dbswift
  DBDriver   sqlite3
  DBDParams  "absolute-path-to-testdb.sqlite3"
</Location>
```


### Who

**mod_swift** is brought to you by
[ZeeZide](http://zeezide.de).
We like feedback, GitHub stars, cool contract work,
presumably any form of praise you can think of.

There is a `#mod_swift` channel on the [Noze.io Slack](http://slack.noze.io).
