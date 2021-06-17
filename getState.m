function[center,theta]  =  getState(temp)
center = [mean([temp(2) temp(5) temp(8)]) mean([temp(3) temp(6) temp(9)])];
for j = 0:2
    if temp(j*3+1)==2                                           %find front leg for theta calc
        frontx = temp(j*3+2);
        fronty = temp(j*3+3);
        theta = atan2(fronty-center(2),frontx-center(1));
    end
end
end
