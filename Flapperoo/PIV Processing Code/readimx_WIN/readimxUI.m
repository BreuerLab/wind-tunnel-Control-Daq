function [A] = readimxUI( )
A='no file';
%Display located vector field 
[f,p] = uigetfile('*.im?');
if ischar(f),
  A = readimx([p f]);
  showimx(A.Frames{1});
end
