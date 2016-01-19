//
//  view.m
//  trailPath
//
//  Created by Hamish Knight on 19/01/2016.
//  Copyright © 2016 Redonkulous Apps. All rights reserved.
//

#import "view.h"

/// Represents a small portion of a trail.
@interface trailSubPath : NSObject

/// The subpath of the trail.
@property (nonatomic) CGPathRef path;

/// The alpha of this section.
@property (nonatomic) CGFloat alpha;

/// The delay before the subpath fades
@property (nonatomic) CGFloat delay;

@end

@implementation trailSubPath


+(instancetype) subPathWithPath:(CGPathRef)path alpha:(CGFloat)alpha delay:(CGFloat)delay {
    trailSubPath* subpath = [[self alloc] init];
    subpath.path = path;
    subpath.alpha = alpha;
    subpath.delay = delay;
    return subpath;
}

@end

/// How long before a subpath starts to fade.
static CGFloat const pathFadeDelay = 5.0;

/// How long the fading of the subpath goes on for.
static CGFloat const pathFadeDuration = 1.0;

/// The stroke width of the path.
static CGFloat const pathStrokeWidth = 3.0;


@implementation view {
    
    UIColor* trailColor;
    NSMutableArray* trailSubPaths;
    
    CGPoint lastPoint;
    BOOL touchedDown;
    
    CADisplayLink* displayLink;
}

-(instancetype) initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        trailSubPaths = [NSMutableArray array];
        trailColor = [UIColor redColor];
        
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

-(void) touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    lastPoint = [[[event allTouches] anyObject] locationInView:self];
    touchedDown = YES;
    
    [displayLink invalidate]; // In case it's already running.
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkDidFire)];
    [displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}



-(void) touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (touchedDown) {
        
        CGPoint p = [[[event allTouches] anyObject] locationInView:self];
        
        CGMutablePathRef mutablePath = CGPathCreateMutable(); // Create a new subpath
        CGPathMoveToPoint(mutablePath, nil, lastPoint.x, lastPoint.y);
        CGPathAddLineToPoint(mutablePath, nil, p.x, p.y);
        
        // Create new subpath object
        [trailSubPaths addObject:[trailSubPath subPathWithPath:CGPathCreateCopy(mutablePath) alpha:1.0 delay:pathFadeDelay]];
        
        CGPathRelease(mutablePath);

        lastPoint = p;
    }
}

-(void) touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    touchedDown = NO;
}

-(void) touchesCancelled:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

-(void) displayLinkDidFire {
    
    // Calculate change in alphas and delays.
    CGFloat deltaAlpha = displayLink.duration/pathFadeDuration;
    CGFloat deltaDelay = displayLink.duration;
    
    NSMutableArray* subpathsToRemove = [NSMutableArray array];
    
    for (trailSubPath* subpath in trailSubPaths) {
        
        if (subpath.delay > 0) subpath.delay -= deltaDelay;
        else subpath.alpha -= deltaAlpha;
        
        if (subpath.alpha < 0) { // Remove subpath
            [subpathsToRemove addObject:subpath];
            CGPathRelease(subpath.path);
        }
    }
    
    [trailSubPaths removeObjectsInArray:subpathsToRemove];

    
    // Cancel running if nothing else to do.
    if (([trailSubPaths count] == 0) && !touchedDown) [displayLink invalidate];
    else [self setNeedsDisplay];
}


- (void)drawRect:(CGRect)rect {

    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextSetStrokeColorWithColor(ctx, trailColor.CGColor);
    CGContextSetLineWidth(ctx, pathStrokeWidth);
    
    for (trailSubPath* subpath in trailSubPaths) {
        CGContextAddPath(ctx, subpath.path);
        CGContextSetAlpha(ctx, subpath.alpha);
        CGContextStrokePath(ctx);
    }

}


@end
