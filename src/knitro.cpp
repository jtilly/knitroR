#include <Rcpp.h>
#include "knitro.h"

using namespace Rcpp;

/* callback function that evaluates the objective
   and constraints */
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
                NumericVector jacobian; 
                jacobian = rJacobian(xVector);            
                    
                for (int kX = 0; kX < m*n; kX++) {                        
                        jac[kX] = jacobian[kX];
                }
            }
            
            return(0);
            
        } else {
            return(-1);
        }
            
    
            
} 


// inputs:
// objective function , objectiveGradient, constraints, constraint jacobian


// [[Rcpp::export]]
NumericVector knitroCon(List fcts, NumericVector startValues, int m) {
    
        // let's make a pointer to a list
        List * fctsPointer = &fcts;
        
        int  nStatus;    

        /* variables that are passed to KNITRO */
        KTR_context *kc;
        int n, nnzJ, nnzH, objGoal, objType;
        int *cType;
        int *jacIndexVars, *jacIndexCons;
        double obj, *x, *lambda;
        double *xLoBnds, *xUpBnds, *xInitial, *cLoBnds, *cUpBnds;
        int i, j, k; // convenience variables

        /*problem size and mem allocation */
        n = startValues.length();
        nnzJ = n*m;
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

        /* objective type */
        objType = KTR_OBJTYPE_GENERAL;
        objGoal = KTR_OBJGOAL_MINIMIZE;

        /* bounds and constraints type */
        for (i = 0; i < n; i++) {
                xLoBnds[i] = -KTR_INFBOUND;
                xUpBnds[i] = KTR_INFBOUND;
        }
        for (j = 0; j < m; j++) {
                cType[j] = KTR_CONTYPE_GENERAL;
                cLoBnds[j] = 0.0;
                cUpBnds[j] = 0.0;
        }

        /* initial point */
        for (i = 0; i < n; i++)
                xInitial[i] = startValues[i];

        /* sparsity pattern (here, of a full matrix) */
        k = 0;
        for (i = 0; i < n; i++)
                for (j = 0; j < m; j++) {
                        jacIndexCons[k] = j;
                        jacIndexVars[k] = i;
                        k++;
                }
        /* create a KNITRO instance */
        kc = KTR_new();
        if (kc == NULL)
                exit( -1 ); // probably a license issue

        /* set options: automatic gradient and hessian matrix */
        if (KTR_set_int_param_by_name (kc, "gradopt", KTR_GRADOPT_EXACT) != 0)
                exit( -1 );
        if (KTR_set_int_param_by_name (kc, "honorbnds", KTR_HONORBNDS_NO) != 0)
                exit( -1 );
        if (KTR_set_int_param_by_name (kc, "hessopt", KTR_HESSOPT_BFGS) != 0)
                exit( -1 );
        if (KTR_set_int_param_by_name (kc, "outlev", KTR_OUTLEV_ITER_VERBOSE) != 0)
                exit( -1 );
        if (KTR_set_int_param_by_name (kc, "derivcheck", KTR_DERIVCHECK_FIRST) != 0)
                exit( -1 );
                

        /* register the callback function */
        if (KTR_set_func_callback (kc, &callback) != 0)
                exit( -1 );
        if (KTR_set_grad_callback (kc, &callback) != 0)
                exit( -1 );

        /* pass the problem definition to KNITRO */
        nStatus = KTR_init_problem (kc, n, objGoal, objType,
                        xLoBnds, xUpBnds,
                        m, cType, cLoBnds, cUpBnds,
                        nnzJ, jacIndexVars, jacIndexCons,
                        nnzH, NULL, NULL, xInitial, NULL);

        /* free memory (KNITRO maintains its own copy) */
        free (xLoBnds);
        free (xUpBnds);
        free (xInitial);
        free (cType);
        free (cLoBnds);
        free (cUpBnds);
        free (jacIndexVars);
        free (jacIndexCons);


        /* solver call */
        nStatus = KTR_solve (kc, x, lambda, 0, &obj,
                NULL, NULL, NULL, NULL, NULL, fctsPointer);

        if (nStatus != 0)
                printf ("\nKNITRO failed to solve the problem, final status = %d\n",
                        nStatus);
        else
                printf ("\nKNITRO successful, objective is = %e\n", obj);

        /* delete the KNITRO instance and primal/dual solution */
        KTR_free (&kc);

        NumericVector finalEstimates(n);
        for(int jX=0;jX<n;jX++) {
	        finalEstimates[jX] = x[jX];
        }
        
        free (x);
        free (lambda);

        return( finalEstimates );
}

// [[Rcpp::export]]
NumericVector knitroUnc(List fcts, NumericVector startValues) {
    return knitroCon(fcts, startValues, 0);
}