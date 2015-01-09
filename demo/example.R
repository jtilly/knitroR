library(knitroR)
objFun = function(x) { 
    return( (x-3)^2 ) 
}
c_equality = function(x) {
    return(sin(x)+1)
}
c_inequality = function(x) {
    return(x-1)
}

knitro(objFun=objFun, c_equality = c_equality, c_inequality = c_inequality, x0=0, options="options.opt")

