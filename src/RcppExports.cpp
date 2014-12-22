// This file was generated by Rcpp::compileAttributes
// Generator token: 10BE3573-1514-4C36-9D1C-5A225CD40393

#include <Rcpp.h>

using namespace Rcpp;

// knitroCpp
NumericVector knitroCpp(List fcts, NumericVector startValues, int m, List options, CharacterVector optionsFile);
RcppExport SEXP knitroR_knitroCpp(SEXP fctsSEXP, SEXP startValuesSEXP, SEXP mSEXP, SEXP optionsSEXP, SEXP optionsFileSEXP) {
BEGIN_RCPP
    SEXP __sexp_result;
    {
        Rcpp::RNGScope __rngScope;
        Rcpp::traits::input_parameter< List >::type fcts(fctsSEXP );
        Rcpp::traits::input_parameter< NumericVector >::type startValues(startValuesSEXP );
        Rcpp::traits::input_parameter< int >::type m(mSEXP );
        Rcpp::traits::input_parameter< List >::type options(optionsSEXP );
        Rcpp::traits::input_parameter< CharacterVector >::type optionsFile(optionsFileSEXP );
        NumericVector __result = knitroCpp(fcts, startValues, m, options, optionsFile);
        PROTECT(__sexp_result = Rcpp::wrap(__result));
    }
    UNPROTECT(1);
    return __sexp_result;
END_RCPP
}
