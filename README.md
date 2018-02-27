## mcnIm2row

Exposes the MatConvNet C++ `im2row` function as a MATLAB function called `vl_nnim2row`.

### Installation

The easiest way to use this module is to install it with the `vl_contrib`
package manager. `mcnIm2row` can be installed with the following commands
from the root directory of your MatConvNet installation:

```
vl_contrib('install', 'mcnIm2row') ;
vl_contrib('compile', 'mcnColors') ;
vl_contrib('setup', 'mcnIm2row') ;
```


### Demo

To understand the `im2row` function, see Section 6.1 of the [MatConvNet manual](https://arxiv.org/pdf/1412.4564.pdf).  You can get some idea of the operation by examining the effect of `im2row` on example image (shown below for a kernel size of `[20, 20]`).  This figure can be produced by running `im2rowDemo.m`.

![fig](misc/fig.png)

The mex interface code was written by James Thewlis.
