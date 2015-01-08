knitroR
=======

This package allows you to call the [Knitro](http://www.ziena.com/knitro.htm) optimizer from R. This is very much work in progress. All of this only works on Linux and Mac OS. There is some rudimentary documentation [here](https://jtilly.github.io/knitroR/knitroR.pdf). Installation instructions are below.

Knitro offers a very straightforward integration for C++ (and many other languages). Check out the example code [here](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html). knitroR uses this C++ integration as backend and provides a wrapper via [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) that can be called from R. This is how it works: 

1.  I define the objective function and (if applicable) constraints and gradients in R. 

2.  Using Rcpp, I then pass the R objective function on to the C++ code via the function ```knitroCpp()```. The content of the function knitroCpp is almost identical to the function main() in the example code       [here](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html), with the one addition that a pointer to the list ```fcts``` is passed on to Knitro's callback function via the parameter ```UserParams``` [see the Knitro documentation](https://www.artelys.com/tools/knitro_doc/2_userGuide/callbacks.html?highlight=userparams) for how this works.

3.  Whenever Knitro needs to evaluate the objective function, it [calls the R function](http://gallery.rcpp.org/articles/r-function-from-c++/). 


##Installation

To install the package under Linux or Mac OS X you need to set a few environmental variables:

```
export KNITRO=/path/to/your/knitro/installation
```

```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KNITRO/lib
```

For any of this to work, I need to open R (or RStudio) through the command line. Then, install the package using the `devtools` package:

```
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```

##Usage

Define the objective function in R

```
objFun = function(x) { -x[1]^2+x[2]-x[2]*x[3] }
```

Other functions such as the gradient (```objGrad```), equality constraints (```ceq```), and the constraint Jacobian (```jac```) can be defined similarly. These additional functions are optional. Then, call the Knitro function to do the optimization

```
x1 = knitro(objFun=objFun, x0=x0, optionsFile="options.opt")
```

##Acknowledgment
Romain Francois has a [Knitro package](https://github.com/romainfrancois/KNITRO/) that helped me a lot to better understand how to get Knitro to work in R. His package allows you to register an R function as knitro's callback. His package is probably superior to mine along every imaginable dimension. So go check it out!

