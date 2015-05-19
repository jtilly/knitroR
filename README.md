knitroR: R Package for Knitro
=======

This package allows you to call the [Knitro](http://www.ziena.com/knitro.htm) optimizer from R. This is very much work in progress. 

At this point, this package only brings some of the functionality from Knitro to R. I have managed to get this package to work under Linux, Mac OS, and Windows 7. I have had some complaints from Windows users, so this package may or may not work for you. The package works with Knitro 8.1.1 and more recent versions. Installation instructions are below. 

Knitro offers a very straightforward integration for C++ (and many other languages). Check out the example code [here](https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html). `knitroR` uses this C++ integration as backend and provides a wrapper using [Rcpp](http://dirk.eddelbuettel.com/code/rcpp.html) that can be called from R. 

##Installation

IMPORTANT: Make sure you're installing `knitroR` on the proper architecture. If you have the 32bit version of Knitro, you should use a 32bit version of `R` and only try to build a 32bit package (i.e. turn off multiarch support using the option `--no-multiarch`). Similarly, if you have the 64bit version of Knitro, you should use a 64bit version of `R` and only try to build a 64bit package. 

### Linux and Mac OS X
To install the package under Linux or Mac OS X you need to create the environmental variable `KNITRO`:
```{bash}
export KNITRO=/path/to/your/knitro/installation
```
Also, you need to make sure that $KNITRO/lib is in your library path, i.e. under Linux, you need to set
```{bash}
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$KNITRO/lib
```
and under Mac OS, you need to set
```{bash}
export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$KNITRO/lib
```
For any of this to work, I need to open R (or RStudio) through the command line. Then, install the package using the `devtools` package:

```{r}
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```

### Windows

I'm assuming that Knitro was installed successfully and that all environmental variables were set appropriately. In particular, `KNITRODIR` must point to the Knitro installation.

To install this package under Windows you need to download and install [Rtools](http://cran.r-project.org/bin/windows/Rtools/). 

If you're using Knitro 9.1, then you can download and install `knitroR` using the devtools:
```{r}
install.packages("devtools")
library("devtools")
install_github("jtilly/knitroR")
```

If you're using an older version than Knitro 9.1, you need to
- Download `knitroR` by hand, either by cloning this repository or by downloading it from [here](https://github.com/jtilly/knitroR/archive/master.zip). 
- Then go to `src\Makevars.win` in this package's source code and change the variable `KNRELEASE` to the appropriate version. `KNRELEASE` needs to be set so that it matches the name of the file `knitro$(KNRELEASE).lib` in your Knitro `lib` directory. 
- Then open `R` and install this package by hand: 
```{r}
install.packages("C:\Downloads\knitroR-master", repos = NULL, type="source", INSTALL_opts="--no-multiarch")
```
where you need to change the path to `knitroR` appropriately. 

##Usage

You can check if the package works by running
```{r}
library(knitroR)
demo(example1)
demo(example2)
```

The files [demo/example1.R](https://github.com/jtilly/knitroR/blob/master/demo/example1.R) and [demo/example2.R](https://github.com/jtilly/knitroR/blob/master/demo/example2.R) illustrate how `knitroR` can be used.

Note that all options are defined in the text file `options.opt`. If this file doesn't exist, it will be created. 

The reference manual is [here](https://jtilly.github.io/knitroR/knitroR.pdf "Documentation for knitroR")

##Acknowledgment
Romain Francois has a [Knitro package](https://github.com/romainfrancois/KNITRO/) that helped me to better understand how to get Knitro to work in `R`. His package allows you to register an R function as Knitro's callback.
