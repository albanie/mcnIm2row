function im2rowDemo
%IM2ROWDEMO simple im2row demo
%   IM2ROWDEMO illustrates the operation of the im2row function
%
% Copyright (C) 2018 James Thewlis and Samuel Albanie
% Licensed under The MIT License [see LICENSE.md for details]

  % read in a sample image
  im = single(imread('peppers.png')) ;

  % define a kernel/patch size
  ksize = [20 20] ;

  % apply im2row operation
  out = vl_nnim2row(im, ksize, 'pad', 1) ;

  % view the results
  subplot(1,2,1) ;
  imagesc(im/255) ; title('original image') ;
  subplot(1,2,2) ;
  imagesc(out) ; title('result of im2row') ;
