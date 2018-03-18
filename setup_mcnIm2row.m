function setup_mcnIm2row()
%SETUP_MCNIM2ROW Sets up mcnIm2row, by adding its folders
% to the Matlab path
%
% Copyright (C) 2018 James Thewlis and Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  root = fileparts(mfilename('fullpath')) ;
  addpath(root, [root '/matlab'], [root '/misc']) ;
  addpath( [root '/matlab/mex']) ;
