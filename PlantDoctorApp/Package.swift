// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PlantDoctorApp",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "PlantDoctorApp",
            targets: ["PlantDoctorApp"])
    ],
    dependencies: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", from: "10.19.0")
    ],
    targets: [
        .target(
            name: "PlantDoctorApp",
            dependencies: [
                .product(name: "FirebaseAuth", package: "firebase-ios-sdk"),
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
            ]
        )
    ]
)
