#include <memory>
#include <string>
#include <utility>
#include <vector>
#include "Eigen/Core"
#include <Eigen/Geometry>

#include "absl/memory/memory.h"
#include "mediapipe/framework/calculator_framework.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/framework/port/ret_check.h"
#include "mediapipe/framework/port/status.h"
#include "mediapipe/framework/port/status_macros.h"
#include "mediapipe/framework/port/statusor.h"
#include "mediapipe/modules/face_geometry/geometry_pipeline_calculator.pb.h"
#include "mediapipe/modules/face_geometry/libs/geometry_pipeline.h"
#include "mediapipe/modules/face_geometry/libs/validation_utils.h"
#include "mediapipe/modules/face_geometry/protos/environment.pb.h"
#include "mediapipe/modules/face_geometry/protos/face_geometry.pb.h"
#include "mediapipe/modules/face_geometry/protos/face_geometry_full_info.pb.h"
#include "mediapipe/modules/face_geometry/protos/geometry_pipeline_metadata.pb.h"
#include "mediapipe/util/resource_util.h"

namespace mediapipe {
namespace {

static constexpr char kImageSizeTag[] = "IMAGE_SIZE";
static constexpr char kMultiFaceGeometryTag[] = "MULTI_FACE_GEOMETRY";
static constexpr char kMultiSmoothedFaceLandmarksTag[] = "SMOOTHED_FACE_LANDMARKS_WITH_IRIS";
static constexpr char kFaceGeometryFullInfoTag[] = "FACE_GEOMETRY_FULL_INFO";

class FaceGeometryInfoCalculator : public CalculatorBase {
 public:
  static absl::Status GetContract(CalculatorContract* cc) {
    cc->Inputs().Tag(kImageSizeTag).Set<std::pair<int, int>>();
    cc->Inputs().Tag(kMultiSmoothedFaceLandmarksTag).Set<NormalizedLandmarkList>();
    cc->Inputs().Tag(kMultiFaceGeometryTag).Set<std::vector<face_geometry::FaceGeometry>>();
    cc->Outputs().Tag(kFaceGeometryFullInfoTag).Set<face_geometry::FaceGeometryFullInfo>();
    return absl::OkStatus();
  }

  absl::Status Open(CalculatorContext* cc) override {
    cc->SetOffset(mediapipe::TimestampDiff(0));
    return absl::OkStatus();
  }

  absl::Status Process(CalculatorContext* cc) override {
    if (cc->Inputs().Tag(kImageSizeTag).IsEmpty() ||
        cc->Inputs().Tag(kMultiSmoothedFaceLandmarksTag).IsEmpty() ||
        cc->Inputs().Tag(kMultiFaceGeometryTag).IsEmpty()) {
      return absl::OkStatus();
    }

    const auto& image_size = cc->Inputs().Tag(kImageSizeTag).Get<std::pair<int, int>>();
    const auto& smoothed_face_landmarks = cc->Inputs().Tag(kMultiSmoothedFaceLandmarksTag).Get<NormalizedLandmarkList>();
    const auto& multi_face_geometry = cc->Inputs().Tag(kMultiFaceGeometryTag).Get<std::vector<face_geometry::FaceGeometry>>();
    auto& face_geometry = multi_face_geometry.at(0);
    auto packed_data = face_geometry.pose_transform_matrix().packed_data();

    Eigen::Matrix3f rot;

    rot(0,0) = packed_data[0];
    rot(1,0) = packed_data[1];
    rot(2,0) = packed_data[2];

    rot(0,1) = packed_data[4];
    rot(1,1) = packed_data[5];
    rot(2,1) = packed_data[6];

    rot(0,2) = packed_data[8];
    rot(1,2) = packed_data[9];
    rot(2,2) = packed_data[10];

    Eigen::Vector3f ypr = rot.eulerAngles(2, 1, 0);

    auto result = absl::make_unique<face_geometry::FaceGeometryFullInfo>();

    result->add_info(static_cast<float>(image_size.first));
    result->add_info(static_cast<float>(image_size.second));
    result->add_info(ypr(0));
    result->add_info(ypr(1));
    result->add_info(ypr(2));
    NormalizedLandmarkList* mutable_landmarks = result->mutable_landmarks();
    mutable_landmarks->CopyFrom(smoothed_face_landmarks);

    cc->Outputs()
    .Tag(kFaceGeometryFullInfoTag)
    .AddPacket(mediapipe::Adopt<face_geometry::FaceGeometryFullInfo>(result.release()).At(cc->InputTimestamp()));

    return absl::OkStatus();
  }

  absl::Status Close(CalculatorContext* cc) override {
    return absl::OkStatus();
  }
};

}  // namespace

REGISTER_CALCULATOR(FaceGeometryInfoCalculator);

}  // namespace mediapipe
