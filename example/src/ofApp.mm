// =============================================================================
//
// Copyright (c) 2013-2014 Christopher Baker <http://christopherbaker.net>
// Portions Copyright (c) 2014 Jordi Puig <http://www.wasawi.com/>
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// =============================================================================


#include "ofApp.h"
#include "ofAppGLFWWindow.h"
#include <Cocoa/Cocoa.h>
#include <AppKit/NSOpenGL.h>


CGImageRef capturedImage;


unsigned char * pixelsBelowWindow(int x, int y, int w, int h)
{
    // Get the CGWindowID of supplied window


	NSOpenGLContext * myContext = nil;
    NSView *myView = nil;
    NSWindow* window = nil;

    // In screensaver mode, set our window's level just above
    // our BOINC screensaver's window level so it can appear
    // over it.  This doesn't interfere with the screensaver
    // password dialog because the dialog appears only after
    // our screensaver is closed.
    myContext = [ NSOpenGLContext currentContext ];
    if (myContext)
        myView = [ myContext view ];
    if (myView)
        window = [ myView window ];
    if (window == nil)
        return NULL;


    CGWindowID windowID = [window windowNumber];

    // Get window's rect in flipped screen coordinates
    CGRect windowRect = NSRectToCGRect( [window frame] );
    windowRect.origin.y = NSMaxY([[window screen] frame]) - NSMaxY([window frame]);

	windowRect.origin.x = x;
	windowRect.origin.y = y;
	windowRect.size.width = w;
	windowRect.size.height = h;


    // Get a composite image of all the windows beneath your window
    capturedImage = CGWindowListCreateImage(windowRect,
                                            kCGWindowListOptionOnScreenBelowWindow,
                                            windowID,
                                            kCGWindowImageDefault);

    // The rest is as in the previous example...
    if(CGImageGetWidth(capturedImage) <= 1)
    {
        CGImageRelease(capturedImage);
        //return nil;
		return NULL;
    }

    // Create a bitmap rep from the window and convert to NSImage...
    NSBitmapImageRep *bitmapRep = [[[NSBitmapImageRep alloc] initWithCGImage: capturedImage] autorelease];
    NSImage *image = [[[NSImage alloc] init] autorelease];
    [image addRepresentation: bitmapRep];

	uint32* bitmapPixels = (uint32*) [bitmapRep bitmapData];

	CGImageRelease(capturedImage);
    return (unsigned char *) bitmapPixels;
    //return image;
}


void ofApp::setup()
{
    ofSetFrameRate(12);

    yourAddonName = "ofxYourAddon";
	
    frameW  = 270;
    frameH  = 70;

    // We must record the pixel scale to account for retina and other HDPI displays.
    // For this call to work, we must place the <key>NSHighResolutionCapable</key>
    // in the application's openFrameworks-Info.plist file.
	pixelScreenCoordScale = ((ofAppGLFWWindow*)ofGetWindowPtr())->getPixelScreenCoordScale();

    // This is a hack for retina displays.
    // It has no effect on non-retina displays.
    ofSetWindowShape(ofGetWidth(), ofGetHeight());

    font.loadFont(OF_TTF_SANS, 14 * pixelScreenCoordScale);

    nFrames = 0;
    maxFrames = 24;
    isRecording = false;

    gifEncoder.setup(frameW, frameH, 1.0f / ofGetFrameRate(), 256);

    ofAddListener(ofxGifEncoder::OFX_GIF_SAVE_FINISHED, this, &ofApp::onGifSaved);
}


void ofApp::update()
{
    unsigned char * data = pixelsBelowWindow(ofGetWindowPositionX()/pixelScreenCoordScale,
                                             ofGetWindowPositionY()/pixelScreenCoordScale,
                                             frameW,
                                             frameH);
	

    for (int i = 0; i < (frameW * pixelScreenCoordScale) * (frameH * pixelScreenCoordScale); ++i)
    {
		unsigned char r1 = data[i*4]; // mem A
		data[i*4]   = data[i*4+1];
		data[i*4+1] = data[i*4+2];
		data[i*4+2] = data[i*4+3];
		data[i*4+3] = r1;
	}

    if (pixelScreenCoordScale > 1)
    {
        screen.setFromPixels(data,
                             frameW * pixelScreenCoordScale,
                             frameH * pixelScreenCoordScale,
                             OF_IMAGE_COLOR_ALPHA);

		screen.resize(frameW, frameH);
	}
    else
    {
		screen.setFromPixels(data, frameW, frameH, OF_IMAGE_COLOR_ALPHA);
	}
	
    if(isRecording)
    {
        screen.setImageType(OF_IMAGE_COLOR);
        gifEncoder.addFrame(screen.getPixels(), frameW, frameH, 24, .1);
        nFrames++;
        if(nFrames > maxFrames)
        {
            ofLogNotice("ofApp::update") << "Saving ...";
            gifEncoder.save("ofxaddons_thumbnail.png");
            isRecording = false;
        }
    }
}


void ofApp::draw()
{
    ofSetColor(255);
    screen.draw(0,0,frameW*pixelScreenCoordScale, frameH*pixelScreenCoordScale);

    ofRectangle infoRect(0,
                         ofGetHeight() - 24*pixelScreenCoordScale,
                         font.getStringBoundingBox(yourAddonName, 0,0).width + 20,
                         24*pixelScreenCoordScale);

    ofSetColor(230, 232, 234);
    ofRect(infoRect);

    if(isRecording)
    {
        ofEnableAlphaBlending();
        ofSetColor(255,0,0,80);
        ofRect(infoRect.x,
               infoRect.y,
               (float)nFrames / maxFrames * infoRect.width,
               infoRect.height);

        ofDisableAlphaBlending();
    }
    else
    {
        if(ofRectangle(0,0,ofGetWidth(), ofGetHeight()).inside(ofGetMouseX(), ofGetMouseY()))
        {
            ofDrawBitmapStringHighlight("Press spacebar to record ...", 10,16,ofColor::magenta);
        }
    }

    if(infoRect.inside(ofGetMouseX(), ofGetMouseY()))
    {
        ofSetColor(ofColor::magenta);

        ofRectangle highlight(4,ofGetHeight()-22*pixelScreenCoordScale, font.getStringBoundingBox(yourAddonName, 0,0).width + 14, 20*pixelScreenCoordScale);
        ofRect(highlight);

        ofSetColor(255);
        font.drawString(yourAddonName, 10, ofGetHeight()-5);
    }
    else
    {
        ofSetColor(68);
        font.drawString(yourAddonName, 10, ofGetHeight()-5);
    }
}


void ofApp::onGifSaved(string &fileName)
{
    ofLogNotice("ofApp::onGifSaved") << "gif saved as " << fileName;
    isRecording = false;
    gifEncoder.reset();
    nFrames = 0;
    ofSystem("open -a Safari " + ofToDataPath("ofxaddons_thumbnail.png", true));
}


void ofApp::keyPressed(int key)
{
    if(key == ' ')
    {
        if(!isRecording) isRecording = true;
    }
}


void ofApp::exit()
{
    gifEncoder.exit();
}
