/* P A S S

 * P:
 * creates a terrain like mesh based on noise values.
 * 
 * MOUSE
 * position x/y + left drag   : specify noise input range
 * position x/y + right drag  : camera controls
 * 
 * KEYS
 * l                          : toogle displaly strokes on/off
 * arrow up                   : noise falloff +
 * arrow down                 : noise falloff -
 * arrow left                 : noise octaves -
 * arrow right                : noise octaves +
 * space                      : new noise seed
 * +                          : zoom in
 * -                          : zoom out
 
 * S: add motion capture + some stuff
 * map noiseXrange to x movement, noise y range to y movement
 */
import gab.opencv.*;
import controlP5.*;
import processing.video.*;

Capture cam;
OpenCV opencv;
ControlP5 cp5;

Controller noiseModSlider;
Controller noiseXRangeSlider;
Controller noiseYRangeSlider;
Controller maxLayersSlider;
Controller layerDensitySlider;
Controller tileCountSlider;
Controller cubeUnitsSlider;
Controller cubeSizeSlider;

// ------ mesh ------
int cubeUnits = 9;
int cubeSize = 15;
int tileCount = 50;
int zScale = 100;
int maxLayers = 50;
int layerDensity = 10;

// ------ noise ------
float noiseMod = 80.0;
float noiseXRange = 0.5;
float noiseYRange = 0.5;
int octaves = 4;
float falloff = 0.5;

// ------ mesh coloring ------
color midColor = color(6, 35, 75);
color topColor = color(6, 55, 55);
color bottomColor = color(6, 35, 75);
color strokeColor = color(0);
float threshold = 0.50;

// ------ mouse interaction ------
int offsetX = 0, offsetY = 0, clickX = 0, clickY = 0, zoom = 500;
float rotationX = 0, rotationZ = PI, targetRotationX = -PI/3, targetRotationZ = PI, clickRotationX, clickRotationZ; 

// ------ image output ------
int qualityFactor = 4;
boolean showStroke = false;

//
PVector opticalFlow;
int ofThreshold = 100;
int flowScale = 10;
float cubeMoveX = 0;
float cubeMoveY = 0;

void setup() {
  fullScreen(P3D);
  //size(800, 800, P3D);
  colorMode(HSB, 360, 100, 100);
  
  cp5 = new ControlP5(this);
  String[] cameras = Capture.list();
  cam = new Capture(this,400, 300, cameras[0]);
  cam.start();
  opencv = new OpenCV(this, 400, 300);

  smooth();
  strokeJoin(ROUND);
  
  //cursor(0);
  //setupSliders();
}

void draw() {
  fill(0, 10, 100, 80);
  rect(0, 0, width, height);
  
  
  // call optical flow!
  opticalFlow();
  
  stroke(255,0,0);
  pushMatrix();
    translate(width - 200, 0);
    scale(3);
    pushMatrix();
      scale(-1,1);
      stroke(0, 32);
      strokeWeight(0.5);
      //fill(230);
      opencv.drawOpticalFlow();
    popMatrix();
  popMatrix();
  
  PVector aveFlow = opencv.getAverageFlow();
 
  
  //stroke(0);
  //strokeWeight(10);
  //line(width/2, height/2, width/2 + aveFlow.x*flowScale, height/2 + aveFlow.y*flowScale);
  
  if (showStroke) stroke(strokeColor);
  else noStroke();

  


  // ------ set view ------
  pushMatrix();
    translate(width*0.5, height*0.5, zoom);
    
    if (mousePressed && mouseButton==RIGHT) {
      offsetX = mouseX-clickX;
      offsetY = mouseY-clickY;
      targetRotationX = min(max(clickRotationX + offsetY/float(width) * TWO_PI, -HALF_PI), HALF_PI);
      targetRotationZ = clickRotationZ + offsetX/float(height) * TWO_PI;
    }      
    rotationX += (targetRotationX-rotationX)*0.25; 
    rotationZ += (targetRotationZ-rotationZ)*0.25;  
    rotateX(-rotationX);
    rotateZ(-rotationZ); 
    
    noiseDetail(octaves, falloff);
    cubeMoveX = constrain(
      cubeMoveX - 0.005 * cubeMoveX - (-aveFlow.x * flowScale),
      -85.0,
      85.0
    );
    cubeMoveY = constrain(
      cubeMoveY - 0.005 * cubeMoveY - (-aveFlow.y * flowScale),
      -75.0,
      75.0
    );  
    pushMatrix();
      translate(cubeMoveX, 0, -cubeMoveY);
      fill(255);//, 145);
      drawCube(cubeUnits, cubeSize);
    popMatrix();
  popMatrix(); 
  lights();
}

void opticalFlow() {
  //image(cam, 0, 0);
  
  opencv.loadImage(cam);
  
  opencv.gray();
  opencv.threshold(ofThreshold);
  
  opencv.calculateOpticalFlow();
  opticalFlow = opencv.getAverageFlow();
  
  //noiseXRange = opticalFlow.x;
  noiseXRange = noiseXRange - 0.002 * noiseXRange - opticalFlow.x;
  //noiseYRange = opticalFlow.y;
  noiseYRange = noiseYRange - 0.002 * noiseYRange - opticalFlow.y;
}

void captureEvent(Capture cam) {
  cam.read();
}

void drawCube(int units, float size){
  pushMatrix();
    //// front and back
    drawFacePair(units, size);
    rotateX(HALF_PI);
    //// top and bottom
    //drawFacePair(units, size);
    rotateY(HALF_PI);
    //// left and right
    drawFacePair(units, size);
  popMatrix();
}

void drawFacePair(int units, float size){
  pushMatrix();
    translate(0,0,units*size/2);
    drawSheet(units, units, size, size);
    translate(0,0,-units*size);
    drawSheet(units, units, size, size);
  popMatrix();
}

void drawSheet(int cols, int rows, float w, float h){  
  pushMatrix();
  translate(-cols*w/2,-rows*h/2);
  for (int meshY = 0; meshY < rows; meshY++) {
    beginShape(TRIANGLE_STRIP); 
    for (int meshX = 0; meshX <= cols; meshX++) {
      float noiseX = map(meshX, 0, cols, 0, noiseXRange);
      float noiseY = map(meshY, 0, rows, 0, noiseYRange);
      //float noiseZ
      float z1 = noise(noiseX, noiseY);//, noiseZ);      
      vertex(meshX*w, meshY*h, z1*noiseMod);//, + z1*zScale);
      vertex(meshX*w, meshY*h + h, z1*noiseMod);//, + z2*zScale); 
    }
    endShape();
  }
  popMatrix();
}

void mousePressed() {
  clickX = mouseX;
  clickY = mouseY;
  clickRotationX = rotationX;
  clickRotationZ = rotationZ;
}

void keyPressed() {
  if (keyCode == UP) falloff += 0.05;
  if (keyCode == DOWN) falloff -= 0.05;
  if (falloff > 1.0) falloff = 1.0;
  if (falloff < 0.0) falloff = 0.0;

  if (keyCode == LEFT) octaves--;
  if (keyCode == RIGHT) octaves++;
  if (octaves < 0) octaves = 0;

  if (key == '+') zoom += 20;
  if (key == '-') zoom -= 20;
}

void keyReleased() {  
  if (key == 'l' || key == 'L') showStroke = !showStroke;
  if (key == ' ') noiseSeed((int) random(100000));
}

void setupSliders() {
  
  //noiseXRangeSlider =  cp5.addSlider("noiseXRange")
  //  .setPosition(25, 1*25)
  //  .setRange(0.0, 4.0)
  //  .setColorLabel(0)
  //  ;
  //noiseYRangeSlider =  cp5.addSlider("noiseYRange")
  //  .setPosition(25, 2*25)
  //  .setRange(0.0, 4.0)
  //  .setColorLabel(0)
  //  ;
  noiseModSlider =  cp5.addSlider("noiseMod")
    .setPosition(25, 3*25)
    .setRange(0.0, 300.0)
    .setColorLabel(0)
    ;
  cubeUnitsSlider =  cp5.addSlider("cubeUnits")
    .setPosition(25, 4*25)
    .setRange(5, 100)
    .setColorLabel(0)
    ;
  cubeSizeSlider =  cp5.addSlider("cubeSize")
    .setPosition(25, 5*25)
    .setRange(5, 100)
    .setColorLabel(0)
    ;
    
}
