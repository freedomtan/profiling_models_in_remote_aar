//
//  bridge-header.h
//  profileMlodelcInRemoteAAR
//
//  Created by Koan-Sin Tan on 8/24/24.
//

#ifndef bridge_header_h
#define bridge_header_h

#import <CoreML/CoreML.h>

// export non-documented setProfilingOptions:
@interface MLModelConfiguration (helper)
- (id) setProfilingOptions:(long long) p;
@end

// export non-documented program:
@interface MLModel (helper)
- (id) program;
@end

// export MLE5Engine and programLibrary
@interface MLE5Engine
- (id) programLibrary;
@end

// hack: becasue we cannot access MLE5ProgramLibrary
@interface NSObject()
- (NSDictionary *) segmentationAnalyticsAndReturnError:(id *) error;
@end


#endif /* bridge_header_h */
