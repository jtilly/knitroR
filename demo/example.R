library(knitroR)
# objective function
objFun = function(x) { 
    return( (x-2)^2 ) 
}
objGrad = function(x) {
    return(2*(x-2))
}
knitro(objFun=objFun, objGrad=objGrad, x0=-3, ub=1e20, lb=-1e20)

