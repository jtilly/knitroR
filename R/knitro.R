knitro = function( objFun=NULL, objGrad=NULL, ceq=NULL, jac=NULL, x0=NA, options=NULL, optionsFile="" ) {
    
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
    
    if(exists("objGrad", mode = "function")) {
        fcts = c( fcts, "objGrad" = objGrad)
    }
    if(exists("ceq", mode = "function")) {
        fcts = c( fcts, "ceq" = ceq)
        # find number of constraints
        m = length(ceq(x0))
    }
    if(exists("jac", mode = "function")) {
        fcts = c( fcts, "jac" = jac)
    }
    
    options = list("gradopt"="KTR_GRADOPT_FORWARD");
    
    x1 = knitroCpp(fcts, x0, m, options, optionsFile)
    
    return(x1)
    
}