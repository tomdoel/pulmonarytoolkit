# npReg
Matlab image registration software

Author: Nathan D. Cahill

Rochester Institute of Technology

January 2014

GNU GPL v3 licence.

## Overview

NPREG solves nonparametric image registration problems.

   BNEW=NPREG(A,B) estimates a deformation field that is applied to
   the floating image B in order to bring it into alignment with reference
   image A.  The default registration algorithm is fluid registration,
   wherein the deformation field is found by minimizing the sum of
   squared difference (SSD) similarity measure, subject to a regularizer
   based on the linearized elastic potential of the velocity field (known)
   as the fluid regularizer).

   BNEW=NPREG(A,B,OPTIONS) estimates the deformation field with the
   default parameters replaced by values in the structure OPTIONS, an
   argument created with the NPREGSET function.  See NPREGSET for
   details.  Used options are Display, SimilarityMeasure, Regularizer, 
   BoundaryCond, MaxIter, UDiffTol, VDiffTol, BodyForceTol, SimMeasTol, 
   BodyForceDiffTol, SimMeasDiffTol, SimMeasPercentDiffTol, 
   FixedPointMaxFlowDistance, RegridTol, and StabilityConstant.

   [BNEW,U]=NPREG(A,B,...) returns the estimated deformation field U
   that is applied to the floating image B in order to produce deformed
   image BNEW.

   [BNEW,U,EXITFLAG]=NPREG(A,B,...) returns an EXITFLAG that
   describes the exit condition of NPREG. Possible values of 
   EXITFLAG and the corresponding exit conditions are 

     1  NPREG converged to a solution BNEW.
     0  Maximum number of iterations reached.
    -1  Error.

   [BNEW,U,EXITFLAG,OUTPUT]=NPREG(A,B,...) returns a structure 
   OUTPUT with the number of fixed point iterations taken in
   OUTPUT.fixedPointIterations, and the exit message in OUTPUT.message.
