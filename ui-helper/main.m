//
//  main.m
//  ui-helper
//
//  Created by Longbiao CHEN on 6/9/19.
//  Copyright © 2019 LONGBIAO CHEN. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

const double LEFT_RATIO = .57;

int main(int argc, const char * argv[]) {

    if(argc==1){
        printf("This is a helper program for manuplating UI instructions.\n");
        return 0;
    }
    
    const char* instruction = argv[1];
    const int code = atoi(argv[2]);
    // printf("%s to %d\n", instruction, code);
    // DOCK
    if(strcmp("dock", instruction)==0){
        // get dock app
        NSArray *apps = [NSRunningApplication runningApplicationsWithBundleIdentifier:@"com.apple.dock"];
        NSRunningApplication *dockApp = apps[0];
        AXUIElementRef dockElement = AXUIElementCreateApplication(dockApp.processIdentifier);
        AXUIElementRef window;
        AXUIElementCopyAttributeValue(dockElement, kAXFocusedWindowAttribute, (CFTypeRef *)&window);
        CFArrayRef children = NULL;
        AXUIElementCopyAttributeValue(dockElement, kAXChildrenAttribute, (const void **)&children);
        AXUIElementCopyAttributeValue((AXUIElementRef)CFArrayGetValueAtIndex(children, 0), kAXChildrenAttribute, (const void **)&children);
        // iterate through dock items
        printf("[");
        for(int i = 0; i < CFArrayGetCount(children); ++i) {
            if(i) printf(", ");
            AXUIElementRef child = (AXUIElementRef)CFArrayGetValueAtIndex(children, i);
            CFStringRef identifier;
            AXUIElementCopyAttributeValue(child, kAXTitleAttribute, (const void **)&identifier);
            CFTypeRef value;
            AXUIElementCopyAttributeValue(child, kAXPositionAttribute, (CFTypeRef *)&value);
            CGPoint pos;
            AXValueGetValue(value, kAXValueCGPointType, &pos);
            printf("{\"name\": \"%s\", \"pos\": {\"x\": %.0f, \"y\": %.0f}}", [(__bridge NSString *)identifier UTF8String], pos.x, pos.y);
        }
        printf("]\n");
        return 0;
    }
    // SCREEN
    if(strcmp("screen", instruction)==0){
        // get app window
        NSRunningApplication *app = [[NSWorkspace sharedWorkspace] frontmostApplication];
        printf("%s",app.localizedName.UTF8String);
        AXUIElementRef appRef = AXUIElementCreateApplication([app processIdentifier]);
        AXUIElementRef winRef;
        AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute, (CFTypeRef *)&winRef);
        // get screen size and pos
        AXValueRef posRef, sizeRef;
        if(NSScreen.screens.count == 1){
            // single screen
            NSScreen *screen = NSScreen.screens[0];
            CGRect bounds = CGDisplayBounds([[screen deviceDescription][@"NSScreenNumber"] unsignedIntValue]);
            posRef = AXValueCreate(kAXValueCGPointType, &bounds.origin);
            sizeRef = AXValueCreate(kAXValueCGSizeType, &bounds.size);
            CGPoint pos;
            CGSize size;
            AXValueGetValue(posRef, kAXValueCGPointType, &pos);
            AXValueGetValue(sizeRef, kAXValueCGSizeType, &size);
            // calculate new size and pos
            switch (code) {
                case 1:
                    // split on the right
                    pos.x += size.width * LEFT_RATIO;
                    size.width *= (1 - LEFT_RATIO);
                    break;
                case 2:
                    // split on the left
                    size.width *= LEFT_RATIO;
                    break;
                    // keep unchanged
                default:
                    break;
            }
            posRef = AXValueCreate(kAXValueCGPointType, &pos);
            sizeRef = AXValueCreate(kAXValueCGSizeType, &size);
        } else{
            // multiple screens
            // get screen size and pos
            NSScreen *screen = NSScreen.screens[code];
            CGRect bounds = CGDisplayBounds([[screen deviceDescription][@"NSScreenNumber"] unsignedIntValue]);
            posRef = AXValueCreate(kAXValueCGPointType, &bounds.origin);
            sizeRef = AXValueCreate(kAXValueCGSizeType, &bounds.size);
        }
        // move window
        AXUIElementSetAttributeValue(winRef, kAXPositionAttribute, posRef);
        AXUIElementSetAttributeValue(winRef, kAXSizeAttribute, sizeRef);
    }
    // MOUSE
    if(strcmp("mouse", instruction)==0){
        // get screen bounds
        if(NSScreen.screens.count == 1){
            return 0;
        }
        NSScreen *screen = NSScreen.screens[code];
        CGRect bounds = CGDisplayBounds([[screen deviceDescription][@"NSScreenNumber"] unsignedIntValue]);
        // determine screen center
        CGPoint pos = { .x =  bounds.origin.x + bounds.size.width/2,
            .y =  bounds.origin.y + bounds.size.height/2 };
        // get mouse position
        NSPoint cursor = CGEventGetLocation(CGEventCreate(NULL));
        // determine whehter the mouse is inside the screen
        Boolean cursor_in_screen = cursor.x - bounds.origin.x >= 0 & cursor.x - bounds.origin.x <= bounds.size.width & cursor.y - bounds.origin.y >= 0 & cursor.y - bounds.origin.y <= bounds.size.height;
        // printf("[%.0f, %.0f], [%.0f, %.0f], [%.0f, %.0f], [%.0f, %.0f], %d\n", cursor.x, cursor.y, bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height, pos.x, pos.y, cursor_in_screen);
        if(!cursor_in_screen){
            // move cursor to screen center
            CGDisplayMoveCursorToPoint(0, pos);
        }
        return 0;
    }
}
