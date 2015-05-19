library(testthat)
library(knitroR)

if (Sys.getenv("KNITRO_MOCK") != 1) {
    test_check("knitroR")
}
