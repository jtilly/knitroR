knitro = function( objFun=NULL, objGrad=NULL, ceq=NULL, jac=NULL, jacIndexCons=NULL, jacIndexVars=NULL, x0=NA, options=NULL, optionsFile="" ) {
    
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