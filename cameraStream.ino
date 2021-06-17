//Author: Mark Hermes
//Date: Sept 2020
//Contact: markherm@usc.edu
//
//Descrition: This script streams pixy2 tracked objects using a custom handshake
//    routine -> MATLAB sends "0", then Arduino sends camera packet. 

// https://docs.pixycam.com/wiki/doku.php?id=wiki:v2:hooking_up_pixy_to_a_microcontroller_-28like_an_arduino-29

#include <Pixy2.h>

int locs[10];
int refX[2];                              // initially this calibration value is (276-46) pixels / 32inches = 7.188 pixels/inch = 182.6 pixels/mm
Pixy2 pixy;

void setup()
{
  Serial.begin(115200);
  pixy.init();
  int calibDist = calibrate(&refX[0]);    //See if calibDist changed = should be 230
  Serial.print("calibration is ");
  Serial.println(calibDist);
}

void loop()
{
  if (Serial.available() > 0)             // wait until MATLAB sends 0
  {
    char key = Serial.read();             //make sure it is a 0 and not just a read request
    if (key == '0') 
    {
      blockLocations(&locs[0], &refX[0]);     //Use pointers for array modifications in C++
    }
  }
}

void blockLocations(int *locs, int *refX)     //Can do dynamic calibration, but won't for faster transmission
{
  pixy.ccc.getBlocks();
  if (pixy.ccc.numBlocks)
  {
    for (int i = 0; i < pixy.ccc.numBlocks; i++)
    {
      int w = pixy.ccc.blocks[i].m_width; //sort by width
      int x = pixy.ccc.blocks[i].m_x;
      int y = pixy.ccc.blocks[i].m_y;
      int sig = pixy.ccc.blocks[i].m_signature;
      if (w > 12)
      {
        //Serial.println(x);                // This prints calibration locations, but disregard unless debugging
      }
      else
      {
        locs[0] = sig;                      //I guess I dont need an array actually for streaming to MATLAB OH WELL
        locs[1] = x;
        locs[2] = y;
        for (int j = 0; j <= 2; j++)
        {
          Serial.println(locs[j]);
        }
      }
    }
  }
}

int calibrate(int *refX)
{
  int calibIndx = 0;                      //Keep track of identified calibration blocks
  pixy.ccc.getBlocks();                   //This is the pixy function for feature extraction
  if (pixy.ccc.numBlocks) 
  {
    for (int i = 0; i < pixy.ccc.numBlocks; i++)
    {
      int w = pixy.ccc.blocks[i].m_width; //sort by width
      int x = pixy.ccc.blocks[i].m_x;
      int y = pixy.ccc.blocks[i].m_y;
      int sig = pixy.ccc.blocks[i].m_signature;

      if (w > 15)                         //pull out the distance calibration blocks. (Not at the exact same level as tracking, so there is probably uncertainty here)
      {
        refX[calibIndx] = x;
        calibIndx++;
      }
    }
    return ( abs( refX[0] - refX[1]));    //This distance is 32 inches IRL
  }
}
