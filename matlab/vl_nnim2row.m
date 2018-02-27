%VL_NNIM2ROW im2row operation
%   Y = VL_NNIM2ROW(X, K) transforms an input tensor X and a patch
%   size K into a matrix whos rows correspond to patches of the given size which
%   have been densely sampled from X.  The tensor X has size H x W x C x N,
%   K is a 1 x 2 array of integers [KH KW] defining the height and width of the
%   patch and Y is a matrix with size size (H'' x W'') x (KW x KH x C) where
%   H'' and W'' correspond to the number of vertical/horizontal shifts that
%   should be applied to the patch location to cover the input image.

%   VL_NNIM2ROW(..., 'option', value, ...) accepts the following
%   options, which correspond directly to their meaning in VL_NNCONV, which can
%   be checked for further details:
%
%   `Stride`:: 1
%    Set the output stride or downsampling factor to the patch sampling
%    process. If the value is a scalar, then the same stride is applied to
%    both vertical and horizontal directions; otherwise, passing [STRIDEY STRIDEX]
%    allows specifying different downsampling factors for each direction.
%
%   `Pad`:: 0
%    Define the amount of spatial padding to be applied to the input tensor X.
%
%   `Dilate`:: 1
%    Dilate the patch sampling locations by the given factor. Passing
%    [DILATEY DILATEX] allows specifying different dilation factors for Y and X.
%
% Copyright (C) 2015, 2018 Andrea Vedaldi, James Thewlis and Samuel Albanie.
vl_nnnotfound(mfilename);
