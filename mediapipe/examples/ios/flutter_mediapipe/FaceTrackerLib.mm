#import "FaceTrackerLib.h"
#import "mediapipe/objc/MPPCameraInputSource.h"
#import "mediapipe/objc/MPPGraph.h"
#import "mediapipe/objc/MPPLayerRenderer.h"
#import "mediapipe/objc/MPPTimestampConverter.h"
#include "mediapipe/framework/formats/landmark.pb.h"
#include "mediapipe/modules/face_geometry/protos/face_geometry_full_info.pb.h"

static const char *kVideoQueueLabel = "com.google.mediapipe.example.videoQueue";
static NSString *const kGraphName = @"iris_tracking_gpu";
static const char *kInputStream = "input_video";
static const char *kOutputStream = "output_video";
static const char *kLandmarksOutputStream = "face_geometry_full_info";

@interface FaceTrackerLib () <MPPGraphDelegate>
// The MediaPipe graph currently in use. Initialized in viewDidLoad, started in
// viewWillAppear: and sent video frames on videoQueue.
@property(nonatomic) MPPGraph *mediapipeGraph;
// Input side packet for focal length parameter.
@property(nonatomic) std::map <std::string, mediapipe::Packet> input_side_packets;
@property(nonatomic) mediapipe::Packet focal_length_side_packet;
- (Landmark *)extractLandmarkById:(const ::mediapipe::NormalizedLandmarkList *)landmarks atId:(int)id;
@end

@interface Landmark ()
- (instancetype)initWithX:(float)x y:(float)y z:(float)z;
@end

@implementation FaceTrackerLib {
}

#pragma mark - Cleanup methods

- (void)dealloc {
    self.mediapipeGraph.delegate = nil;
    [self.mediapipeGraph cancel];
    // Ignore errors since we're cleaning up.
    [self.mediapipeGraph closeAllInputStreamsWithError:nil];
    [self.mediapipeGraph waitUntilDoneWithError:nil];
}

#pragma mark - MediaPipe graph methods

+ (MPPGraph *)loadGraphFromResource:(NSString *)resource {
    // Load the graph config resource.
    NSError *configLoadError = nil;
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    if (!resource || resource.length == 0) {
        return nil;
    }
    NSURL *graphURL = [bundle URLForResource:resource withExtension:@"binarypb"];
    NSData *data = [NSData dataWithContentsOfURL:graphURL options:0 error:&configLoadError];
    if (!data) {
        NSLog(@"Failed to load MediaPipe graph config: %@", configLoadError);
        return nil;
    }

    // Parse the graph config resource into mediapipe::CalculatorGraphConfig proto object.
    mediapipe::CalculatorGraphConfig config;
    config.ParseFromArray(data.bytes, data.length);

    // Create MediaPipe graph with mediapipe::CalculatorGraphConfig proto object.
    MPPGraph *newGraph = [[MPPGraph alloc] initWithGraphConfig:config];
    return newGraph;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isGraphInitialized = false;
        self.didReadCameraIntrinsicMatrix = false;
        self.mediapipeGraph = [[self class] loadGraphFromResource:kGraphName];
        //в данном варианте графа нет выходного видео потока
        //[self.mediapipeGraph addFrameOutputStream:kOutputStream outputPacketType:MPPPacketTypePixelBuffer];
        [self.mediapipeGraph addFrameOutputStream:kLandmarksOutputStream outputPacketType:MPPPacketTypeRaw];
        _focal_length_side_packet = mediapipe::MakePacket < std::unique_ptr < float >> (absl::make_unique<float>(0.0));
        _input_side_packets = {{"focal_length_pixel", _focal_length_side_packet},};
        [self.mediapipeGraph addSidePackets:_input_side_packets];
        self.mediapipeGraph.delegate = self;
    }
    return self;
}

- (void)startGraph {
    // Start running self.mediapipeGraph.
    NSError *error;
    if (![self.mediapipeGraph startWithError:&error]) {
        NSLog(@"Failed to start graph: %@", error);
    } else if (![self.mediapipeGraph waitUntilIdleWithError:&error]) {
        NSLog(@"Failed to complete graph initial run: %@", error);
    }
    self.isGraphInitialized = true;
}

#pragma mark - MPPGraphDelegate methods

// Receives CVPixelBufferRef from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph *)graph
  didOutputPixelBuffer:(CVPixelBufferRef)pixelBuffer
            fromStream:(const std::string &)streamName {
    if (streamName == kOutputStream) {
        [_delegate track:self didOutputPixelBuffer:pixelBuffer];
    }
}

// Receives a raw packet from the MediaPipe graph. Invoked on a MediaPipe worker thread.
- (void)mediapipeGraph:(MPPGraph *)graph
       didOutputPacket:(const ::mediapipe::Packet &)packet
            fromStream:(const std::string &)streamName {
    if (streamName == kLandmarksOutputStream) {
        if (packet.IsEmpty()) {return;}
        const auto &face_geometry_full_info = packet.Get<::mediapipe::face_geometry::FaceGeometryFullInfo>();

        const auto &info = &face_geometry_full_info.info();
        const auto &landmarks = &face_geometry_full_info.landmarks();
        NSMutableArray < Landmark * > *result = [NSMutableArray array];

        [result addObject:[self extractLandmarkById:landmarks atId:1]];

        [result addObject:[self extractLandmarkById:landmarks atId:10]];
        [result addObject:[self extractLandmarkById:landmarks atId:152]];
        [result addObject:[self extractLandmarkById:landmarks atId:234]];
        [result addObject:[self extractLandmarkById:landmarks atId:454]];

        [result addObject:[self extractLandmarkById:landmarks atId:124]];
        [result addObject:[self extractLandmarkById:landmarks atId:46]];
        [result addObject:[self extractLandmarkById:landmarks atId:53]];
        [result addObject:[self extractLandmarkById:landmarks atId:52]];
        [result addObject:[self extractLandmarkById:landmarks atId:65]];
        [result addObject:[self extractLandmarkById:landmarks atId:55]];

        [result addObject:[self extractLandmarkById:landmarks atId:285]];
        [result addObject:[self extractLandmarkById:landmarks atId:295]];
        [result addObject:[self extractLandmarkById:landmarks atId:282]];
        [result addObject:[self extractLandmarkById:landmarks atId:283]];
        [result addObject:[self extractLandmarkById:landmarks atId:276]];
        [result addObject:[self extractLandmarkById:landmarks atId:353]];

        [result addObject:[self extractLandmarkById:landmarks atId:468]];
        [result addObject:[self extractLandmarkById:landmarks atId:473]];

        [result addObject:[self extractLandmarkById:landmarks atId:33]];
        [result addObject:[self extractLandmarkById:landmarks atId:159]];
        [result addObject:[self extractLandmarkById:landmarks atId:133]];
        [result addObject:[self extractLandmarkById:landmarks atId:145]];

        [result addObject:[self extractLandmarkById:landmarks atId:362]];
        [result addObject:[self extractLandmarkById:landmarks atId:386]];
        [result addObject:[self extractLandmarkById:landmarks atId:263]];
        [result addObject:[self extractLandmarkById:landmarks atId:374]];

        [result addObject:[self extractLandmarkById:landmarks atId:471]];
        [result addObject:[self extractLandmarkById:landmarks atId:470]];
        [result addObject:[self extractLandmarkById:landmarks atId:469]];
        [result addObject:[self extractLandmarkById:landmarks atId:472]];

        [result addObject:[self extractLandmarkById:landmarks atId:474]];
        [result addObject:[self extractLandmarkById:landmarks atId:475]];
        [result addObject:[self extractLandmarkById:landmarks atId:476]];
        [result addObject:[self extractLandmarkById:landmarks atId:477]];

        [result addObject:[self extractLandmarkById:landmarks atId:78]];
        [result addObject:[self extractLandmarkById:landmarks atId:308]];

        [result addObject:[self extractLandmarkById:landmarks atId:81]];
        [result addObject:[self extractLandmarkById:landmarks atId:13]];
        [result addObject:[self extractLandmarkById:landmarks atId:311]];

        [result addObject:[self extractLandmarkById:landmarks atId:178]];
        [result addObject:[self extractLandmarkById:landmarks atId:14]];
        [result addObject:[self extractLandmarkById:landmarks atId:402]];

        [result addObject:[self extractLandmarkById:landmarks atId:9]];

        std::vector<float> info_vector_array(info->begin(), info->end());
        NSMutableArray <NSNumber*> *info_ns_array = [NSMutableArray array];
        for (auto el : info_vector_array) {
            [info_ns_array addObject:[NSNumber numberWithFloat:el]];
        }

        [_delegate track:self didOutputLandmarks:result infoArray:info_ns_array];
    }
}

- (Landmark *)extractLandmarkById:(const ::mediapipe::NormalizedLandmarkList *)landmarks atId:(int)id {
    Landmark *landmark = [[Landmark alloc] initWithX:landmarks->landmark(id).x()
                                                   y:landmarks->landmark(id).y()
                                                   z:landmarks->landmark(id).z()];
    return landmark;
}

- (void)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    if (self.isGraphInitialized) {
        [self.mediapipeGraph sendPixelBuffer:pixelBuffer
                                  intoStream:kInputStream
                                  packetType:MPPPacketTypePixelBuffer];
    }
}

- (void)updateFocalDistance:(CMSampleBufferRef)buffer {
    if (self.isGraphInitialized) {
        if (!self.didReadCameraIntrinsicMatrix) {
            CFTypeRef cameraIntrinsicData = CMGetAttachment(buffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil);
            if (cameraIntrinsicData != nil) {
                CFDataRef cfdr = (CFDataRef)cameraIntrinsicData;
                matrix_float3x3* intrinsicMatrix = (matrix_float3x3*)(CFDataGetBytePtr(cfdr));
                if (intrinsicMatrix != nil) {
                    *(_input_side_packets["focal_length_pixel"].Get<std::unique_ptr<float>>()) = intrinsicMatrix->columns[0][0];
                }
            }
            self.didReadCameraIntrinsicMatrix = true;
        }
    }
}
@end

@implementation Landmark
- (instancetype)initWithX:(float)x y:(float)y z:(float)z {
    self = [super init];
    if (self) {
        _x = x;
        _y = y;
        _z = z;
    }
    return self;
}
@end
