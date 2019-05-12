// swift-tools-version:4.2
//
//  Package.swift
//  mod_swift
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2019 ZeeZide. All rights reserved.
//
import PackageDescription

let package = Package(
    name: "Apache",
    
    products: [
      .library(name: "Apache", targets: [ "Apache" ]),
    ],
    
    dependencies: [
      .package(url: "https://github.com/modswift/CApache.git", from: "2.0.1")
    ],
    
    targets: [
      .target(name: "Apache", dependencies: [ "CApache" ])
    ]
)
