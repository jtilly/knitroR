knitroR
=======

This package allows you to call the [Knitro](http://www.ziena.com/knitro.htm) optimizer from R. This is very much work in progress.

Knitro offers a very straightforward integration for C++ (and many other languages). Check out the example code (https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html)[here]. knitroR uses this C++ integration as backend and provides a wrapper via (http://dirk.eddelbuettel.com/code/rcpp.html)[Rcpp] that can be called from R. This is how it works: 
1. I define the objective function in R. 
2. Using Rcpp, I then pass the R objective function on to the C++ code

```
knitroCpp(fcts, x0, m, nnzJ, jacIndexCons, jacIndexVars, options, optionsFile)
```

The R-list ```fcts``` contains all the user-defined R functions
1.  ```objFun```
2.  ```objGrad``` (optional)
3.  ```ceq``` (optional)
4.  ```jac``` (optional)

The function knitroCpp is very similar to the example code (https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html)[here], with the one addition that a pointer to the functions list is passed on to Knitro's callback function via the parameter ```UserParams``` [see the Knitro documentation](https://www.artelys.com/tools/knitro_doc/2_userGuide/callbacks.html?highlight=userparams).

3. Whenever knitro needs to evaluate the objective function, it [calls the R function](http://gallery.rcpp.org/articles/r-function-from-c++/). 


Installation
==============
To install the package under Linux or Mac OS X you need to set a few environmental variables:

```
export KNITRO=/path/to/your/knitro/installation
```

```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KNITRO/lib
```


Usage
==============

Define the objective function in R

```
objFun = function(x) { -x[1]^2+x[2]-x[2]*x[3] }
```

Other functions such as the gradient (```objGrad```), equality constraints (```ceq```), and the constraint Jacobian (```jac```) can be defined similarly. Then, call the Knitro function to do the optimization

```
x1 = knitro(objFun=objFun, x0=x0, optionsFile="options.opt")
```

