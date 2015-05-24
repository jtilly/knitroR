# Example with one inequality constraint and lower bounds
#
# Taken from the Julia implementation of Knitro (knitrojl)
#
#    min  9 - 8x1 - 6x2 - 4x3
#         + 2(x1^2) + 2(x2^2) + (x3^2) + 2(x1*x2) + 2(x1*x3)
#    subject to  x1 + x2 + 2x3 <= 3
#                x1 >= 0
#                x2 >= 0
#                x3 >= 0
#    Initial value: (0.5, 0.5, 0.5)
#
#    Solution is x1=4/3, x2=7/9, x3=4/9, lambda=2/9  (f* = 1/9)
#
#  The problem comes from Hock and Schittkowski, HS35.

library(knitroR)

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

results1 = knitro(objFun=objFun, c_inequality = c_inequality, lb=lb, x0=x0, options="options.opt")

# define objective function gradient
objGrad = function(x) {
    grad = vector(mode="numeric", length=3)
    grad[1] = -8.0 + 4.0*x[1] + 2.0*x[2] + 2.0*x[3]
    grad[2] = -6.0 + 2.0*x[1] + 4.0*x[2]
    grad[3] = -4.0 + 2.0*x[1]            + 2.0*x[3]
    return(grad)
}

# define the jacobian
jac = function(x) {
    jac = matrix(0,nrow=1,ncol=3)
    jac[1] = 1.0
    jac[2] = 1.0
    jac[3] = 2.0
    return(jac)
}

results2 = knitro(objFun=objFun, c_inequality = c_inequality, 
                  objGrad=objGrad, jac=jac, lb=lb, x0=x0, options="options.opt")

