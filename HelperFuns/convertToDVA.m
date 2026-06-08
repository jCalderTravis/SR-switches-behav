function dva = convertToDVA(fracScreenHeight, screenHeight, distance)
%
% INPUT
% fracScreenHeight: The fraction of the screen height from the centre of
%   the screen to the point of interest.
% screenHeight: Screen height in meters.
% distance: Distance to screen in meters.

height = fracScreenHeight .* screenHeight;
theta = atan(height ./ distance);
dva = (theta * 360) / (2*pi);

end

