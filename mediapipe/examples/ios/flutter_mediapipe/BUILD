load("@build_bazel_rules_apple//apple:ios.bzl", "ios_framework")

ios_framework(
    name = "face",
    hdrs = [
        "FaceTrackerLib.h",
    ],
    infoplists = [
        "//mediapipe/examples/ios/common:Info.plist",
    ],
    bundle_id = "com.kastapp.stickers.face",
    families = ["iphone", "ipad"],
    minimum_os_version = "12.1",
    deps = [
        ":FaceTrackerLibrary",
        "@ios_opencv//:OpencvFramework",
    ],
)

objc_library(
    name = "FaceTrackerLibrary",
    srcs = [
        "FaceTrackerLib.mm",
    ],
    hdrs = [
        "FaceTrackerLib.h",
    ],
    copts = ["-std=c++17"],
    data = [
        "//mediapipe/graphs/iris_tracking:iris_tracking_gpu.binarypb",
        "//mediapipe/modules/face_detection:face_detection_short_range.tflite",
        "//mediapipe/modules/face_landmark:face_landmark.tflite",
        "//mediapipe/modules/iris_landmark:iris_landmark.tflite",
    ],
    deps = [
        "//mediapipe/examples/ios/common:CommonMediaPipeAppLibrary",
    ] + select({
        "//mediapipe:ios_i386": [],
        "//mediapipe:ios_x86_64": [],
        "//conditions:default": [
            "//mediapipe/graphs/iris_tracking:iris_tracking_gpu_deps",
            "//mediapipe/framework/formats:landmark_cc_proto",
        ],
    }),
)