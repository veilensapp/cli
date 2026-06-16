// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Veilens",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        // Vendored zstd decompressor (decoder-only amalgamation), statically
        // linked so we never need a system `zstd`/`libzstd` — see Sources/CZstd.
        .target(
            name: "CZstd",
            path: "Sources/CZstd",
            sources: ["zstddeclib.c"],
            publicHeadersPath: "include"
        ),
        // Shared engine-lifecycle logic: install/build/start the millrace inference
        // server + headgate + the veilens vault. The same Bootstrapper the millrace
        // app uses (it installs into the shared ~/Library/Application Support/Millrace
        // tree + the me.millrace.server launchd job), so the `veilens` and `millrace`
        // CLIs interoperate on one server.
        .target(
            name: "VeilensCore",
            dependencies: ["CZstd"],
            path: "Sources/VeilensCore"
        ),
        // The `veilens` CLI. There is no companion .app, so the binary is named
        // `veilens` directly; the Homebrew formula installs it as `veilens`.
        .executableTarget(
            name: "veilens",
            dependencies: [
                "VeilensCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ],
            path: "Sources/veilens"
        ),
    ]
)
