
#import "Gpx.h"
//#import "GpxParser.h"
#import "FileReader.h"

@implementation Gpx {
    GPXRoot *_gpxRoot;
	KMLRoot *_kmlRoot;
}

- (id)init {
	_items = [[NSMutableArray alloc] initWithCapacity:1];

	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
	_name = [dateFormatter stringFromDate:[NSDate new]];
	
	return self;
}

// GPXRootからGpxItem配列への展開
- (void)extractGpx:(GPXRoot*)gpxRoot {
	NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
	[inputDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];

	_version = gpxRoot.version;

	[_items removeAllObjects];
	
	for(int tr=0; tr<[gpxRoot.tracks count]; tr++) {
		GPXTrack* track = [gpxRoot.tracks objectAtIndex:tr];
		if(tr==0) {
			_name = track.name;
		}
		
		for(int seg=0; seg<[track.tracksegments count]; seg++) {
			GPXTrackSegment* trackSeg = [track.tracksegments objectAtIndex:seg];
			for(int i=0; i<[trackSeg.trackpoints count]; i++) {
				GPXTrackPoint* trackPoint = [trackSeg.trackpoints objectAtIndex:i];
				
				GpxItem* aGpxItem = [[GpxItem alloc] init];
				if(i==0) {
					aGpxItem.segmentStart = YES;
				}
				else {
					aGpxItem.segmentStart = NO;
				}
				aGpxItem.latitude = [trackPoint.latitudeValue doubleValue];
				aGpxItem.longitude = [trackPoint.longitudeValue doubleValue];
				aGpxItem.altitude = [trackPoint.elevationValue doubleValue];
				aGpxItem.heading = [trackPoint.magneticVariationValue doubleValue];
				aGpxItem.timestamp = [[NSDate alloc] initWithTimeInterval:0 sinceDate:[inputDateFormatter dateFromString:trackPoint.timeValue]];
				
				if([trackPoint.extensions.text length]>0) {
					aGpxItem.extensions = trackPoint.extensions.text;
					if([aGpxItem.extensions rangeOfString:@"stationary"].location != NSNotFound)	aGpxItem.stationary = YES;
					if([aGpxItem.extensions rangeOfString:@"walking"].location != NSNotFound)		aGpxItem.walking = YES;
					if([aGpxItem.extensions rangeOfString:@"running"].location != NSNotFound)		aGpxItem.running = YES;
					if([aGpxItem.extensions rangeOfString:@"automotive"].location != NSNotFound)	aGpxItem.automotive = YES;
					if([aGpxItem.extensions rangeOfString:@"unknown"].location != NSNotFound)		aGpxItem.unknown = YES;
					if([aGpxItem.extensions rangeOfString:@"low"].location != NSNotFound)			aGpxItem.confidence = CMMotionActivityConfidenceLow;
					if([aGpxItem.extensions rangeOfString:@"medium"].location != NSNotFound)		aGpxItem.confidence = CMMotionActivityConfidenceMedium;
					if([aGpxItem.extensions rangeOfString:@"high"].location != NSNotFound)			aGpxItem.confidence = CMMotionActivityConfidenceHigh;
				}
				[_items addObject:aGpxItem];
			}
		}
	}
}

// GMLRootからGpxItem配列への展開
- (void)extractKml:(KMLRoot*)kmlRoot {
	NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
	[inputDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
	
	KMLDocument* feature0 = kmlRoot.feature;
	for(int fe=0; fe<[feature0.features count]; fe++) {
		KMLPlacemark* placemark = [feature0.features objectAtIndex:fe];
		// placemark.name
		KMLMultiGeometry* geometry = placemark.geometry;
		for(int gm=0; gm<[geometry.geometries count]; gm++) {
			KMLLineString* lineString = [geometry.geometries objectAtIndex:gm];
			for(int i=0; i<[lineString.coordinates count]; i++) {
				GpxItem* aGpxItem = [[GpxItem alloc] init];
				if(i==0) {
					aGpxItem.segmentStart = YES;
				}
				else {
					aGpxItem.segmentStart = NO;
				}

				KMLCoordinate* coordinate = [lineString.coordinates objectAtIndex:i];
				aGpxItem.latitude = coordinate.latitude;
				aGpxItem.longitude = coordinate.longitude;
				aGpxItem.altitude = coordinate.altitude;
				aGpxItem.heading = 0.0f;
			//	aGpxItem.timestamp = [[NSDate alloc] initWithTimeInterval:0 sinceDate:[inputDateFormatter dateFromString:trackPoint.timeValue]];

			}
		}
	}
}

- (BOOL)loadGpxData:(NSString*)fileName {
	
	if(fileName.length == 0)
		return NO;
	
	[self loadGpxMeta:fileName];
	
	// Documents/<fileName>.gpx
	NSString* folderPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* path=[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gpx", fileName]];
	
	_filePath = path;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[_items removeAllObjects];

//		_kmlRoot = [KMLParser parseKMLAtPath:path];
//		[self extractKml:_kmlRoot];

        _gpxRoot = [GPXParser parseGPXAtPath:path];
		[self extractGpx:_gpxRoot];
		return YES;
	}
	else {
		//NSLog(@"no such Gpx file %@", fileName);
		return NO;
	}
	_currentIndex = 0;
}

- (BOOL)saveGpxData:(NSString*)fileName {

	if(fileName.length==0) {
		fileName = _name;
	}
	
	NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
	[dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];

	// headerText
	// <trkpt lat="36.524365000" lon="136.616612000"><magvar>21.3</magvar><ele>28.5</ele><time>2013-12-23T15:16:15Z</time><extensions></extensions></trkpt>
	//   ...
	// footerText

	NSDate* currentTimeStamp;
	if(_timestamp!=nil) {
		currentTimeStamp = _timestamp;
	}
	else {
		currentTimeStamp = [NSDate new];
	}
	
	NSMutableString*	gpxText = [[NSMutableString alloc] initWithCapacity:1];
//	NSString*	repStr = [[self headerText] stringByReplacingOccurrencesOfString:@"*****dataname*****" withString:fileName];
	NSString*	repStr = [[self headerText] stringByReplacingOccurrencesOfString:@"*****dataname*****" withString:_name];
	repStr = [repStr stringByReplacingOccurrencesOfString:@"*****timestamp*****" withString:[dateFormatter stringFromDate:currentTimeStamp]];
	[gpxText appendString:repStr];

	for(int i=0; i<[_items count]; i++) {
		GpxItem* aGpxItem = [_items objectAtIndex:i];

		if(aGpxItem.segmentStart) {
			if(i>0) {
				[gpxText appendString:@"</trkseg>\n"];
			}
			[gpxText appendString:@"<trkseg>\n"];
		}
		
		NSString* timestamp = [dateFormatter stringFromDate:aGpxItem.timestamp];
		
		NSMutableString* extStr = [[NSMutableString alloc] initWithCapacity:1];
		[extStr appendString:@"<![CDATA[motionActivity=\""];
		if(aGpxItem.stationary)	[extStr appendString:@"stationary "];
		if(aGpxItem.walking)	[extStr appendString:@"walking "];
		if(aGpxItem.running)	[extStr appendString:@"running "];
		if(aGpxItem.automotive)	[extStr appendString:@"automotive "];
		if(aGpxItem.unknown)	[extStr appendString:@"unknown "];
		[extStr setString:[extStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]]];
		
		[extStr appendString:@"\" confidence=\""];
		switch (aGpxItem.confidence) {
			case CMMotionActivityConfidenceLow:
				[extStr appendString:@"low"];
				break;
			case CMMotionActivityConfidenceMedium:
				[extStr appendString:@"medium"];
				break;
			case CMMotionActivityConfidenceHigh:
				[extStr appendString:@"high"];
				break;
		}
		[extStr appendString:@"\"]]>"];
		
		NSString* pt = [NSString stringWithFormat:@"<trkpt lat=\"%.9f\" lon=\"%.9f\"><magvar>%.1f</magvar><ele>%.1f</ele><time>%@</time><extensions>%@</extensions></trkpt>\n", aGpxItem.latitude, aGpxItem.longitude, aGpxItem.heading, aGpxItem.altitude, timestamp, extStr];
		[gpxText appendString:pt];
	}

	if([_items count]>0) {
		[gpxText appendString:@"</trkseg>\n"];
	}
	[gpxText appendString:[self footerText]];

	// Documents/<fileName>.gpx
	NSString* folderPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* path=[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gpx", fileName]];
	
	_filePath = path;

	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
	}
	[gpxText writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];

	return YES;
}

- (void)renameAutoSaveFileToTimestampName {
	
	if([self loadGpxData:AUTO_SAVE_NAME] == YES) {
		NSString* folderPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
		NSString* path=[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gpx", AUTO_SAVE_NAME]];
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];

		[self saveGpxData:_name];
	}
}

- (BOOL)deleteGpxData:(NSString*)fileName {
	
	if(fileName.length==0) {
		fileName = _fileName;
	}
	
	_filePath = @"";

	// Documents/<fileName>.gpx
	NSString* folderPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* path=[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gpx", fileName]];
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
		[[NSFileManager defaultManager] removeItemAtPath:path error:nil];
		return YES;
	}
	
	return NO;
}

- (NSString*)headerText {

	NSString* retStr = @"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<gpx\n	version=\"1.1\"\n	creator=\"GeoFake\"\nxmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"\n	xmlns=\"http://www.topografix.com/GPX/1/1\"\nxsi:schemaLocation=\"http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd\"\nxmlns:gpxtpx=\"http://www.garmin.com/xmlschemas/TrackPointExtension/v1\">\n<trk>\n	<name><![CDATA[*****dataname*****]]></name>\n	<time>*****timestamp*****</time>\n";

	return retStr;
}

- (NSString*)footerText {
	
	NSString* retStr = @"</trk>\n</gpx>\n";
	return retStr;
}


- (BOOL)loadGpxMeta:(NSString*)fileName {
	
	if(fileName.length == 0)
		return NO;
	
	_fileName = fileName;
	
	// Documents/<fileName>.gpx
	NSString* folderPath=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];
	NSString* path=[folderPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.gpx", fileName]];
	
	_filePath = path;

	if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {

#if 1
		int lineCount = 0;

		_name = nil;
		_timestamp = nil;
		_version = nil;

		FileReader* fileReader = [[FileReader alloc] initWithFilePath:path];
		if (!fileReader) {
			return NO;
		}

		NSString* line = nil;
		while ((line = [fileReader readLine])) {
			lineCount++;
			//NSLog(@"%3.d: %@", lineCount, line);
			NSString* tmpStr;
			tmpStr = [self getElementValueOf:line withTag:@"name"];
			if([tmpStr length]>0) {
				_name = [tmpStr stringByReplacingOccurrencesOfString:@"<![CDATA[" withString:@""];
				_name = [_name stringByReplacingOccurrencesOfString:@"]]>" withString:@""];
			}

			tmpStr = [self getElementValueOf:line withTag:@"time"];
			if([tmpStr length]>0) {
				NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
				[inputDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
				_timestamp = [[NSDate alloc] initWithTimeInterval:0 sinceDate:[inputDateFormatter dateFromString:tmpStr]];
			}

			if([[line lowercaseString] rangeOfString:@"xml"].location==NSNotFound) {
				if([[line lowercaseString] rangeOfString:@"version"].location!=NSNotFound) {
					_version = [self getQuoteValueOf:line withTag:@"version"];
				}
			}
			
			if (lineCount >= 100) {	// ファイル先頭からチェックする行数の最大
				break;
			}
			
			if((_name)&&(_timestamp)&&(_version))
				break;
		}

#else
		NSString *xmlText = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
		if (xmlText) {
			_name = [self getElementValueOf:xmlText withTag:@"name"];
			_name = [_name stringByReplacingOccurrencesOfString:@"<![CDATA[" withString:@""];
			_name = [_name stringByReplacingOccurrencesOfString:@"]]>" withString:@""];

			NSString* timestampStr = [self getElementValueOf:xmlText withTag:@"time"];
			if(timestampStr.length > 0) {
				NSDateFormatter *inputDateFormatter = [[NSDateFormatter alloc] init];
				[inputDateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
				_timestamp = [[NSDate alloc] initWithTimeInterval:0 sinceDate:[inputDateFormatter dateFromString:timestampStr]];
			}
			else {
				_timestamp = nil;
			}
			
			_version = [self getGpxVersion:[xmlText lowercaseString]];
		}
#endif
	}
	else {
		//NSLog(@"no such Gpx file %@", fileName);
		return NO;
	}
	
	_currentIndex = 0;
	return YES;
}

// XMLテキストデータ内の指定したタグの値を取得する
-(NSString*)getElementValueOf:(NSString*)baseString withTag:(NSString*)tagString {
	
	NSArray *compo =  [baseString componentsSeparatedByString:[NSString stringWithFormat:@"<%@>",tagString]];
	if([compo count] < 2) return @"";
	
	NSArray *compo2 = [[compo objectAtIndex:1] componentsSeparatedByString:[NSString stringWithFormat:@"</%@>",tagString]];
	if([compo2 count] < 2) return @"";
	
	NSString *elementValue = [[compo2 objectAtIndex:0] substringFromIndex:0];
	
	return elementValue;
}

-(NSString*)getQuoteValueOf:(NSString*)baseString withTag:(NSString*)tagString {
	
	NSArray *compo =  [baseString componentsSeparatedByString:[NSString stringWithFormat:@"%@",tagString]];
	if([compo count] < 2) return @"";
	
	NSArray *compo2 = [[compo objectAtIndex:1] componentsSeparatedByString:[NSString stringWithFormat:@"\""]];
	if([compo2 count] < 2) return @"";
	
	NSString *elementValue = [[compo2 objectAtIndex:1] substringFromIndex:0];
	
	//	NSLog(@"NewtonBooksタグエレメント: %@", tagString);
	//	NSLog(@"NewtonBooks値: %@", elementValue);
	
	return elementValue;
}

- (NSString*)getGpxVersion:(NSString*)baseString {

	NSArray *compo =  [baseString componentsSeparatedByString:@"<gpx"];
	if([compo count] < 2) return @"";

	NSString *verStr = [self getQuoteValueOf:[compo objectAtIndex:1] withTag:@"version"];
	return verStr;
}

#pragma mark - Parser


@end
