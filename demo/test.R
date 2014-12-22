# test
require(knitroR)

# objective function
objFun <- function(x) { 
    return(1000 - x[1]*x[1] - 2*x[2]*x[2] - x[3]*x[3] - x[1]*x[2] - x[1]*x[3])
}

gradObj <- function(x) {
    return(c(-x[1], x[2], x[3]*3-x[2]))
}

jac <- function(x) {
    return(rbind(c(-x[1], x[2], x[3]*3-x[2]), c(-x[1], x[2], x[3]*3-x[2])));
}

ceq <- function(x) {
    return(c(x[3]-x[2], x[1]-3))
}

x0 = c(0,0,0)
x1 = knitro(objFun=objFun, objGrad=gradObj, jac=jac, ceq = ceq, x0=x0, optionsFile="options.opt")