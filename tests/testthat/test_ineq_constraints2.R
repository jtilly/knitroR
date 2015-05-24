test_that("Check if optimizer with inequality constraints works (2/2)", {
    # define the objective function
    objFun = function(x) {
        100 * (x[2] - x[1] ^ 2) ^ 2 + (1 - x[1]) ^ 2
    }
    
    # define the inequality constraint
    c_inequality = function(x) {
        return(c(1 - x[1] * x[2],-x[1] - x[2] ^ 2))
    }
    
    ub = c(0.5, 1e20);
    
    # define starting values
    x0 = c(-2, 1)
    
    results1 = knitro(
        objFun = objFun, c_inequality = c_inequality, ub = ub, x0 = x0
    )
    
    expect_true(all(abs(results1$x - c(0.5, 2.0)) < 1e-7))
    
})
