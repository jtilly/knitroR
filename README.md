knitroR
=======

This package provides an R integration of (http://www.ziena.com/knitro.htm)[Knitro] via Rcpp for Linux and Mac OS X. 
This is very much work in progress and most of it is probably not going to work. 

Knitro offers a very straightforward integration for C++ (and many other langugages). Check out the example code (https://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html)[here]. knitroR uses this C++ integration as backend and provides a wrapper via (http://dirk.eddelbuettel.com/code/rcpp.html)[Rcpp] that can be called from R. This is how it works: 
* I define the objective function in R. 
* Using Rcpp, I then pass the R objective function on to the C++ code that calls knitro. 
* Whenever knitro needs to evaluate the objective function, it [calls the R function](http://gallery.rcpp.org/articles/r-function-from-c++/). 


