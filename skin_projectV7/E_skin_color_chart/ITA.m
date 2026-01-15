function [type, ITA] = ITA(lab1)

center = [50, 0];

tanvalue = (lab1(:, 1) - center(:, 1)) ./ (lab1(:, 3) - center(:, 2));
ITA = atan(tanvalue) * 180 / pi;

for i = 1: length(ITA)
    v = ITA(i);
    if (v > 55) t = 1;
    elseif (v > 41) t = 2;
    elseif (v > 28) t = 3;
    elseif (v > 10) t = 4;
    elseif (v > -30) t = 5;
    else t = 6;
    end
    type(i, 1) = t;
end
end

