test_that("Check if optimizer with inequality constraints works", {
    # define the objective function
    objFun = function(x) {
        9.0 - 8.0 * x[1] - 6.0 * x[2] - 4.0 * x[3] + 2.0 * x[1] ^ 2 + 2.0 * x[2] ^
            2 + x[3] ^ 2 + 2.0 * x[1] * x[2] + 2.0 * x[1] * x[3]
    }
    
    # define the inequality constraint
    c_inequality = function(x) {
        return(x[1] + x[2] + 2.0 * x[3] - 3.0)
    }
    
    lb = c(0, 0, 0)
    
    # define starting values
    x0 = c(0.5, 0.5, 0.5)
    
    results1 = knitro(
        objFun = objFun, c_inequality = c_inequality, lb = lb, x0 = x0
    )
    
    expect_true(all(abs(results1$x - c(4 / 3, 7 / 9, 4 / 9)) < 1e-7))
    
})
