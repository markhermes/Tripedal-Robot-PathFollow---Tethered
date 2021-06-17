# Tripedal-Robot-PathFollow---Tethered


This is the repository for the tethered (Serial communication) robot, where

MATLAB:
inputs -> (i) Pixycam2 signal (fed through dedicated arduino board) - <x,y> 
          (ii) Motor ready flag 
     
outputs -> (i) 3 byte Motor command sequence offset by 30degress, e.g. <60, 30, 0>  -> <30, 0 , -30> degrees sweep

