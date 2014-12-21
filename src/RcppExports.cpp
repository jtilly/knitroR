// This file was generated by Rcpp::compileAttributes
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// knitroCon
NumericVector knitroCon(List fcts, NumericVector startValues, int m);
RcppExport SEXP knitroR_knitroCon(SEXP fctsSEXP, SEXP startValuesSEXP, SEXP mSEXP) {
BEGIN_RCPP
    SEXP __sexp_result;
    {
        Rcpp::RNGScope __rngScope;
        Rcpp::traits::input_parameter< List >::type fcts(fctsSEXP );
        Rcpp::traits::input_parameter< NumericVector >::type startValues(startValuesSEXP );
        Rcpp::traits::input_parameter< int >::type m(mSEXP );
        NumericVector __result = knitroCon(fcts, startValues, m);
        PROTECT(__sexp_result = Rcpp::wrap(__result));
    }
    UNPROTECT(1);
    return __sexp_result;
END_RCPP
}
// knitroUnc
NumericVector knitroUnc(List fcts, NumericVector startValues);
RcppExport SEXP knitroR_knitroUnc(SEXP fctsSEXP, SEXP startValuesSEXP) {
BEGIN_RCPP
    SEXP __sexp_result;
    {
        Rcpp::RNGScope __rngScope;
        Rcpp::traits::input_parameter< List >::type fcts(fctsSEXP );
        Rcpp::traits::input_parameter< NumericVector >::type startValues(startValuesSEXP );
        NumericVector __result = knitroUnc(fcts, startValues);
        PROTECT(__sexp_result = Rcpp::wrap(__result));
    }
    UNPROTECT(1);
    return __sexp_result;
END_RCPP
}
