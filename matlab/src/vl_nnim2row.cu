// @file vl_nnim2row.cu
// @brief im2row block MEX wrapper
// @author Andrea Vedaldi
// @author Karel Lenc

/*
Copyright (C) 2014-15 Andrea Vedaldi and Karel Lenc.
All rights reserved.

This file is part of the VLFeat library and is made available under
the terms of the BSD license (see the COPYING file).
*/

#include <bits/mexutils.h>
#include <bits/datamex.hpp>
#include <bits/impl/im2row.hpp>

#if ENABLE_GPU
#include <bits/datacu.hpp>
#endif

#include <assert.h>

/* option codes */
enum {
  opt_stride = 0,
  opt_dilate,
  opt_pad,
} ;

/* options */
VLMXOption  options [] = {
  {"Stride",           1,   opt_stride            },
  {"Pad",              1,   opt_pad               },
  {"Dilate",           1,   opt_dilate            },
  {0,                  0,   0                     }
} ;

/* ---------------------------------------------------------------- */
/*                                                          Context */
/* ---------------------------------------------------------------- */

vl::MexContext context ;

/*
 Resetting the context here resolves a crash when MATLAB quits and
 the ~Context function is implicitly called on unloading the MEX file.
 */
void atExit()
{
  context.clear() ;
}

/* ---------------------------------------------------------------- */
/*                                                       MEX driver */
/* ---------------------------------------------------------------- */

enum {
  IN_DATA = 0, IN_SIZE, IN_DEROUTPUT, IN_END
} ;

enum {
  OUT_RESULT = 0, OUT_END
} ;

void mexFunction(int nout, mxArray *out[],
                 int nin, mxArray const *in[])
{
  int windowWidth ;
  int windowHeight ;
  int strideX = 1 ;
  int strideY = 1 ;
  int padLeft = 0 ;
  int padRight = 0 ;
  int padTop = 0 ;
  int padBottom = 0 ;
  int dilateY = 1 ;
  int dilateX = 1 ;
  bool backMode = false ;

  int verbosity = 0 ;
  int opt ;
  int next = IN_END ;
  mxArray const *optarg ;

  /* -------------------------------------------------------------- */
  /*                                            Check the arguments */
  /* -------------------------------------------------------------- */

  mexAtExit(atExit) ;

  if (nin < 2) {
    mexErrMsgTxt("The arguments are less than two.") ;
  }

  if (nin > 2 && vlmxIsString(in[2],-1)) {
    next = 2 ;
    backMode = 0 ;
  } else {
    backMode = (nin >= 3) ;
  }

  while ((opt = vlmxNextOption (in, nin, options, &next, &optarg)) >= 0) {
    switch (opt) {
       case opt_dilate :
        if (!vlmxIsPlainMatrix(optarg,-1,-1)) {
          vlmxError(VLMXE_IllegalArgument, "DILATE is not a plain matrix.") ;
        }
        switch (mxGetNumberOfElements(optarg)) {
          case 1:
            dilateY = (int)mxGetPr(optarg)[0] ;
            dilateX = dilateY ;
            break ;
          case 2:
            dilateY = (int)mxGetPr(optarg)[0] ;
            dilateX = (int)mxGetPr(optarg)[1] ;
            break ;
          default:
            vlmxError(VLMXE_IllegalArgument, "DILATE has neither one nor two elements.") ;
        }
        break ;


      case opt_stride :
        if (!vlmxIsPlainMatrix(optarg,-1,-1)) {
          mexErrMsgTxt("STRIDE is not a plain matrix.") ;
        }
        switch (mxGetNumberOfElements(optarg)) {
          case 1:
            strideY = (int)mxGetPr(optarg)[0] ;
            strideX = strideY ;
            break ;
          case 2:
            strideY = (int)mxGetPr(optarg)[0] ;
            strideX = (int)mxGetPr(optarg)[1] ;
            break ;
          default:
            mexErrMsgTxt("STRIDE has neither one nor two elements.") ;
        }
        break ;

      case opt_pad :
        if (!vlmxIsPlainMatrix(optarg,-1,-1)) {
          mexErrMsgTxt("PAD is not a plain matrix.") ;
        }
        switch (mxGetNumberOfElements(optarg)) {
          case 1:
            padLeft = (int)mxGetPr(optarg)[0] ;
            padRight = padLeft ;
            padTop = padLeft ;
            padBottom = padLeft ;
            break ;
          case 4:
            padTop = (int)mxGetPr(optarg)[0] ;
            padBottom = (int)mxGetPr(optarg)[1] ;
            padLeft = (int)mxGetPr(optarg)[2] ;
            padRight = (int)mxGetPr(optarg)[3] ;
            break ;
          default:
            mexErrMsgTxt("PAD has neither one nor four elements.") ;
        }
        break;

      default:
        break ;
    }
  }

  vl::MexTensor data(context) ;
  vl::MexTensor derOutput(context) ;

  data.init(in[IN_DATA]) ;
  data.reshape(4) ; // -> 4 dimensions

  if (backMode) {
    derOutput.init(in[IN_DEROUTPUT]) ;
    derOutput.reshape(4) ; // -> 4 dimensions
  }

  if (backMode && ! vl::areCompatible(data, derOutput)) {
    mexErrMsgTxt("DATA and DEROUTPUT do not have compatible formats.") ;
  }

  if (!vlmxIsPlainMatrix(in[IN_SIZE],-1,-1)) {
    mexErrMsgTxt("SIZE is not a plain matrix.") ;
  }
  switch (mxGetNumberOfElements(in[IN_SIZE])) {
    case 1:
      windowHeight = mxGetPr(in[IN_SIZE])[0] ;
      windowWidth = windowHeight ;
      break ;
    case 2:
      windowHeight = mxGetPr(in[IN_SIZE])[0] ;
      windowWidth = mxGetPr(in[IN_SIZE])[1] ;
      break ;
    default:
      mexErrMsgTxt("SIZE has neither one nor two elements.") ;
  }

  /* Basic compatibility of Shape */
  if (data.getSize() != 1) {
  	mexErrMsgTxt("Currently only one input image supported.") ;
  }
  if (strideX < 1 || strideY < 1) {
    mexErrMsgTxt("At least one element of STRIDE is smaller than one.") ;
  }
  if (windowHeight == 0 || windowWidth == 0) {
    mexErrMsgTxt("A dimension of the window SIZE is void.") ;
  }
  if (data.getHeight() + (padTop+padBottom) < windowHeight ||
      data.getWidth() + (padLeft+padRight) < windowWidth) {
    mexErrMsgTxt("The window is larger than the DATA (including padding).") ;
  }
  if (padLeft < 0 ||
      padRight < 0 ||
      padTop < 0 ||
      padBottom < 0) {
    mexErrMsgTxt("An element of PAD is negative.") ;
  }
  if (padLeft >= windowWidth ||
      padRight >= windowWidth ||
      padTop >= windowHeight  ||
      padBottom >= windowHeight) {
    mexErrMsgTxt("A padding value is larger or equal to the size of the window.") ;
  }

  /* Get the output Shape */
  int numPatchesX = (data.getWidth() + (padLeft + padRight) - windowWidth)/strideX + 1 ;
  int numPatchesY = (data.getHeight() + (padTop + padBottom) - windowHeight)/strideY + 1 ;
  int numRows = windowWidth * windowHeight * data.getDepth() ;

  vl::TensorShape outputShape(numPatchesX * numPatchesY, numRows, 1, 1) ;

  if (backMode && (derOutput != outputShape)) {
    mexErrMsgTxt("DEROUTPUT dimensions are incompatible with X and SIZE.") ;
  }

  /* Create output buffers */
  const vl::DeviceType deviceType = data.getDeviceType() ;
  const vl::DataType dataType = data.getDataType() ;
  vl::MexTensor output(context) ;
  vl::MexTensor derData(context) ;

  if (!backMode) {
    output.initWithZeros(deviceType, dataType, outputShape) ;
  } else {
    derData.initWithZeros(deviceType, dataType, data.getShape()) ;
  }

  /* -------------------------------------------------------------- */
  /*                                                    Do the work */
  /* -------------------------------------------------------------- */

#define DISPATCH2(deviceType) \
switch (dataType) { \
case vl::VLDT_Float: DISPATCH(deviceType, float) ; break ; \
IF_DOUBLE(case vl::VLDT_Double : DISPATCH(deviceType, double) ; break ;) \
default: assert(false) ; return ; \
}
  vl::ErrorCode error ;
  if (!backMode) {
    #define DISPATCH(deviceType, type) \
    error = vl::impl::im2row<deviceType,type>::forward \
    (context, \
     (type*)output.getMemory(), \
     (type*)data.getMemory(), \
     data.getHeight(), data.getWidth(), data.getDepth(), \
     windowHeight, windowWidth, \
     strideY, strideX, \
     padTop, padBottom, padLeft, padRight, dilateY, dilateX) ;
    switch (deviceType) {
    default:
      assert(false) ;
      error = vl::VLE_Unknown ;
      break ;
    case vl::VLDT_CPU:
      // error = vl::impl::im2row<vl::VLDT_CPU,float>::forward \
      //         (context, \
      //          (float*)output.getMemory(), \
      //          (float*)data.getMemory(), \
      //          data.getHeight(), data.getWidth(), data.getDepth(), \
      //          windowHeight, windowWidth, \
      //          strideY, strideX, \
      //          padTop, padBottom, padLeft, padRight, dilateX, dilateY) ;
      DISPATCH2(vl::VLDT_CPU) ;
      break ;
#if ENABLE_GPU
    case vl::VLDT_GPU:
      // error = vl::impl::im2row<vl::VLDT_GPU,float>::forward \
      //         (context, \
      //          (float*)output.getMemory(), \
      //          (float*)data.getMemory(), \
      //          data.getHeight(), data.getWidth(), data.getDepth(), \
      //          windowHeight, windowWidth, \
      //          strideY, strideX, \
      //          padTop, padBottom, padLeft, padRight) ;
      DISPATCH2(vl::VLDT_GPU) ;
      break ;
#endif
    }
  } else {
  	#undef DISPATCH
  	#define DISPATCH(deviceType, type) \
    error = vl::impl::im2row<deviceType,type>::backward \
    (context, \
     (type*)derData.getMemory(), \
     (type*)derOutput.getMemory(), \
     derData.getHeight(), derData.getWidth(), derData.getDepth(), \
     windowHeight, windowWidth, \
     strideY, strideX, \
     padTop, padBottom, padLeft, padRight, dilateY, dilateX) ;
    switch (deviceType) {
    default:
      assert(false) ;
      error = vl::VLE_Unknown ;
      break ;
    case vl::VLDT_CPU:
      // error = vl::impl::im2row<deviceType,type>::backward \
      //     (context, \
      //      (type*)derData.getMemory(), \
      //      (type*)derOutput.getMemory(), \
      //      derData.getHeight(), derData.getWidth(), derData.getDepth(), \
      //      windowHeight, windowWidth, \
      //      strideY, strideX, \
      //      padTop, padBottom, padLeft, padRight) ;
      DISPATCH2(vl::VLDT_CPU) ;
      break ;
#if ENABLE_GPU
    case vl::VLDT_GPU:
      // error = vl::impl::im2row<vl::VLDT_GPU,float>::backward \
      //     (context, \
      //      (type*)derData.getMemory(), \
      //      (type*)derOutput.getMemory(), \
      //      derData.getHeight(), derData.getWidth(), derData.getDepth(), \
      //      windowHeight, windowWidth, \
      //      strideY, strideX, \
      //      padTop, padBottom, padLeft, padRight) ;
      DISPATCH2(vl::VLDT_GPU) ;
      break ;
#endif
    }
  }

  /* -------------------------------------------------------------- */
  /*                                                         Finish */
  /* -------------------------------------------------------------- */

  if (error != vl::VLE_Success) {
    mexErrMsgTxt(context.getLastErrorMessage().c_str()) ;
  }
  if (backMode) {
    out[OUT_RESULT] = derData.relinquish() ;
  } else {
    out[OUT_RESULT] = output.relinquish() ;
  }
}
