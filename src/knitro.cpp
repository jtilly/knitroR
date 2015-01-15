#include <Rcpp.h>
#include "knitro.h"

using namespace Rcpp;

// Callback function that evaluates the objective function, the 
// constraints, and the gradients
int  callback (const int evalRequestCode,
    const int n,
    const int m,
    const int nnzJ,
    const int nnzH,
    const double * const x,
    const double * const lambda,
          double * const obj,
          double * const c,
          double * const objGrad,
          double * const jac,
          double * const hessian,
          double * const hessVector,
          void * userParams) {

        NumericVector xVector(n);
        for(int jX=0;jX<n;jX++) {
            xVector[jX] = x[jX];
        }

        List * listFctsPointer = (List *) userParams;
        List listFcts = * listFctsPointer;
        
        if( evalRequestCode == KTR_RC_EVALFC) {
            Function rObjFun = listFcts["objFun"];
            NumericVector fval(1);
            fval = rObjFun(xVector);		
    		*obj = fval(0);
            
         if(m>0) {
        
            Function rConstraint = listFcts["c"];
            NumericVector constraint(m);            
            constraint = rConstraint(xVector);
                            
            for(int jX=0;jX<m;jX++) {
                c[jX] = constraint(jX);
            }
         }
         
         return(0);
            
        } else if( evalRequestCode == KTR_RC_EVALGA) {
          
            Function rObjGrad = listFcts["objGrad"];
            NumericVector gradVal(n);
            gradVal = rObjGrad(xVector);
            for(int jX=0;jX<n;jX++) {
                objGrad[jX] = gradVal(jX);
            }
        
            if(m>0) {
                Function rJacobian = listFcts["jac"];
                NumericVector jacobian(nnzJ); 
                jacobian = rJacobian(xVector);            
                    
                for(int kX = 0; kX < nnzJ; kX++) {                        
                    jac[kX] = jacobian[kX];
                }
            }
            
            return(0);
            
        } else {
            return(-1);
        }
            
    
            
} 

//' Knitro C++ Wrapper
//' 
//' This function is the standard C++ wrapper around knitro. It defines the object 
//' \code{KTR_new} and defines a callback function that is used to evaluate the objective
//' function, the constraints, and gradients. The only deviation from the standard C++
//' wrapper is to use \code{UserParam} to pass the original R functions on to the C++
//' callback function. 
//' 
//' @param fcts is an R list of functions that includes the \code{objFun}, \code{objGrad}, \code{c}, and \code{jac}.
//' @param startValues is a vector of start values
//' @param num_equality_constraints is an integer with the number of equality constraints in \code{c}
//' @param num_inequality_constraints is an integer with the number of inequality constraints in \code{c}
//' @param nnzJ is an integer with the number of non-zero objects in the Jacobian
//' @param RjacIndexCons is a vector of length \code{nnzJ}. Each element contains the index of a 
//' particular constraint (i.e. the index of a row in the jacobian).
//' @param RjacIndexVars is a vector of length \code{nnzJ}. Each element contains the index of a 
//' particular variable (i.e. the index of a column in the jacobian).
//' @param ub a vector of upper bounds for each element in x0
//' @param lb a vector lower bounds for each element in x0
//' @param optionsFile the location of the options file 
//' @return A list with the vector that minimizes the objective function, the final function value, and Knitro's exit status
//' @seealso http://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html
// [[Rcpp::export]]
List knitroCpp(    List fcts, 
                            NumericVector startValues, 
                            int num_equality_constraints,
                            int num_inequality_constraints,
                            int nnzJ, 
                            NumericVector RjacIndexCons, 
                            NumericVector RjacIndexVars, 
                            NumericVector ub,
                            NumericVector lb,
                            CharacterVector optionsFile) {
                                    
        int m = num_equality_constraints+num_inequality_constraints;
    
        // let's make a pointer to a list
        List * fctsPointer = &fcts;
        
        // knitro variables
        int  nStatus;    
        KTR_context *kc;
        int n, nnzH, objGoal, objType;
        int *cType;
        int *jacIndexVars, *jacIndexCons;
        double obj, *x, *lambda;
        double *xLoBnds, *xUpBnds, *xInitial, *cLoBnds, *cUpBnds;

        // problem size and mem allocation
        n = startValues.length();
        nnzH = 0;
        x = (double *) malloc (n * sizeof(double));
        lambda = (double *) malloc ((m+n) * sizeof(double));

        xLoBnds      = (double *) malloc (n * sizeof(double));
        xUpBnds      = (double *) malloc (n * sizeof(double));
        xInitial     = (double *) malloc (n * sizeof(double));
        cType        = (int    *) malloc (m * sizeof(int));
        cLoBnds      = (double *) malloc (m * sizeof(double));
        cUpBnds      = (double *) malloc (m * sizeof(double));
        jacIndexVars = (int    *) malloc (nnzJ * sizeof(int));
        jacIndexCons = (int    *) malloc (nnzJ * sizeof(int));

        // objective type
        objType = KTR_OBJTYPE_GENERAL;
        objGoal = KTR_OBJGOAL_MINIMIZE;

        // bounds and constraints type
        for(int i = 0; i < n; i++) {
                xLoBnds[i] = lb[i];
                xUpBnds[i] = ub[i];
        }
        for(int j = 0; j < num_equality_constraints; j++) {
                cType[j] = KTR_CONTYPE_GENERAL;
                cLoBnds[j] = 0.0;
                cUpBnds[j] = 0.0;
        }
        for(int j = num_equality_constraints; j < m; j++) {
                cType[j] = KTR_CONTYPE_GENERAL;
                cLoBnds[j] = -KTR_INFBOUND;
                cUpBnds[j] = 0.0;
        }

        // initial point 
        for(int i = 0; i < n; i++)
                xInitial[i] = startValues[i];

        // sparsity pattern
        if(m>0 && nnzJ>0) {
            for(int k = 0; k < nnzJ; k++) {
                jacIndexCons[k] = RjacIndexCons[k];
                jacIndexVars[k] = RjacIndexVars[k];
            }
        }

        // create a KNITRO instance 
        kc = KTR_new();
        if (kc == NULL)
                return( -1 ); // probably a license issue

        // set options via textfile
        nStatus = KTR_load_param_file (kc, optionsFile[0]);
        
        // check if the gradient options make sense
        int gradopt;
        KTR_get_int_param_by_name(kc, "gradopt", &gradopt);
        
        if(gradopt!=2 && gradopt!=3) {
            // if gradient option is exact, but there's no objGrad, 
            // then change derivatives to forward
            if(!fcts.containsElementNamed("objGrad")) {
                KTR_set_int_param_by_name(kc, "gradopt", KTR_GRADOPT_FORWARD);    
                Rcpp::Rcout << "WARNING: gradopt was set to exact, but no objGrad function could be found. \n";
                Rcpp::Rcout << "         Using forward finite differences instead. \n";
            }
            if(m>0) {
                // if gradient option is exact, but there's no jac, 
                // then change derivatives to forward
                if(!fcts.containsElementNamed("jac")) {
                    KTR_set_int_param_by_name(kc, "gradopt", KTR_GRADOPT_FORWARD);
                    Rcpp::Rcout << "WARNING: gradopt was set to exact, but no jac function could be found. \n";
                    Rcpp::Rcout << "         Using forward finite differences instead. \n";
                }
            }
        }
        
        // only perform gradient check if a gradient was provided
        int derivcheck;
        KTR_get_int_param_by_name(kc, "derivcheck", &derivcheck);
        if(derivcheck==1 && !fcts.containsElementNamed("objGrad")) {
            KTR_set_int_param_by_name(kc, "derivcheck", 0);
            Rcpp::Rcout << "WARNING: derivcheck was set to 1, but no gradient was provided. \n";
            Rcpp::Rcout << "         Skipping derivatives check. \n";
        }
        if(derivcheck==1 && m>0 && !fcts.containsElementNamed("jac")) {
            KTR_set_int_param_by_name(kc, "derivcheck", 0);
            Rcpp::Rcout << "WARNING: derivcheck was set to 1, but no jacobian was provided. \n";
            Rcpp::Rcout << "         Skipping derivatives check. \n";
        }
        
        // check if hessopt makes sense
        int hessopt;        
        KTR_get_int_param_by_name(kc, "hessopt", &hessopt);
        if(hessopt <= 1 || hessopt>6) {
            Rcpp::Rcout << "ERROR: knitroR cannot deal with user defined Hessians at this point.\n";
            return(-1);
        }
        if(hessopt == 5) {
            Rcpp::Rcout << "ERROR: knitroR cannot deal with Hessian-vector products at this point.\n";
            return(-1);
        }
        
        // register the callback function 
        if (KTR_set_func_callback (kc, &callback) != 0)
                return( -1 );
        if (KTR_set_grad_callback (kc, &callback) != 0)
                return( -1 );

        // pass the problem definition to KNITRO 
        nStatus = KTR_init_problem (kc, n, objGoal, objType,
                        xLoBnds, xUpBnds,
                        m, cType, cLoBnds, cUpBnds,
                        nnzJ, jacIndexVars, jacIndexCons,
                        nnzH, NULL, NULL, xInitial, NULL);

        // free memory (KNITRO maintains its own copy) 
        free (xLoBnds);
        free (xUpBnds);
        free (xInitial);
        free (cType);
        free (cLoBnds);
        free (cUpBnds);
        free (jacIndexVars);
        free (jacIndexCons);

        // solver call 
        nStatus = KTR_solve (kc, x, lambda, 0, &obj,
                NULL, NULL, NULL, NULL, NULL, fctsPointer);

        if (nStatus != 0) {
                printf ("\nKNITRO failed to solve the problem, final status = %d\n",
                        nStatus);
        }
        else {
                printf ("\nKNITRO successful, objective is = %e\n", obj);
        }

        int numberOfIterations = KTR_get_number_iters(kc);
        int numberOfObjFunEval = KTR_get_number_FC_evals(kc);
        int numberOfGradEval = KTR_get_number_GA_evals(kc);

        // delete the KNITRO instance and primal/dual solution 
        KTR_free (&kc);
        
        NumericVector finalEstimates(n);
        for(int jX=0;jX<n;jX++) {
	        finalEstimates[jX] = x[jX];
        }
        
        free (x);
        free (lambda);

        return List::create(_["x"]       = finalEstimates,
                            _["fval"]    = obj,
                            _["status"]  = nStatus,
                            _["iter"]    = numberOfIterations,
                            _["objEval"] = numberOfObjFunEval,
                            _["gradEval"] = numberOfGradEval
                       );
}
