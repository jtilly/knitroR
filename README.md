knitroR: R Package for Knitro
=======
[![Build Status](https://travis-ci.org/jtilly/knitroR.svg?branch=master)](https://travis-ci.org/jtilly/knitroR)

This package provides an `R` interface for the non-linear constraint optimizer [KNITRO](http://www.ziena.com/knitro.htm) optimizer from `R`. This is very much work in progress. At this point, this package only brings some of the functionality from KNITRO to `R`. I have managed to get this package to work under Linux, Mac OS, and Windows 7. The package works with KNITRO 8 and more recent versions. Installation instructions are below. 

KNITRO offers a very straightforward integration for C++. Examples are available [here](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html). `knitroR` uses this C++ integration as backend and provides a wrapper using [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) that can be called from R. 

##Installation

Make sure you're installing `knitroR` on the proper architecture. If you have the 32bit version of KNITRO, you should use a 32bit version of `R` and only try to build a 32bit package (i.e. turn off multiarch support using the option `--no-multiarch`). Similarly, if you have the 64bit version of KNITRO, you should use a 64bit version of `R` and only try to build a 64bit package. 

### Linux and Mac OS X
To install the package under Linux or Mac OS X you need to create the environmental variable `KNITRO`:
```{bash}
export KNITRO=/path/to/your/knitro/installation
```

Also, you need to make sure that `$KNITRO/lib` is in your library path, i.e. under Linux, you need to set

```{bash}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KNITRO/lib
```
and under Mac OS, you need to set
```{bash}
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KNITRO/lib
```
For any of this to work, I need to open `R` (or `RStudio`) through the command line. Then, install the package using the `devtools` package:

```{r}
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```

### Windows

I'm assuming that KNITRO was installed successfully and that all environmental variables were set appropriately. In particular, `KNITRODIR` must point to the directory with the KNITRO installation.

To install this package under Windows you need to download and install [Rtools](http://cran.r-project.org/bin/windows/Rtools/). 

If you're using KNITRO 9.1, then you can download and install `knitroR` using the devtools:
```{r}
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```

If you're using an older version than KNITRO 9.1, you need to
- Download `knitroR` by hand, either by cloning this repository or by downloading it from [here](https://github.com/jtilly/knitroR/archive/master.zip). 
- Then go to `src\Makevars.win` in this package's source code and change the variable `KNRELEASE` to the appropriate version. `KNRELEASE` needs to be set so that it matches the name of the file `knitro$(KNRELEASE).lib` in your KNITRO `lib` directory. 
- Then open `R` and install this package by hand: 
```{r}
install.packages("C:\Downloads\knitroR-master", repos = NULL, type="source", INSTALL_opts="--no-multiarch")
```
where you need to change the path to `knitroR` appropriately. 

##Usage

Example with inequality constraint and lower bounds: 

```{r}
# load library
library("knitroR")

# define the objective function
objFun = function(x) { 
    9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]+2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2 + 2.0*x[1]*x[2] + 2.0*x[1]*x[3]
}

# define the inequality constraint
c_inequality = function(x) {
    return(  x[1] + x[2] + 2.0*x[3] - 3.0  )
}

lb = c(0, 0, 0)

# define starting values
x0 = c(0.5, 0.5, 0.5)

results = knitro(objFun=objFun, c_inequality = c_inequality, lb=lb, x0=x0, options="options.opt")
```

Note that all options are defined in the text file `options.opt`. If this file doesn't exist, it will be created. 

The files [demo/example1.R](https://github.com/jtilly/knitroR/blob/master/demo/example1.R) and [demo/example2.R](https://github.com/jtilly/knitroR/blob/master/demo/example2.R) contain more examples.


## Documentation
The reference manual is [here](https://jtilly.github.io/knitroR/knitroR.pdf "Documentation for knitroR").

##Acknowledgment
Romain Francois has a [KNITRO package](https://github.com/romainfrancois/KNITRO/) that helped me to better understand how to get KNITRO to work in `R`. His package provides a deeper integration of KNITRO that allows you to register an `R` function as KNITRO's callback.
