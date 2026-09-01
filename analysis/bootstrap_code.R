#this code is required to test bootstrap code before implementation
library(nnls)

# ============================================================
# Shared setup / helpers: Perlman LRT statistic + multivariate
# bootstrap test that resamples the whole vector-valued statistic
# ============================================================

#' Perlman (1969) likelihood ratio test statistic
#'
#' Computes Perlman's (1969) likelihood ratio test statistic for testing
#' whether a multivariate mean lies in the positive orthant, against an
#' unrestricted alternative, when the covariance matrix is unknown and
#' estimated from the data.
#'
#' @param data A numeric matrix or data frame with \code{n} rows
#'   (observations) and \code{p} columns (variables). Requires \code{n > p}
#'   so that the scaled covariance matrix \code{A} is invertible.
#'
#' @return A list with:
#'   \itemize{
#'     \item \code{U} — the Perlman LRT statistic (numeric scalar)
#'     \item \code{m_hat} — the constrained mean estimate, i.e. the
#'       closest point to \code{x} in the positive orthant under the
#'       Mahalanobis (\eqn{A^{-1}}-weighted) distance
#'     \item \code{info} — a list of intermediate quantities
#'       (\code{x}, \code{A}, \code{A_inv}, \code{xbar}, \code{S}) useful
#'       for diagnostics or reuse
#'   }

perlman_lrt_stat <- function(data) {
  
  data <- as.matrix(data)
  n <- nrow(data)
  p <- ncol(data)
  
  if (n <= p) {
    stop(sprintf("Need n > p for A = (n-1)S to be invertible (got n=%d, p=%d).", n, p))
  }
  
  #compute sample mean and sample covariance
  xbar <- colMeans(data)
  S <- cov(data) 
  
  x <- sqrt(n) * xbar
  A <- (n - 1) * S
  
  A_inv <- solve(A)
  U_chol <- chol(A_inv) 
  # Reframe the constrained Mahalanobis minimization as an NNLS problem:
    # minimize ||U_chol %*% x - U_chol %*% m||^2 over m >= 0
    # <=> minimize (x - m)' A^{-1} (x - m)
  design <- U_chol
  target <- as.vector(U_chol %*% x)
  
  fit <- nnls::nnls(design, target)
  m_hat <- fit$x
  
  diff <- x - m_hat
  num <- as.numeric(t(m_hat) %*% A_inv %*% m_hat)        # ||m_hat||_A^2
  denom <- 1 + as.numeric(t(diff) %*% A_inv %*% diff)    # 1 + ||m_hat - x||_A^2
  U_stat <- num / denom
  
  list(
    U = U_stat,
    m_hat = m_hat,
    info = list(x = x, A = A, A_inv = A_inv, xbar = xbar, S = S)
  )
}

#' Bootstrap test using Perlman's LRT statistic
#'
#' Performs a nonparametric bootstrap hypothesis test based on the Perlman
#' (1969) LRT statistic (see \code{\link{perlman_lrt_stat}}). The null
#' distribution of the statistic is simulated by resampling residuals
#' (data centered at the observed column means) with replacement, so the
#' bootstrap approximates the sampling distribution of \code{U} under the
#' null hypothesis that the mean vector is not in the positive orthant
#' (i.e. centered at zero).
#'
#' @param seed Integer. Random seed, set for reproducibility of the
#'   resampling.
#' @param bootstrap_iters Integer. Number of bootstrap resamples to draw.
#' @param data A numeric matrix or data frame with \code{n} rows
#'   (observations) and \code{p} columns (variables), passed through to
#'   \code{\link{perlman_lrt_stat}}.
#'
#' @return A list with:
#'   \itemize{
#'     \item \code{u_obs} — the observed Perlman LRT statistic on the
#'       original (uncentered) data
#'     \item \code{u_stars} — a numeric vector of length
#'       \code{bootstrap_iters} containing the statistic computed on each
#'       bootstrap resample of the centered residuals
#'     \item \code{p} — the one-sided bootstrap p-value, computed as the
#'       proportion of bootstrap statistics exceeding \code{u_obs}
#'       (with a +1/+1 correction to avoid a p-value of exactly zero)
#'   }
#'
#' @details Each bootstrap iteration resamples entire rows (i.e. whole
#'   observation vectors) with replacement — there is no within-group or
#'   column-wise resampling.
#'
#' @seealso \code{\link{perlman_lrt_stat}}
#'

multivariate_bootstrap <- function(seed, bootstrap_iters, data){
  
  #set seed for reproducibility
  set.seed(seed)
  #keep track of number of observations
  n <- nrow(data)
  index <- seq(1,n)
  #store bootstrap test statistics
  u_stars <- rep(0,bootstrap_iters)
  #number of u_stars that exceed the observed statistic
  j <- 0 
  
  #next, to simulate the null environment, let's calculate the residuals x_i - xbar 
  residuals <- sweep(data,2, colMeans(data),"-")
  
  #compute observed u on uncentered data 
  u_obs <- perlman_lrt_stat(data)$U
  
  # bootstrap: resample whole rows of the centered residuals with
  # replacement to approximate the null distribution of U
  for(i in 1:bootstrap_iters){
    #collect a sample of size n with replacement
    boot_indices <- sample(index,n,replace = TRUE)
    e_star <- residuals[boot_indices,]
    #compute statistic on the resampled null data
    u_star <- perlman_lrt_stat(e_star)$U
    u_stars[i] <- u_star
    #is u_star bigger than u? (keep a tally)
    if(u_star > u_obs){
      j <- j+1
    }
  }

  #compute p value with +1/+1 correction
  p <- (j+1)/(bootstrap_iters+1)
  return(list(
    u_obs = u_obs, 
    u_stars = u_stars, 
    p = p
  ))
}
# ============================================================
# Standalone: individual (per-variable) mean bootstrap test
# ============================================================

#' Bootstrap test of individual variable means
#'
#' Performs a nonparametric bootstrap hypothesis test on each variable's
#' (column's) mean independently, by resampling rows of the data with
#' replacement. Unlike \code{\link{multivariate_bootstrap}}, this test
#' does not use the Perlman LRT statistic — it directly compares each
#' bootstrapped column mean, under the null, to the observed column mean.
#'
#' @param seed Integer. Random seed, set for reproducibility of the
#'   resampling.
#' @param bootstrap_iters Integer. Number of bootstrap resamples to draw.
#' @param data A numeric matrix or data frame with \code{n} rows
#'   (observations) and \code{d} columns (variables).
#'
#' @return A list with:
#'   \itemize{
#'     \item \code{p_vals} — a numeric vector of length \code{d} with one
#'       bootstrap p-value per variable
#'     \item \code{mu_obs} — the observed column means (numeric vector of
#'       length \code{d})
#'     \item \code{mu_stars} — a \code{bootstrap_iters x d} matrix of
#'       bootstrapped column means under the null, one row per iteration
#'   }
#'
#' @details Each bootstrap iteration resamples entire rows (i.e. whole
#'   observation vectors) with replacement from the data centered at
#'   \code{mu_obs} — there is no within-group or column-wise resampling.
#'   For each variable, the p-value is the one-sided proportion of
#'   bootstrap means that are greater than or equal to the observed mean
#'   (with a +1/+1 correction to avoid a p-value of exactly zero).
#'

mean_bootstrap <- function(seed, bootstrap_iters, data){
  #set seed 
  set.seed(seed=seed)
  
  #data storage
  n <- nrow(data)
  d <- ncol(data) #number of variables tested
  row_indices <- seq(1,n)
  
  #matrix to store bootstrapped means: one row per iteration, one column per variable 
  mu_stars <- matrix(0,nrow = bootstrap_iters,ncol = d)
  
  #observed statistic: column means of the original data
  mu_obs <- colMeans(data)
  
  #simulate null environment by centering each column at its observed mean
  null_envir <- sweep(data,2,mu_obs,"-")
  
  # keep track of, per variable, how many bootstrap means meet/exceed the observed mean
  p_val_count <- rep(0,d)  
  
  #compute bootstrap
  for (iter in 1:bootstrap_iters){
    #resampled n rows with replacement
    boot_indices <- sample(row_indices, n, replace = TRUE)
    boot_sample <- null_envir[boot_indices,]
    
    #compute bootstrap means under H0
    mu_star <- (colMeans(boot_sample))
    mu_stars[iter,] <- mu_star
    
    #update per variable tally of bootstrap means >= observed mean
    for(var in 1:d){
      if(mu_star[[var]]>=mu_obs[[var]]){
        p_val_count[var] <- p_val_count[var]+1
      }
    }
  }
  
  #apply +1/+1 correction to avoid p=0. 
  p_vals <- (p_val_count+1)/(bootstrap_iters+1)
  
  return(list(
    p_vals = p_vals,
    mu_obs = mu_obs,
    mu_stars = mu_stars
  ))
}


