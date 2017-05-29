import PackageDescription

let package = Package(
    name: "Apache",

    dependencies: [
      .Package(url: "https://github.com/modswift/CApache.git", 
               majorVersion: 1, minor: 0)
    ]
)
