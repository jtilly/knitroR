# test
require(knitroR)

# objective function
objFun <- function(x) { 
    return(1000 - x[1]*x[1] - 2*x[2]*x[2] - x[3]*x[3] - x[1]*x[2] - x[1]*x[3])
}

gradObj <- function(x) {
    return(c(2*x[1]-x[2]-x[3], 
             4*x[2]-x[1], 
             -2*x[3]-x[1]))
}

ceq <- function(x) {
    return(c(x[1]^2*x[2]-5))
}

jac <- function(x) {
    return(c(2*x[1]*x[2], x[1]^2));
}




x0 = c(0,0,0)
x1 = knitro(objFun=objFun, objGrad=gradObj, jac=jac, ceq = ceq, x0=x0, optionsFile="options.opt")