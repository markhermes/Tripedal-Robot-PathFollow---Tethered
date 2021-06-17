%{
Author: Mark Hermes
Date: Sept 2020
Contact: markherm@usc.edu

Descrition: This script streams pixy2 tracked objects using a custom handshake
    routine -> MATLAB sends "0", then Arduino sends camera packet. It also
    sends the sweep command every two cycles to the motor arduino.
%}
%% Closing serial instances. This is a failsafe -> double calling a Serial object is a disaster
try
    fclose(camObj);                             %place at the top because if you double call fopen for serial, have to restart computer
    fclose(motorObj);
catch
end
%% MAIN -> Communicate with arduinos and stream cam info
clear all;

ampTheta = [];
rawData = [];                           %raw data consists of the three servo x,y positions and color codes
camTimeStamp =[];
temp = [];
stateData =[];                          %maybe don't need to store state data, just use it when needed, But oh well.
motorTimeStamp = [];
PIXEL2M = 1 / (263 / 32 * 39.37);       %pixels / inch * (inch/m)
testSweep = [10 30 -30];                %0deg leg sweep,2pi/3 leg sweep, etc
testSweep = uint8(testSweep + 60);      %cant send negative numbers as bytes and want to minimize transmission time

camObj = serial('COM5','BaudRate',115200,'Terminator','LF');
motorObj = serial('COM6','BaudRate',115200,'Terminator','CR');
fopen(motorObj);
fopen(camObj);
formatSpec = 'char';

%% insert interpolation method here
% %Original mapping w/o momentum consideration
% load('AveragedMu(0.33_0.59_0.85)_SteadyState_0_to_30_Sweep');
% Param.AngOfTrans=OutputAngle;      %Angle of translation for LF case
% Param.AngInput=InputSweep;         %Sweep angles for LF case

load('LowFriction2Cycle');
Param.AngOfTrans=LowFrictionK_2Cycles;      %Angle of translation for LF case
Param.AngInput=LowFrictionK_Angles;         %Sweep angles for LF case

%% Main
%Set goal positions - SPELL USC
sinePath = sinePath();
PATH.X = sinePath(:,1);
PATH.Y = sinePath(:,2); 

pause(10);
h = figure(1);
while(ishandle(h)==1)                       %run the loop until I close the figure window (kind of a stop  button)
    for i = 1:length(PATH.X)
        radius = 10;                        %intialization value to enter the tracking loop
        GOAL.X = PATH.X(i)
        GOAL.Y = PATH.Y(i)
        while(radius > 0.015)               %until you get close to the target point
            sec = cputime;
            [camTimeStamp, rawData, stateData] = getCamStream(camObj,rawData, stateData, camTimeStamp, sec);
            
            if(~isempty(stateData))                 %wait until camera starts recording
                
                x=stateData(end,1)*PIXEL2M;         %Current X positon [m]
                y=stateData(end,2)*PIXEL2M;         %Current Y position [m]
                theta=stateData(end,3);             %Current rotation of body [rad]
                
                radius = sqrt((x-GOAL.X)^2 + (y-GOAL.Y)^2);
                
                [sweep]=SweepCalc(x,y,theta,GOAL,Param);        %Calculate the new sweep values for legs [Leg1, Leg2, Leg3]
                testSweep = uint8(round(sweep*180/pi)+60);      %Convert rads to  rounded angle, then add 60 to remove negative numbers
                
                motorTimeStamp = sendAngle(motorObj, testSweep, motorTimeStamp, sec);
                ampTheta = [ampTheta; testSweep x y theta GOAL.X GOAL.Y];
                
                plot(stateData(:,1)*PIXEL2M, stateData(:,2)*PIXEL2M,'*k');  %plot after motor send to minimize delay with new angle
                xlim([0 300]*PIXEL2M); ylim([0 200]*PIXEL2M);
                pause(0.001);
            end
        end
    end
end
trialName = 'sineRawFile';
csvwrite(trialName,[camTimeStamp rawData]);
trialName = 'sineStateFile';
csvwrite(trialName,[camTimeStamp stateData]);
trialName = 'sineMotorStamps';
csvwrite(trialName,[motorTimeStamp]);
trialName = 'sineAmpTheta';
csvwrite(trialName,[ampTheta]);

fclose(camObj);
fclose(motorObj);
%% Send the commanded angle to the motors
function motorTimeStamp = sendAngle(motorObj, testSweep, motorTimeStamp, sec)
if(motorObj.BytesAvailable)         %Send motor the updated sweep value
    flushinput(motorObj);
    %     fprintf(motorObj,'%d',testSweep);
    fwrite(motorObj,testSweep);
    motorTimeStamp = [motorTimeStamp; sec];
end
end
%% Get 1 packet of camera data from PIXY2
function [camTimeStamp, rawData, stateData] = getCamStream(camObj,rawData,stateData, camTimeStamp, sec)

temp = [];
while(camObj.BytesAvailable)        %get packet of data from camera arduino
    val = fscanf(camObj);
    try
        num = str2double(val);
        if(~isnan(num))             %only add numeric data, not initial startup dialog
            temp = [temp num];
        end
    catch
    end
end
if(~isempty(temp))                  %this check condition is due to initial startup communication dialogues
    try                             %this try catch is in case there are anomalies with tracking
        temp = temp(1:9);               %ugh idk why but sometimes the buffer had multiple signals
        temp([3 6 9]) = -temp([3 6 9])+160; %Since the y-tracking is flipped, flip the y-data (160 is near bottom)
        [center,theta] = getState(temp);
        rawData = [rawData;temp];
        stateData = [stateData;center theta];
        camTimeStamp = [camTimeStamp;sec];
    catch
    end
end
fprintf(camObj,'%d',0);                 %after the packet is read, query for a new packet
end

%% Diff combinations of param values


%Load interpolation values
%{
%Original mapping w/o momentum consideration
load('LowFriction2Cycle');
Param.AngOfTrans=LowFrictionK_2Cycles;      %Angle of translation for LF case
Param.AngInput=LowFrictionK_Angles;         %Sweep angles for LF case
%}

%{
%Updated mapping for nominal SIMULATED motion
load('Curves2');
Param.AngOfTrans=Ang(:,1);      %Angle of translation for LF case
Param.AngInput=Input(:,1);         %Sweep angles for LF case
%}

%{
%Median mapping
load('LowFriction2Cycle');
load('Curves2');
Param.AngOfTrans=(Ang(:,1)+LowFrictionK_2Cycles)/2;      %Angle of translation for LF case
Param.AngInput=Input(:,1);         %Sweep angles for LF case
%}

%{
%Load friction surface values
load('Surface')
Param.MuInput=Input;            %Experimental Sweep values
Param.MuAng=Ang;                %Experimental Translation angle values
Param.Fric=Fric;                %Experimental Mu values
%}
