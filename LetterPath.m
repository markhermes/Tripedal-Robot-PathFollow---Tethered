function [GOAL]=LetterPath(string)
GOAL.X=[];
GOAL.Y=[];
offset=0;
for i=1:length(string)
    curr=string(i);
    points=LetterLibrary(curr);
    GOAL.X=[GOAL.X points.X+offset];
    GOAL.Y=[GOAL.Y points.Y];
    offset=offset+max(points.X)+.15;
end