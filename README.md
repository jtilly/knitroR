knitroR: R Package for KNITRO
=======
[![Build Status](https://travis-ci.org/jtilly/knitroR.svg?branch=master)](https://travis-ci.org/jtilly/knitroR)

`knitroR` provides an `R` interface for the commercial non-linear constraint optimizer [KNITRO](http://www.ziena.com/knitro.htm). This is very much work in progress. At this point, this package only brings *some* of the functionality from KNITRO to `R`. I have managed to get this package to work under Linux, Mac OS, and Windows 7. The package works with KNITRO 8 and more recent versions. Installation instructions are below. 

`knitroR` builds an `R` wrapper around [KNITRO's C++ interface](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html) using [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html).

## Example

Consider the following example. The goal is to minimize a smooth function in three parameters with an inequality constraint and non-negativity constraints on all three parameters.

```{r}
# load package
library("knitroR")

# define the objective function
objFun = function(x) { 
    9.0 - 8.0*x[1] - 6.0*x[2] - 4.0*x[3]+2.0*x[1]^2 + 2.0*x[2]^2 + x[3]^2 + 2.0*x[1]*x[2] + 2.0*x[1]*x[3]
}

# define the inequality constraint
c_inequality = function(x) {
    return(  x[1] + x[2] + 2.0*x[3] - 3.0  )
}

# specify non-negativity constraints
lb = c(0, 0, 0)

# define starting values
x0 = c(0.5, 0.5, 0.5)

# minimize the objective function using KNITRO
results = knitro(objFun=objFun, c_inequality = c_inequality, lb=lb, x0=x0, options="options.opt")
```
The code returns a list `results` that includes (among other things) KNITRO's exit status, the final parameters values, and the value of the objective function at the minimum.
```
> results$status
[1] 0
> results$x
[1] 1.3333333 0.7777778 0.4444444
> results$fval
[1] 0.1111111
```
For more examples see [here](https://github.com/jtilly/knitroR/tree/master/demo). These examples illustrate how to pass user-defined gradients and Jacobians to KNITRO.

## Documentation
* The official documentation for KNITRO is available [here](http://www.artelys.com/tools/knitro_doc/).
* The reference manual for `knitroR` is available [here](https://jtilly.github.io/knitroR/knitroR.pdf "Documentation for knitroR: R Package for KNITRO"). 

##Installation

Make sure you're installing `knitroR` on the proper architecture. If you have the 32bit version of KNITRO, you should use a 32bit version of `R` and only try to build a 32bit package (i.e. turn off multiarch support using the option `--no-multiarch`). Similarly, if you have the 64bit version of KNITRO, you should use a 64bit version of `R` and only try to build a 64bit package. 

#### Linux 
To install the package under Linux you first need to set the environmental variables `KNITRO`, `ZIENA_LICENSE`, and `LD_LIBRARY_PATH`. This can be done directly in `R` (or `RStudio`). In the following, please adjust the paths and file names where appropriate:
```{r}
Sys.setenv(KNITRO = "/path/to/knitro")
Sys.setenv(ZIENA_LICENSE = "/path/to/knitro/ziena_license.txt")
Sys.setenv(LD_LIBRARY_PATH = sprintf("%s:%s/lib", Sys.getenv("LD_LIBRARY_PATH"), Sys.getenv("KNITRO")))
install.packages("devtools")
devtools::install_github("jtilly/knitroR")
```
Alternatively, you can define these environmental variables using the command line:
```{bash}
export KNITRO=/path/to/knitro
export ZIENA_LICENSE=/path/to/knitro/ziena_license.txt
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/path/to/knitro/lib
```

#### Mac OS X
Same as under Linux with the only exception that `LD_LIBRARY_PATH` is called `DYLD_LIBRARY_PATH`: This can be done directly in `R` (or `RStudio`). In the following, please adjust the paths and file names where appropriate:
```{r}
Sys.setenv(KNITRO = "/path/to/knitro")
Sys.setenv(ZIENA_LICENSE = "/path/to/knitro/ziena_license.txt")
Sys.setenv(DYLD_LIBRARY_PATH = sprintf("%s:%s/lib", Sys.getenv("DYLD_LIBRARY_PATH"), Sys.getenv("KNITRO")))
install.packages("devtools")
devtools::install_github("jtilly/knitroR")
```
Alternatively, you can define these environmental variables using the command line:
```{bash}
export KNITRO=/path/to/knitro
export ZIENA_LICENSE=/path/to/knitro/ziena_license.txt
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:/path/to/knitro/lib
```

#### Windows

I'm assuming that KNITRO was installed successfully and that all environmental variables were set appropriately. In particular, `KNITRODIR` must point to the directory with the KNITRO installation.

To install this package under Windows you need to download and install [Rtools](http://cran.r-project.org/bin/windows/Rtools/). 

If you're using KNITRO 9.1, then you can download and install `knitroR` right away:
```{r}
install.packages("devtools")
devtools::install_github("jtilly/knitroR")
```

If you're using an older version than KNITRO 9.1, you need to
- Download `knitroR` by hand, either by cloning this repository or by downloading it from [here](https://github.com/jtilly/knitroR/archive/master.zip). 
- Then go to `src\Makevars.win` in this package's source code and change the variable `KNRELEASE` to the appropriate version. `KNRELEASE` needs to be set so that it matches the name of the file `knitro$(KNRELEASE).lib` in your KNITRO `lib` directory. 
- Then open `R` and install this package by hand: 
```{r}
install.packages("C:\Downloads\knitroR-master", repos = NULL, type="source", INSTALL_opts="--no-multiarch")
```
where you need to change the path to `knitroR` appropriately. 

##Acknowledgment
Romain Francois has a [KNITRO package](https://github.com/romainfrancois/KNITRO/) that helped me to better understand how to get KNITRO to work in `R`. His package provides a deeper integration of KNITRO that allows you to register an `R` function as KNITRO's callback.
