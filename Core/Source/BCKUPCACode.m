//
//  BCKUPCACode.m
//  BarCodeKit
//
//  Created by Jaanus Siim on 9/17/13.
//  Copyright (c) 2013 Oliver Drobnik. All rights reserved.
//

#import "BCKUPCACode.h"
#import "NSError+BCKCode.h"
#import "BCKEANCodeCharacter.h"
#import "BCKUPCCodeCharacter.h"

@implementation BCKUPCACode

#pragma mark - Subclassing Methods

//TODO jaanus: copy/paste from EAN-13
- (NSUInteger)_digitAtIndex:(NSUInteger)index
{
	NSString *digitStr = [self.content substringWithRange:NSMakeRange(index, 1)];
	return [digitStr integerValue];
}

+ (BOOL)canEncodeContent:(NSString *)content error:(NSError *__autoreleasing *)error
{
	NSUInteger length = [content length];

	if (length != 12)
	{
		if (error)
		{
			NSString *message = [NSString stringWithFormat:@"%@ requires content to be 12 digits", NSStringFromClass([self class])];
			*error = [NSError BCKCodeErrorWithMessage:message];
		}

		return NO;
	}

	NSInteger checkSum = 0;

	for (NSUInteger index=0; index<[content length]; index++)
	{
		NSString *character = [content substringWithRange:NSMakeRange(index, 1)];
		char c = [character UTF8String][0];

		if (!(c>='0' && c<='9'))
		{
			if (error)
			{
				NSString *message = [NSString stringWithFormat:@"%@ cannot encode '%@' at index %d", NSStringFromClass([self class]), character, (int)index];
				*error = [NSError BCKCodeErrorWithMessage:message];
			}

			return NO;
		}

		if (index == [content length] - 1) {
			continue;
		}

		NSInteger multiply = ((index % 2) != 0 ? 1 : 3);
		NSInteger digit = [character integerValue];
		checkSum += (digit * multiply);
	}

	NSInteger remainder = checkSum % 10;
	NSInteger calculatedCheck = 10 - remainder;
	if (calculatedCheck == 10) {
		calculatedCheck = 0;
	}

	NSInteger inputCheckNumber = [[content substringFromIndex:11] integerValue];

	if (calculatedCheck != inputCheckNumber) {
		if (error)
		{
			NSString *message = @"Invalid barcode provided. Check number does not match";
			*error = [NSError BCKCodeErrorWithMessage:message];
		}

		return NO;
	}

	return YES;
}

+ (NSString *)barcodeStandard
{
	return @"International standard ISO/IEC 15420";
}

+ (NSString *)barcodeDescription
{
	return @"UPC-A";
}

- (NSUInteger)horizontalQuietZoneWidth
{
	return 10;
}

- (NSArray *)codeCharacters
{
	// If the array was created earlier just return it
	if (_codeCharacters)
	{
		return _codeCharacters;
	}

	NSMutableArray *tmpArray = [NSMutableArray array];


	// start marker
	[tmpArray addObject:[BCKEANCodeCharacter endMarkerCodeCharacter]];

	for (NSUInteger index = 0; index < 12; index ++)
	{
		NSUInteger digit = [self _digitAtIndex:index];
		BCKEANCodeCharacterEncoding encoding = (index <6 ? BCKEANCodeCharacterEncoding_L : BCKEANCodeCharacterEncoding_R);

		BCKEANCodeCharacter *codeCharacter = [BCKEANCodeCharacter codeCharacterForDigit:digit encoding:encoding];
		if (index == 0 || index == 11)
		{
			codeCharacter = [BCKUPCCodeCharacter markerCharacterWithEANCharacter:codeCharacter];
		}

		[tmpArray addObject:codeCharacter];

		if (index == 5)
		{
			// middle marker
			[tmpArray addObject:[BCKEANCodeCharacter middleMarkerCodeCharacter]];
		}
	}

	// end marker
	[tmpArray addObject:[BCKEANCodeCharacter endMarkerCodeCharacter]];

	_codeCharacters = [tmpArray copy];
	return _codeCharacters;
}

- (NSString *)captionTextForZone:(BCKCodeDrawingCaption)captionZone withRenderOptions:(NSDictionary *)options
{
	if (captionZone == BCKCodeDrawingCaptionLeftQuietZone)
	{
		return [self.content substringToIndex:1];
	}
	else if (captionZone == BCKCodeDrawingCaptionRightQuietZone)
	{
		return [self.content substringFromIndex:11];
	}
	else if (captionZone == BCKCodeDrawingCaptionLeftNumberZone)
	{
		return [self.content substringWithRange:NSMakeRange(1, 5)];
	}
	else if (captionZone == BCKCodeDrawingCaptionRightNumberZone)
	{
		return [self.content substringWithRange:NSMakeRange(6, 5)];
	}

	return nil;
}

- (NSString *)defaultCaptionFontName
{
	return @"OCRB";
}

- (CGFloat)aspectRatio
{
	return 39.29 / 25.91;
}

- (BOOL)markerBarsCanOverlapBottomCaption
{
	return YES;
}

@end
