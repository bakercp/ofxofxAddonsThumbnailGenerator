#include "ofApp.h"

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
    capturedImage = CGWindowListCreateImage( windowRect, kCGWindowListOptionOnScreenBelowWindow, windowID, kCGWindowImageDefault );

    // The rest is as in the previous example...
    if(CGImageGetWidth(capturedImage) <= 1) {
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


//--------------------------------------------------------------
void ofApp::setup(){
    font.loadFont(OF_TTF_SANS,14);

    yourAddonName = "ofxYourAddon";

    frameW  = 270;
    frameH  = 70;
    nFrames = 0;
    maxFrames = 48;
    bIsRecording = false;

    ofSetFrameRate(15);
    gifEncoder.setup(frameW, frameH, 1.0f/ofGetFrameRate(), 256);
    ofAddListener(ofxGifEncoder::OFX_GIF_SAVE_FINISHED, this, &ofApp::onGifSaved);
}

//--------------------------------------------------------------
void ofApp::update(){ 

    unsigned char * data = pixelsBelowWindow(ofGetWindowPositionX(),
                                             ofGetWindowPositionY(),
                                             frameW,
                                             frameH);

    for (int i = 0; i < frameW * frameH; i++) {
		unsigned char r1 = data[i*4]; // mem A
		data[i*4]   = data[i*4+1];
		data[i*4+1] = data[i*4+2];
		data[i*4+2] = data[i*4+3];
		data[i*4+3] = r1;
	}
    
    screen.setFromPixels(data, frameW, frameH, OF_IMAGE_COLOR_ALPHA);

    if(bIsRecording) {
        screen.setImageType(OF_IMAGE_COLOR);
        gifEncoder.addFrame(screen.getPixels(), frameW, frameH, 24, .1);
        nFrames++;
        if(nFrames > maxFrames) {
            cout <<"Saving ..." << endl;
            gifEncoder.save("ofxaddons_thumbnail.png");
            bIsRecording = false;
        }
    }
}

//--------------------------------------------------------------
void ofApp::draw(){
    ofSetColor(255);
    screen.draw(0,0);

    ofRectangle infoRect(0,ofGetHeight()-24, font.getStringBoundingBox(yourAddonName, 0,0).width + 20, 24);

    ofSetColor(230, 232, 234);
    ofRect(infoRect);

    if(bIsRecording) {
        ofEnableAlphaBlending();
        ofSetColor(255,0,0,80);
        ofRect(infoRect.x,infoRect.y, (float)nFrames / maxFrames * infoRect.width, infoRect.height);
        ofDisableAlphaBlending();
    } else {
        if(ofRectangle(0,0,ofGetWidth(), ofGetHeight()).inside(ofGetMouseX(), ofGetMouseY())) {
            ofDrawBitmapStringHighlight("Press spacebar to record ...", 10,16,ofColor::magenta);
        }
    }

    if(infoRect.inside(ofGetMouseX(), ofGetMouseY())) {
        ofSetColor(ofColor::magenta);

        ofRectangle highlight(4,ofGetHeight()-22, font.getStringBoundingBox(yourAddonName, 0,0).width + 14, 20);
        ofRect(highlight);

        ofSetColor(255);
        font.drawString(yourAddonName, 10, ofGetHeight()-5);
    } else {
        ofSetColor(68);
        font.drawString(yourAddonName, 10, ofGetHeight()-5);
    }


}

//--------------------------------------------------------------
void ofApp::onGifSaved(string &fileName) {
    cout << "gif saved as " << fileName << endl;
    bIsRecording = false;
    nFrames = 0;
    ofSystem("open -a Safari " + ofToDataPath("ofxaddons_thumbnail.png",true));
}

//--------------------------------------------------------------
void ofApp::keyPressed(int key){
    if(key == ' ') {
        if(!bIsRecording) bIsRecording = true;
    }
}

//--------------------------------------------------------------
void ofApp::exit(){ 
    gifEncoder.exit();
}

