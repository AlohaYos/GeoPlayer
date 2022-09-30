
#import <UIKit/UIKit.h>
#import "GpxItem.h"

@interface GpxParser : NSObject {

	NSMutableString*	currentElement;
	GpxItem*			aGpxItem;
	NSMutableArray*		gpxArray;
	BOOL				segmentStart;
}

- (id)initWithArray:(NSMutableArray*)array;

@end
