# Clean up
rm(list=ls())

# Include required packages
require("actyR")
require("knitroR")

# Make the Gauss-Legendre integration nodes and weights
GaussLegendre = legendre.quadrature.rules( 32 )[32][[1]];

# Set Settings
Settings = list(tolInner = 1e-10,
                maxIter = 1000,
                nCheck = 5,
                cCheck = 25,
                lowBndC = 0.5,
                uppBndC = 5,
                logGrid = NA,
                d = NA,
                integrationNodes=(GaussLegendre$x+1)/2,
                integrationWeights=GaussLegendre$w/2)

# Make a grid of the population data
Settings$logGrid = matrix(seq(log(Settings$lowBndC),log(Settings$uppBndC), length=Settings$cCheck), nrow=1, ncol=Settings$cCheck)
Settings$d = Settings$logGrid[2] - Settings$logGrid[1]

# We now define the true values for which we have a simulated dataset
Param = list(rho = 1/1.05,
             k = c(1.8, 1.4, 1.2, 1, 0.9),
             phi = rep(10,5),
             omega = 1.0,
             mu = 0,
             sigma = 1,
             Pi = NA)

specificationMatrix = matrix(0 , nrow=10+3, ncol=9)
specificationMatrix[1:5,1:5] = diag(rep(1,5))
specificationMatrix[6:10,6] = rep(1,5)
specificationMatrix[11,7] = 1
specificationMatrix[12,8] = 1
specificationMatrix[13,9] = 1
if("specificationMatrix" %in% names(Param)) {
    Param$specificationMatrix = specificationMatrix
} else {
    Param = c(Param, list(specificationMatrix=specificationMatrix))
}

# Compute the transition probability matrix at the truth
Param$Pi = tauchen( Settings$logGrid, Param$mu, Param$sigma )

# Compute the value function and check how long it takes
tic()
ret  = valuefunction(Settings, Param)
toc()

set.seed(1)

# Simulate data set
Data = simulateData(Settings, Param, rCheck = 1000, tCheck = 10)

# Skip the first step

## Second step estimation
# likelihood step 2
mpec.likelihood.Step2 = function(x, Pi=NULL) {
    
    if(!is.null(Pi)) {
        Param$Pi = Pi
    }
    
    Param$k = x[1:5];
    Param$phi = matrix(x[6], ncol=5, nrow=1);
    Param$omega = x[7];
    vS = matrix(0, nrow=Settings$nCheck+1, ncol=Settings$cCheck);
    vS[-(Settings$nCheck+1),] = t(matrix(x[seq(from=8,to=7+Settings$nCheck*Settings$cCheck)], ncol=Settings$nCheck, nrow=Settings$cCheck))
    ll = mpecLikelihood( Settings, Param, Data, vS)
    
    return(-sum(log(ll)))
}


mpec.likelihoodGradient.Step2 = function(x, Pi=NULL) {
    
    if(!is.null(Pi)) {
        Param$Pi = Pi
    }
    
    Param$k = x[1:5];
    Param$phi = matrix(x[6], ncol=5, nrow=1);
    Param$omega = x[7];
    vS = matrix(0, nrow=Settings$nCheck+1, ncol=Settings$cCheck);
    vS[-(Settings$nCheck+1),] = t(matrix(x[seq(from=8,to=7+Settings$nCheck*Settings$cCheck)], ncol=Settings$nCheck, nrow=Settings$cCheck))
    gr = mpecLikelihoodGradient( Settings, Param, Data, vS)
    
    return( c( gr[seq(from=1,to=5)], 
               sum(gr[seq(from=6,to=10)]),
               gr[11],
               gr[12:NCOL(gr)]));
}

mpec.constraint.Step2 = function(x, Pi=NULL) {
    if(!is.null(Pi)) {
        Param$Pi = Pi
    }
    
    Param$k = x[1:5];
    Param$phi = matrix(x[6], ncol=5, nrow=1);
    Param$omega = x[7];
    vS = matrix(0, nrow=Settings$nCheck+1, ncol=Settings$cCheck);
    vS[-(Settings$nCheck+1),] = t(matrix(x[seq(from=8,to=7+Settings$nCheck*Settings$cCheck)], ncol=Settings$nCheck, nrow=Settings$cCheck))
    equalityConstraint = mpecConstraint( Settings, Param, vS)
    
    return(equalityConstraint)
}


mpec.constraintGradient.Step2 = function(x, idx=FALSE, Pi=NULL) {
    if(!is.null(Pi)) {
        Param$Pi = Pi
    }
    
    Param$k = x[1:5];
    Param$phi = matrix(x[6], ncol=5, nrow=1);
    Param$omega = x[7];
    vS = matrix(0, nrow=Settings$nCheck+1, ncol=Settings$cCheck);
    vS[-(Settings$nCheck+1),] = t(matrix(x[seq(from=8,to=7+Settings$nCheck*Settings$cCheck)], ncol=Settings$nCheck, nrow=Settings$cCheck))
    constraintGradientMatrix = mpecConstraintGradient( Settings, Param, Data, vS, CONSOLIDATE_PHIS=TRUE)
    
    if(idx==TRUE) {
        return(constraintGradientMatrix);
    }
    else {
        constraintGradientMatrix = constraintGradientMatrix[,3]
        return(constraintGradientMatrix);
    }
}

# this function randomly draws the structural parameters and then computes
# values for the auxiliary parameters such that the equilibrium constraint 
# is satisfied; this is trying to find the best possible starting values for 
# mpec
generateMPECStartValues = function(x0=NULL) {
    if(is.null(x0)) {
        structural.startvalues = matrix(runif(1, 0, 5), nrow=1, ncol=7)
    } else {
        structural.startvalues = matrix(x0, nrow=1, ncol=7)    
    }
    ParamStartValues = Param
    ParamStartValues$k = structural.startvalues[1:5]
    ParamStartValues$phi = rep(structural.startvalues[6],5)
    ParamStartValues$omega = structural.startvalues[7]
    ret  = valuefunction(Settings, ParamStartValues)
    x = c(structural.startvalues, as.vector(t(ret$vS[-6,])))
}

truth = c(Param$k, Param$phi[1], Param$omega, as.vector(t(ret$vS[-6,])))
mpec.likelihood.Step2(mpec.Startvalues.Step2)
max(abs(mpec.constraint.Step2(mpec.Startvalues.Step2)))
mpec.likelihood.Step2(truth)
max(abs(mpec.constraint.Step2(truth)))

mpec.inequalityConstraint.Step2 = function(x) {
    return( c( x[2]-x[1], x[3]-x[2], x[4]-x[3] ));
}

mpec.jacobian.Step2 = function(x) {
  return( c(mpec.constraintGradient.Step2(x), -1, 1, -1, 1, -1, 1 ))
}



mpec.Startvalues.Step2 = matrix(nrow=10, ncol=Settings$nCheck*Settings$cCheck+Settings$nCheck+2)
for(jX in (1:NROW(mpec.Startvalues.Step2))) {
    mpec.Startvalues.Step2[jX,] = generateMPECStartValues()
    while(!is.finite( mpec.likelihood.Step2(mpec.Startvalues.Step2[jX,]) )) {
        mpec.Startvalues.Step2[jX,] = generateMPECStartValues()
    }
}

tic()
mpec.Estimates = knitro_ms(objFun = mpec.likelihood.Step2, 
                        objGrad = mpec.likelihoodGradient.Step2,
                        c_equality = mpec.constraint.Step2,
                        c_inequality = mpec.inequalityConstraint.Step2,
                        x0 = mpec.Startvalues.Step2, 
                        jac = mpec.jacobian.Step2,
                        jacIndexCons = c(mpec.constraintGradient.Step2(mpec.Startvalues.Step2, idx=TRUE)[,1],
                                         125, 125, 126, 126, 127, 127),
                        jacIndexVars = c(mpec.constraintGradient.Step2(mpec.Startvalues.Step2, idx=TRUE)[,2],
                                         0,1,1,2,2,3),
                        lb = rep(0, Settings$nCheck*Settings$cCheck+Settings$nCheck+2), 
                        ub = c( rep(10,Settings$nCheck), 20, 20 , rep(200, Settings$nCheck*Settings$cCheck)), 
                        optionsFile = "options.opt")
mpecTimer = toc()

# nfxp comparison
tic()
nfxp.Estimates = knitro_ms(x0 = mpec.Startvalues.Step2[,1:7], 
                        objFun = function(x) nfxp.likelihood.Step2(x, Data, Settings, Param),
                        objGrad = function(x) nfxp.gradient.Step2(x, Data, Settings, Param),
                        optionsFile="options.opt")
nfxpTimer = toc()


mpec.Estimates$x[1:7]
mpec.Estimates$iter
nfxp.Estimates$x 
nfxp.Estimates$iter

