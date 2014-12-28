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
                    
                for (int kX = 0; kX < nnzJ; kX++) {                        
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
//' @param num_equality_constraints is an integer with the number of inequality constraints in \code{c}
//' @param nnzJ is an integer with the number of non-zero objects in the Jacobian
//' @param RjacIndexCons is a vector of length \code{nnzJ}. Each element contains the index of a 
//' particular constraint (i.e. the index of a row in the jacobian).
//' @param RjacIndexVars is a vector of length \code{nnzJ}. Each element contains the index of a 
//' particular variable (i.e. the index of a column in the jacobian).
//' @param ub a vector of upper bounds for each element in x0
//' @param lb a vector lower bounds for each element in x0
//' @param optionsFile the location of the options file 
//' @return the vector that minimizes the objective function
//' @seealso http://www.artelys.com/tools/knitro_doc/2_userGuide/gettingStarted/startCallableLibrary.html
// [[Rcpp::export]]
NumericVector knitroCpp(    List fcts, 
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
        // convenience variables
        int i, j, k; 

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
        for (i = 0; i < n; i++) {
                xLoBnds[i] = lb[i];
                xUpBnds[i] = ub[i];
        }
        for (j = 0; j < num_equality_constraints; j++) {
                cType[j] = KTR_CONTYPE_GENERAL;
                cLoBnds[j] = 0.0;
                cUpBnds[j] = 0.0;
        }
        for (j = num_equality_constraints; j < m; j++) {
                cType[j] = KTR_CONTYPE_GENERAL;
                cLoBnds[j] = -KTR_INFBOUND;
                cUpBnds[j] = 0.0;
        }

        // initial point 
        for (i = 0; i < n; i++)
                xInitial[i] = startValues[i];

        // sparsity pattern
        if(m>0 && nnzJ>0) {
            for (k = 0; k < nnzJ; k++) {
                jacIndexCons[k] = RjacIndexCons[k];
                jacIndexVars[k] = RjacIndexVars[k];
            }
        }

        // create a KNITRO instance 
        kc = KTR_new();
        if (kc == NULL)
                exit( -1 ); // probably a license issue

        // set options via textfile
        nStatus = KTR_load_param_file (kc, optionsFile[0]);
        
        // register the callback function 
        if (KTR_set_func_callback (kc, &callback) != 0)
                exit( -1 );
        if (KTR_set_grad_callback (kc, &callback) != 0)
                exit( -1 );

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

        if (nStatus != 0)
                printf ("\nKNITRO failed to solve the problem, final status = %d\n",
                        nStatus);
        else
                printf ("\nKNITRO successful, objective is = %e\n", obj);

        // delete the KNITRO instance and primal/dual solution 
        KTR_free (&kc);
        
        NumericVector finalEstimates(n);
        for(int jX=0;jX<n;jX++) {
	        finalEstimates[jX] = x[jX];
        }
        
        free (x);
        free (lambda);

        return( finalEstimates );
}
