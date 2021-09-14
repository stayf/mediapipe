#import <CoreVideo/CoreVideo.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

@class Landmark;
@class FaceTrackerLib;

@protocol FaceTrackerDelegate <NSObject>
- (void)track: (FaceTrackerLib *)tracker didOutputLandmarks: (NSArray<Landmark *> *)landmarks infoArray:(NSArray <NSNumber*>*)info;
- (void)track: (FaceTrackerLib *)tracker didOutputPixelBuffer: (CVPixelBufferRef)pixelBuffer;
@end

@interface FaceTrackerLib : NSObject
- (instancetype)init;
- (void)startGraph;
- (void)updateFocalDistance:(CMSampleBufferRef)buffer;
- (void)sendPixelBuffer:(CVPixelBufferRef)pixelBuffer;
@property(weak, nonatomic) id<FaceTrackerDelegate> delegate;
@property(nonatomic) bool isGraphInitialized;
@property(nonatomic) bool didReadCameraIntrinsicMatrix;
@end

@interface Landmark: NSObject
@property(nonatomic, readonly) float x;
@property(nonatomic, readonly) float y;
@property(nonatomic, readonly) float z;
@end