# Example with two inequality constraints and one upper bound
#
#  min   100 (x2 - x1^2)^2 + (1 - x1)^2
#  s.t.  x1 x2 >= 1
#        x1 + x2^2 >= 0
#        x1 <= 0.5
#
#  The standard start point (-2, 1) usually converges to the standard
#  minimum at (0.5, 2.0), with final objective = 306.5.
#  Sometimes the solver converges to another local minimum
#  at (-0.79212, -1.26243), with final objective = 360.4.
#
#  The problem comes from Hock and Schittkowski, HS15

library(knitroR)

# define the objective function
objFun = function(x) { 
    100*(x[2] - x[1]^2)^2 + (1-x[1])^2
}

# define the inequality constraint
c_inequality = function(x) {
    return(  c( 1- x[1] * x[2], -x[1] - x[2]^2)  )
}

ub = c(0.5, 1e20);

# define starting values
x0 = c(-2, 1)

results1 = knitro(objFun=objFun, c_inequality = c_inequality, ub=ub, x0=x0, options="options.opt")

# define objective function gradient
objGrad = function(x) {
    grad = vector(mode="numeric", length=2)
    grad[1] = (-400.0 * (x[2] - x[1]^2) * x[1]) - (2.0 * (1.0 - x[1]))
    grad[2] = 200.0 * (x[2] - x[1]^2)
    return(grad)
}

# define the jacobian
jac = function(x) {
    jac = matrix(0,nrow=2,ncol=2)
    jac[1,1] = -x[2]
    jac[1,2] = -x[1]
    jac[2,1] = -1.0
    jac[2,2] = -2.0 * x[2]
    return(jac)
}

results2 = knitro(objFun=objFun, c_inequality = c_inequality, 
                  objGrad=objGrad, jac=jac, ub=ub, x0=x0, options="options.opt")

