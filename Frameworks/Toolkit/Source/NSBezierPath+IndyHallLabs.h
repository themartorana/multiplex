#import <Cocoa/Cocoa.h>

typedef enum _IHCornerTypes {
	kIHTopLeftCorner = 1,
	kIHBottomLeftCorner = 2,
	kIHTopRightCorner = 4,
	kIHBottomRightCorner = 8
} IHCornerType;

@interface NSBezierPath (IndyHallLabs)

+ (NSPoint) pointWithPolarCenter:(NSPoint)center radius:(CGFloat)r angle:(CGFloat)deg;
+ (NSBezierPath*) circleSegmentWithCenter:(NSPoint)center startAngle:(CGFloat)a1 endAngle:(CGFloat)a2 smallRadius:(CGFloat)r1 bigRadius:(CGFloat)r2;
+ (NSBezierPath *) bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(CGFloat)radius inCorners:(IHCornerType)corners;
+ (NSBezierPath*) bezierPathWithRoundedRect:(NSRect)aRect cornerRadius:(CGFloat)radius;

@end
