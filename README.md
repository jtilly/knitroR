knitroR
=======

This package allows you to call the [Knitro](http://www.ziena.com/knitro.htm) optimizer from R. This is very much work in progress. My goal for this package is to create an R integration of Knitro that is as simple to use as R's `optim()`.

So far I have managed to get this package to work under Linux, Mac OS, and Windows. Installation instructions are below. 

Knitro offers a very straightforward integration for C++ (and many other languages). Check out the example code [here](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html). `knitroR` uses this C++ integration as backend and provides a wrapper using [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) that can be called from R. This is how it works: 

1.  I define the objective function and (if applicable) constraints and gradients in R. 

2.  Using `Rcpp`, I then pass the R objective function on to the `C++` code via the function `knitroCpp()`. The content of the function `knitroCpp` is almost identical to the function `main()` in the example code       [here](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html), with the one addition that a pointer to the list ```fcts``` is passed on to Knitro's callback function via the parameter `UserParams`. [see the Knitro documentation](https://www.artelys.com/tools/knitro_doc/2_userGuide/callbacks.html?highlight=userparams) for how this works.

3.  Whenever Knitro needs to evaluate the objective function (or the constraints, gradients, jacobian, etc...), it calls the original objective function that was defined in R using code similar to this [example](http://gallery.rcpp.org/articles/r-function-from-c++/). 


##Installation

### Linux and Mac OS X
To install the package under Linux or Mac OS X you need to create the environmental variable `KNITRO`:

```
export KNITRO=/path/to/your/knitro/installation
```
Also, you need to make sure that $KNITRO/lib is in your library path, i.e. under Linux, you need to set
```
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KNITRO/lib
```
and under Mac OS, you need to set
```
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KNITRO/lib
```
For any of this to work, I need to open R (or RStudio) through the command line. Then, install the package using the `devtools` package:

```
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```
### Windows

I'm assuming that Knitro was installed successfully and that all environmental variables were set appropriately. In particular, `KNITRODIR` must point to the Knitro installation.

To install this package under Windows you need to download and install [Rtools](http://cran.r-project.org/bin/windows/Rtools/). 

If you're using Knitro 9.1, then you can download and install `knitroR` using the devtools:
```
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```

If you're using an older version than Knitro 9.1, you need to
- Download `knitroR` by hand, either by cloning this repository or by downloading it from [here](https://github.com/jtilly/knitroR/archive/master.zip). 
- Then go to `src\Makevars.win` in this package's source code and change the variable `KNRELEASE` to the appropriate version
- Then open `R' and install this package by hand: 
```
install.packages("C:\Downloads\knitroR-master", repos = NULL, type="source")
```
where you need to change the path to `knitroR` appropriately. 

##Usage

You can check if the package works by running
```
library(knitroR)
demo(example1)
demo(example2)
```

The files [demo/example1.R](https://github.com/jtilly/knitroR/blob/master/demo/example1.R) and [demo/example2.R](https://github.com/jtilly/knitroR/blob/master/demo/example2.R) illustrate how `knitroR` can be used.

Note that all options are defined in the text file `options.opt`. If this file doesn't exist, it will be created.

There is some rudimentary documentation [here](https://jtilly.github.io/knitroR/knitroR.pdf)

##Acknowledgment
Romain Francois has a [Knitro package](https://github.com/romainfrancois/KNITRO/) that helped me a lot to better understand how to get Knitro to work in R. His package allows you to register an R function as Knitro's callback. His package is probably superior to mine along every imaginable dimension. So go check it out!
