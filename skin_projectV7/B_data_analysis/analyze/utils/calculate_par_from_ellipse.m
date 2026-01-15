function [par,lambda00,lambda11,lambda01,A_rotated,B_rotated] = calculate_par_from_ellipse(hue_angle, chroma, long_axis, short_axis, theta, alpha)
    % calculateEllipseParameters: Calculates ellipse parameters par(1) to par(6)
    % from hue_angle, chroma, long_axis, short_axis, theta, and alpha.
    %
    % Inputs:
    %   hue_angle: Hue angle in degrees (0-360)
    %   chroma: Chroma value
    %   long_axis: Length of the long axis of the ellipse
    %   short_axis: Length of the short axis of the ellipse
    %   theta: Orientation angle of the ellipse in degrees (0-360)
    %   alpha: Alpha value (related to -log(par(6)))
    %
    % Output:
    %   par: A 1x6 vector containing the calculated ellipse parameters [par(1), ..., par(6)]
    
    % Ensure theta is in radians for trigonometric functions if needed,
    % but cosd, sind, atan2d work with degrees.
    % Ensure hue_angle and theta are in [0, 360) range
    hue_angle = mod(hue_angle, 360);
    theta = mod(theta, 360);
    
    % So, let A_rotated = 1/long_axis^2 and B_rotated = 1/short_axis^2.
    A_rotated = 1 ./ (long_axis.^2);
    B_rotated = 1 ./ (short_axis.^2);
    
    lambda00 = (A_rotated + B_rotated) / 2 + (A_rotated - B_rotated) / 2 .* cosd(2 .* theta);
    lambda11 = (A_rotated + B_rotated) / 2 - (A_rotated - B_rotated) / 2 .* cosd(2 .* theta);
    lambda01 = (A_rotated - B_rotated) / 2 .* sind(2 .* theta);

    
    par1 = lambda00 .* alpha.^2;
    par2 = lambda11 .* alpha.^2;
    par3 = lambda01 .* alpha.^2 .* 2;

        % Calculate par(6)
    par6 = exp(-alpha);

    par4 = chroma .* cosd(hue_angle);
    par5 = chroma .* sind(hue_angle);
    
    par = [par1, par2, par3, par4, par5, par6];

end