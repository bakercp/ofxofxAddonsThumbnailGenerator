#pragma

#include "ofMain.h"
#include "ofxGifEncoder.h"

class ofApp : public ofBaseApp{

	public:
		void setup();
		void update();
		void draw();
        
        void keyPressed(int key);
        void onGifSaved(string & fileName);

        void exit();

        ofImage screen;

        bool bIsRecording;

        string yourAddonName;

        int frameW, frameH;
        int nFrames;
        int maxFrames;

        ofxGifEncoder gifEncoder;

        ofTrueTypeFont font;
};


