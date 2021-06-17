function [MuApprox]=MuInterp(Param,Sweep,TransAngle)
%{
Author: Taylor McLaughlin
Date: September 2020
Contact: mclaughlintay16@gmail.com

Goal: This function ireturns an estimation of average environmental friction(mu)
      from multiple sweep and translation angle measurements.

Notation: Please see comments for an elaboration on notation
%}
  
  MuApprox=zeros(1,lenght(Sweep));      %Preallocate space
  for i=1:length(Sweep)
    MuApprox(i)=griddata(Param.MuInput,Param.MuAng,Param.Fric,Sweep,TransAngle);     %Interpolate mu value using experimental surface
  end
  MuApprox=mean(MuApprox);      %Calculate mean mu value
end
