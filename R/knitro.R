knitro = function( objFun=NULL, objGrad=NULL, ceq=NULL, jac=NULL, jacIndexCons=NULL, jacIndexVars=NULL, x0=NA, options=NULL, optionsFile="options.opt" ) {
    
    
    if(!file.exists(optionsFile)) {
        sink(optionsFile)
        cat("# KNITRO 9.1.0 Options file
algorithm   1
maxit       1000
outlev      iter
derivcheck  1
derivcheck_tol 1e-06
derivcheck_type central
feastol     1e-06
opttol      1e-06
xtol        1e-15
gradopt     1
hessopt     2
honorbnds   1
linsolver   4
bar_directinterval  100000
bar_maxbacktrack  10
bar_maxcrossit   0
bar_maxrefactor  5")
        sink()      
        
        warning("No options file found. Created default options file \"options.opt\"")
    }
    
    
    if(!exists("objFun", mode = "function")) {
        stop("Need to provide objective function!")
    }
    if(any(is.na(x0))) {
        stop("Need to provide starting values")
    }
    tryCatch(
        {objFun(x0)}, 
        error = function(err) {
            print(paste("couldn't evaluate objective function at start values",  err));
        }
    )
    
    fcts = list("objFun" = objFun);
    m = 0;
    nnzJ = 0;
    if(is.null(jacIndexCons)) {
        jacIndexCons = vector(mode="numeric", length=1);
    }
    if(is.null(jacIndexVars)) {
        jacIndexVars = vector(mode="numeric", length=1);
    }
    
    if(exists("objGrad", mode = "function")) {
        fcts = c( fcts, "objGrad" = objGrad)
    }
    if(exists("ceq", mode = "function")) {
        fcts = c( fcts, "ceq" = ceq)
        # find number of constraints
        m = length(ceq(x0))
    }
    if(m>0 && exists("jac", mode = "function")) {
        fcts = c( fcts, "jac" = jac)
        
        # how many non-zeros do we have in the jacobian?
        nnzJ = length(fcts$jac(x0));
        
    }
    
    options = list("gradopt"="KTR_GRADOPT_FORWARD");
    
    x1 = knitroCpp(fcts, x0, m, nnzJ, jacIndexCons, jacIndexVars, options, optionsFile)

    return(x1)
    
}