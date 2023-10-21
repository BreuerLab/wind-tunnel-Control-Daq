% Author: Ronan Gissler
% Last updated: October 2023

% What's the reasoning behind the rotation process:
% The pitch angle is adjusted via the MPS system and the force transducer
% has a constant yaw offset (in its reference frame) of 205 degrees. Why is
% the force transducer yawed? Well the cable has to stick out the back, so
% x- must point downstream although typically x- is upstream in wind tunnel
% experiments. Second, the metal plate used to mount the force transducer
% had an existing set of holes for an older force transducer. To find space
% for this new force transducer we had to put the holes elsewhere on the
% plate, we arbitrarily chose to put them 20 degrees off from the old
% holes.

% So the force transducer has a constant yaw angle in its frame and a
% variable pitch angle in the wind tunnel frame.
% First let's align the y-axis of the force transducer with the y-axis of
% the wind tunnel by rotating the force transducer reference frame about
% the z-axis:
%                      (Z Rotation Matrix) * data
% Now y means left to right, but z and x still change as we change angle of
% attack. So let's do a rotation about the y-axis to align the x and z axes
% of the force transducer with the wind tunnel:
%           (Y Rotation Matrix) * (Z Rotation Matrix) * data
% That should be it!
% In the code below, I implement these steps using: 
% dcm_F = angle2dcm(yaw, pitch, roll,'ZYX');
% where dcm is the direct cosine matrix (just the product of these
% individual rotation matrices)

% Interestingly, what's working now is not that. Instead we are thinking
% about going from the wind tunnel reference frame to the force transducer
% reference frame.
% First let's align the z-axis of the wind tunnel with the z-axis of the
% force transducer by rotating the wind tunnel reference frame about the
% y-axis:
%                   (Y Rotation Matrix) * (wind tunnel frame)
% Now the z-axis of the wind tunnel is aligned normal to the surface of the
% force transducer, but x and y are still misaligned. So let's do a
% rotation about the z-axis to align the x and y axes of the wind tunnel
% with the force transducer:
%      (Z Rotation Matrix) * (Y Rotation Matrix) * (wind tunnel frame)
% But our data is in the force transducer frame so if we moved the rotation
% matrices to the other sides of the equation we need to take their inverse
% (same as transpose for rotation matrices, i.e they are orthogonal)
%   [Transpose of ((Z Rotation Matrix) * (Y Rotation Matrix))] * data
% Why this produces a different result than the process described before? I
% have no idea, but the results look better for the static aerodynamics.
% In the code below, I implement these steps using: 
% dcm_F = angle2dcm(roll, pitch, yaw, 'XYZ');

% Note: I am concerned this function might not be working properly
% Way to verify that it is working correctly:

% 1. When performing a weight taring experiment (i.e. no wind, no flapping,
% just adjusting pitch angle via MPS system), we'd expect the rotated data
% to show a constant force in the z-direction and near zero forces in the
% x and y directions as we change the pitch angle. What would we expect
% with the moments? The yaw and rolling moments should be near zero as 
% we're changing the pitch angle, not roll or yaw angles. Since the system
% is back heavy, it's always wanting to pitch up but this moment arm would
% decrease as you increase or decrease the angle of attack (although it
% shouldn't flip sign). I did some experiments with putting masses on the
% X+, X-, Y-, Y+ sides of the force transducer to identify how a positive
% moment is defined by the force transducer. See 10_07_2023 Weight Test.
% Results summarized here:
% Mass on X+ - +M_y
% Mass on X- - -M_y
% Mass on Y+ - -M_x
% Mass on Y- - +M_x

% 2. When performing a static aerodynamic experiment (i.e wings attached,
% wind on, no flapping, adjusting pitch angle via MPS system), we'd expect
% the rotated data to show near zero force in the y-direction, an upwards
% facing parabola for force in the x-direction, something like sin(x)
% -3pi/4 < x < 3pi/4 for the z-direction. This is based on data available
% for regular airfoils tested in wind tunnels. The yaw and rolling moments
% should be near zero as we're changing the pitch angle, not roll or yaw
% angles. I'm not sure what to expect for the pitching moment curve.

% Inputs:
% results - (n x 6) force transducer data
% pitch - pitch angle set by MPS system

% Returns:
% results_lab - (n x 6) rotated force transducer data
function results_lab = coordinate_transformation(results, pitch_d)
    yaw_d = 205; % At 0 pitch angle, x- rotated 25 degrees from downstream
    roll_d = 0;
    
    pitch = deg2rad(pitch_d);
    roll = deg2rad(roll_d);
    yaw = deg2rad(yaw_d);
    
%     dcm_F = angle2dcm(roll, pitch, yaw, 'XYZ');
    dcm_F = angle2dcm(yaw, pitch, roll,'ZYX');
%     dcm_M = angle2dcm(roll, pitch, yaw, 'XYZ');
    dcm_M = angle2dcm( roll, 0, yaw, 'XYZ');
    
    F_lab = (dcm_F * results(:, 1:3)')';
%     T_lab = (roty(-pitch) * dcm_M' * results(:, 4:6)')';
    T_lab = (dcm_M * results(:, 4:6)')';
    results_lab = [F_lab, T_lab];
end

   % Z-rotation * Y-rotation * X rotation, so X-rotation first, then
   % Y-rotation, then Z-rotation
%     dcm_comp = [cos(yaw),sin(yaw),0; -sin(yaw),cos(yaw),0; 0,0,1]*...
%         [cos(pitch),0,-sin(pitch); 0,1,0; sin(pitch),0,cos(pitch);]*...
%         [1,0,0; 0,1,0; 0,0,1];    