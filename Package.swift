// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription


func makeBinaryTarget(_ name: String) -> Target {
#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)
    .binaryTarget(
        name: name,
        path: "Binaries/\(name).xcframework"
    )
#else
    .binaryTarget(
        name: name,
        path: "Binaries/\(name).artifactbundle"
    )
#endif
}


let package = Package(
    name: "Brotli",
    platforms: [
        .macOS(.v10_13),
        .iOS(.v12),
        .tvOS(.v12),
        .watchOS(.v8),
        .visionOS(.v1),
        .custom("Android", versionString: "5.0")
    ],
    products: [
        .library(
            name: "libbrotlicommon",
            targets: ["libbrotlicommon"]
        ),
        .library(
            name: "libbrotlienc",
            targets: ["libbrotlienc"]
        ),
        .library(
            name: "libbrotlidec",
            targets: ["libbrotlidec"]
        ),
        .library(
            name: "BrotliCommon",
            targets: ["BrotliCommon"]
        ),
        .library(
            name: "BrotliEncodeC",
            targets: ["BrotliEncodeC"]
        ),
        .library(
            name: "BrotliDecodeC",
            targets: ["BrotliDecodeC"]
        ),
        .library(
            name: "BrotliC",
            targets: ["BrotliC"]
        ),
        .library(
            name: "Brotli",
            targets: ["Brotli"]
        ),
    ],
    targets: [
        makeBinaryTarget("libbrotlicommon"),
        makeBinaryTarget("libbrotlienc"),
        makeBinaryTarget("libbrotlidec"),
        .target(
            name: "BrotliCommon",
            dependencies: [
                .target(name: "libbrotlicommon"),
            ],
            cxxSettings: [
                .enableWarning("all"),
            ]
        ),
        .target(
            name: "BrotliEncodeC",
            dependencies: [
                .target(name: "BrotliCommon"),
                .target(name: "libbrotlienc"),
            ],
            cxxSettings: [
                .enableWarning("all"),
            ]
        ),
        .target(
            name: "BrotliDecodeC",
            dependencies: [
                .target(name: "BrotliCommon"),
                .target(name: "libbrotlidec"),
            ],
            cxxSettings: [
                .enableWarning("all"),
            ]
        ),
        .target(
            name: "BrotliC",
            dependencies: [
                .target(name: "BrotliCommon"),
                .target(name: "BrotliEncodeC"),
                .target(name: "BrotliDecodeC"),
            ],
            cxxSettings: [
                .enableWarning("all"),
            ]
        ),
        .target(
            name: "Brotli",
            dependencies: [
                .target(name: "BrotliC"),
            ],
            swiftSettings: [
                .interoperabilityMode(.Cxx)
            ]
        ),
    ],
    // The libpng library was compiled using c17, so set it also here
    cLanguageStandard: .c17,
    // Also use c++20, we don't live in the stone age, but still not ready to accept c++23
    cxxLanguageStandard: .cxx20
)
