
#import "GpxParser.h"

@implementation GpxParser

#pragma mark Object lifecycle

- (id)initWithArray:(NSMutableArray*)array {
	self = [super init];
	gpxArray = array;
	aGpxItem = nil;
	segmentStart = NO;

	return self;
}


#pragma mark - Parse delegate

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qualifiedName 
	attributes:(NSDictionary *)attributeDict {

	// "<trkseg>"タグが出現
	if([elementName isEqualToString:@"trkseg"]) {
		segmentStart = YES;
	}
	
	// "<trkpt>"タグが出現するまで読み飛ばす
	if([elementName isEqualToString:@"trkpt"]) {
		// GpxItemインスタンスの初期化
		aGpxItem = [[GpxItem alloc] init];
		aGpxItem.segmentStart = segmentStart;
		segmentStart = NO;
		[gpxArray addObject:aGpxItem];
	}

	// GpxItemクラスに対応するプロパティがある場合のみ文字列の格納領域を用意する
	if(aGpxItem) {
		if ([aGpxItem respondsToSelector:NSSelectorFromString(elementName)]) {
			currentElement = [[NSMutableString alloc] initWithString:@""];
		}
	}

	// lat/lon 属性があるかどうかチェックする
	if ([attributeDict objectForKey:@"lat"]) {
		NSString* latStr = [attributeDict objectForKey:@"lat"];
		aGpxItem.latitude = [latStr doubleValue];
	}
	if ([attributeDict objectForKey:@"lon"]) {
		NSString* lonStr = [attributeDict objectForKey:@"lon"];
		aGpxItem.longitude = [lonStr doubleValue];
	}

	//NSLog(@"タグエレメント: %@", elementName);
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string { 
	
	if(currentElement) {
		[currentElement appendString:string];
	}
	
	//NSLog(@"値: %@", currentElement);
	
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName 
  namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {

	// 対応するプロパティがある場合のみ処理する
	if(currentElement) {
		if ([aGpxItem respondsToSelector:NSSelectorFromString(elementName)]) {
			
#if 0
			if([elementName isEqualToString:@"trkpt"]) {
				aGpxItem.latitude = [currentElement doubleValue];
				currentElement = nil;
				return;
			}

			if([elementName isEqualToString:@"lat"]) {
				aGpxItem.latitude = [currentElement doubleValue];
				currentElement = nil;
				return;
			}

			if([elementName isEqualToString:@"lon"]) {
				aGpxItem.longitude = [currentElement doubleValue];
				currentElement = nil;
				return;
			}
#endif
			if([elementName isEqualToString:@"magvar"]) {
				aGpxItem.heading = [currentElement doubleValue];
				currentElement = nil;
				return;
			}
			
			if([elementName isEqualToString:@"ele"]) {
				aGpxItem.altitude = [currentElement doubleValue];
				currentElement = nil;
				return;
			}
			
			if([elementName isEqualToString:@"extensions"]) {
				aGpxItem.extensions = currentElement;
				
				if([currentElement rangeOfString:@"stationary"].location != NSNotFound)	aGpxItem.stationary = YES;
				if([currentElement rangeOfString:@"walking"].location != NSNotFound)	aGpxItem.walking = YES;
				if([currentElement rangeOfString:@"running"].location != NSNotFound)	aGpxItem.running = YES;
				if([currentElement rangeOfString:@"automotive"].location != NSNotFound)	aGpxItem.automotive = YES;
				if([currentElement rangeOfString:@"unknown"].location != NSNotFound)	aGpxItem.unknown = YES;
				if([currentElement rangeOfString:@"low"].location != NSNotFound)	aGpxItem.confidence = CMMotionActivityConfidenceLow;
				if([currentElement rangeOfString:@"medium"].location != NSNotFound)	aGpxItem.confidence = CMMotionActivityConfidenceMedium;
				if([currentElement rangeOfString:@"high"].location != NSNotFound)	aGpxItem.confidence = CMMotionActivityConfidenceHigh;
				currentElement = nil;
				return;
			}
			
			if([elementName isEqualToString:@"time"]) {
				NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
				[inputDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
				//[inputDateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
				aGpxItem.timestamp = [[NSDate alloc] initWithTimeInterval:0 sinceDate:[inputDateFormatter dateFromString:currentElement]];
				currentElement = nil;
				return;
			}
		}
		currentElement = nil;
	}
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
//	NSLog([parseError description]);
}

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validError {
//	NSLog([validError description]);
}

@end
