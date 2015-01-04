#' Call the knitro C++ interface
#' 
#' This function passes user defined R functions on to the C++ interface
#'
#' @param objFun is a scalar valued R function that returns the objective function
#' @param objGrad is a vector-valued R function with the gradient
#' @param c_inequality is a vector-valued R function with inequality constraints
#' @param c_equality is a vector-valued R function with equality constraints
#' @param jac is a vector with the content of the Jacobian (sparse)
#' @param jacIndexCons refers to each element of jac and contains the number 
#' of the constraint it refers to. Indexing is C++ compatible, i.e. the first 
#' constraint has index 0
#' @param jacIndexVars refers to each element of jac and contains the number 
#' of the variable it refers to. Indexing is C++ compatible, i.e. the first 
#' variable has index 0
#' @param x0 is a vector with starting values
#' @param optionsFile is the path and filename of the options file. 
#' If it does not exist, the function will create it
#' @return a list with the final estimates, the function value, and Knitro's exit status
#' 
knitro = function( objFun = NULL, 
                   objGrad = NULL, 
                   c_equality = NULL, 
                   c_inequality = NULL, 
                   jac = NULL, 
                   jacIndexCons = NULL, 
                   jacIndexVars = NULL, 
                   x0 = NA, 
                   lb = NULL,
                   ub = NULL,
                   optionsFile = "options.opt" ) {
    
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
            honorbnds   0
            linsolver   4
            bar_directinterval  100000
            bar_maxbacktrack  10
            bar_maxcrossit   0
            bar_maxrefactor  5")
        sink()      
        
        warning("No options file found. Created default options file \"options.opt\"")
    }
    
    # check if an objective function was provided as an argument
    if(!exists("objFun", mode = "function")) {
        stop("Need to provide objective function!")
    }
    # check if start values were provided
    if(any(is.na(x0))) {
        stop("Need to provide starting values")
    }
    # check if the objective function can be evaluated
    tryCatch({objFun(x0)}, error = function(err) 
    {print(paste("couldn't evaluate objective function at start values",  err)) })
    
    # assemble the list of functions fcts and begin with the objective function
    fcts = list("objFun" = objFun);
    
    # check if a objective gradient was provided
    if(!is.null(objGrad) && exists("objGrad", mode = "function")) {
        
        # check if the dimensions make sense
        if(length(objGrad(x0))!=length(x0)) {
            stop("objGrad has wrong length")
        }
        
        # add the gradient to the list of functions
        fcts = c( fcts, list("objGrad" = objGrad))
    }
    
    # check if any equality constraints were provided 
    num_equality_constraints = 0
    if(!is.null(c_equality) && exists("c_equality", mode = "function")) {
        # add them to the list of functions
        fcts = c( fcts, list("c" = c_equality))
        # find number of equality constraints
        num_equality_constraints = length(c_equality(x0))
    }
    
    # check if any inequality constraints were provided 
    num_inequality_constraints = 0
    if(!is.null(c_inequality) && exists("c_inequality", mode = "function")) {
        # add them to fcts$c
        if("c" %in% names(fcts)) {
            fcts$c = function(x) c( c_equality(x), c_inequality(x) );
        } else {
            fcts = c( fcts, list("c" = c_inequality))
        }
        # find number of inequality constraints
        num_inequality_constraints = length(c_inequality(x0))
    }
    
    # if the number of constraints is positive, check if a jacobian was provided
    num_nonzeros_in_jacobian = 0
    if((num_inequality_constraints + num_equality_constraints)>0 
       && !is.null(jac) && exists("jac", mode = "function")) {
        fcts = c( fcts, list("jac" = jac))
        # how many non-zeros do we have in the jacobian?
        num_nonzeros_in_jacobian = length(fcts$jac(x0));
        
        # check if jacIndexCons and jacIndexVars exist
        if(!is.null(jacIndexCons) && !is.null(jacIndexVars)) {
            
            if(length(jacIndexCons)!=length(fcts$jac(x0)) || length(jacIndexVars)!=length(fcts$jac(x0))) {
                stop("number of elements in jacIndexCons and jac are not equal")
            }
            
            if(length(jacIndexVars)!=length(fcts$jac(x0))) {
                stop("number of elements in jacIndexVars and jac are not equal")
            }
            
        }  else {
            # check if the jacobian is dense
            if(length(fcts$jac(x0)) == (num_inequality_constraints + num_equality_constraints)*length(x0)) {
                jac = c( jac )
                jacIndexCons = rep( (1:(num_inequality_constraints + num_equality_constraints)), length(x0) )
                jacIndexVars = kronecker(1:length(x0), 
                                         seq(from=1, to=1, length.out = (num_inequality_constraints + num_equality_constraints)))
            } else {
                stop("jac is not dense, but no sparsity pattern was provided")
            }
        }
        
    }
    if(num_nonzeros_in_jacobian==0) {
        jacIndexVars = vector(mode="numeric", length=1)
        jacIndexCons = vector(mode="numeric", length=1)
    }
    
    if( !is.null(ub) ) {
        if(length(ub) != length(x0)) {
            stop("ub has wrong length")
        }
    } else {
        ub = rep(1e10, length(x0))
    }
    if( !is.null(lb) ) {
        if(length(lb) != length(x0)) {
            stop("lb has wrong length")
        }
    } else {
        lb = rep(-1e10, length(x0))
    }
    
    # call knitro cpp interface
    results = knitroCpp(fcts          = fcts, 
                        startValues   = x0, 
                        num_equality_constraints = num_equality_constraints, 
                        num_inequality_constraints = num_inequality_constraints, 
                        nnzJ          = num_nonzeros_in_jacobian, 
                        RjacIndexCons = jacIndexCons, 
                        RjacIndexVars = jacIndexVars, 
                        lb            = lb,
                        ub            = ub, 
                        optionsFile   = optionsFile)
    
    return(results)
    
}

#' Call the knitro C++ interface using multiple start values
#' 
#' This function passes user defined R functions on to the C++ interface. In contrast
#' to knitro() knitro uses a matrix of startvalues as input, where each row corresponds
#' to one vector of start values that knitro will attempt to optimize the objective function.
#' The function returns the solution for the set of start values that resulted in the lowest
#' objective function.
#'
#' @param objFun is a scalar valued R function that returns the objective function
#' @param objGrad is a vector-valued R function with the gradient
#' @param c_inequality is a vector-valued R function with inequality constraints
#' @param c_equality is a vector-valued R function with equality constraints
#' @param jac is a vector with the content of the Jacobian (sparse)
#' @param jacIndexCons refers to each element of jac and contains the number 
#' of the constraint it refers to. Indexing is C++ compatible, i.e. the first 
#' constraint has index 0
#' @param jacIndexCons refers to each element of jac and contains the number 
#' of the variable it refers to. Indexing is C++ compatible, i.e. the first 
#' variable has index 0
#' @param x0 is a matrix with starting values
#' @param optionsFile is the path and filename of the options file. 
#' If it does not exist, the function will create it
#' @return a list with the final estimates, the function value, and Knitro's exit status
#' 
knitro_ms = function( objFun = NULL, 
                      objGrad = NULL, 
                      c_equality = NULL, 
                      c_inequality = NULL, 
                      jac = NULL, 
                      jacIndexCons = NULL, 
                      jacIndexVars = NULL, 
                      x0 = NA, 
                      lb = NULL,
                      ub = NULL,
                      optionsFile = "options.opt" ) {
    
    if(NROW(x0)==1 || NCOL(x0) ==1 ) {
        x0 = matrix(x0, nrow=1, ncol=length(x0));
    }
    
    countSuccesses = 0
    
    for( jX in 1:NROW(x0)) {
        
        # do the optimization at the current start values
        current = knitro(objFun, objGrad, c_equality, c_inequality, jac, jacIndexCons,  jacIndexVars, x0[jX,], lb, ub, optionsFile)
        
        # count whther the knitro finished with a "good" exit flag
        if(current$status == 0 || current$status==-100) {
            countSuccesses = countSuccesses + 1
        }
        
        # store the best optimization outcome
        if(jX==1) {
            best = current
        }
        else {
            if(best$fval > current$fval && (current$status==0 || current$status==-100)) {
                best = current
            }
        }
    }
    
    best = c(best, list( converged = countSuccesses ))
    
    return(best)
}