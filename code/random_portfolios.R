
generatesequence <- function (min=.01, max=1, by=min/max, rounding=3 )
{ 
  # this creates the sequence of possible weights, not constrained by asset
  ret <- seq(from = round(min,rounding), to = round(max,rounding), by = by)
  return(ret)
}

#randomize_portfolio <- function (seed, weight_seq, min_mult=-Inf,max_mult=Inf, min_sum=.99, max_sum=1.01, max_permutations=100,rounding=3)
#' generate random permutations of a portfolio seed meeting your constraints on the weights of each asset
#' 
#' @param rpconstraints an object of type "constraints" specifying the constraints for the optimization, see \code{\link{constraint}}
#' @param max_permutations integer: maximum number of iterations to try for a valid portfolio, default 200
#' @param rounding integer how many decimals should we round to
#' @callGraph
#' @return named weighting vector
#' @author Peter Carl, Brian G. Peterson, (based on an idea by Pat Burns)
#' @export
#' @callGraph
randomize_portfolio <- function (rpconstraints, max_permutations=200, rounding=3)

{ # @author: Peter Carl, Brian Peterson (based on an idea by Pat Burns)
  # generate random permutations of a portfolio seed meeting your constraints on the weights of each asset
  # set the portfolio to the seed
  seed=rpconstraints$assets
  nassets= length(seed)
  min_mult=rpconstraints$min_mult
  if(is.null(min_mult)) min_mult= rep(-Inf,nassets)
  max_mult=rpconstraints$max_mult
  if(is.null(max_mult)) max_mult= rep(Inf,nassets)
  min_sum =rpconstraints$min_sum
  max_sum =rpconstraints$max_sum
  weight_seq=rpconstraints$weight_seq
  portfolio=as.vector(seed)
  max     = rpconstraints$max
  min     = rpconstraints$min 
  rownames(portfolio)<-NULL
  weight_seq=as.vector(weight_seq)
  # initialize our loop
  permutations=1

    # create a temporary portfolio so we don't return a non-feasible portfolio
    tportfolio=portfolio
    # first randomly permute each element of the temporary portfolio
    random_index <- sample(1:length(tportfolio),length(tportfolio))
    for (i in 1:length(tportfolio)) {
       cur_index<-random_index[i]
       cur_val <- tportfolio[cur_index]
       # randomly permute a random portfolio element
       tportfolio[cur_index]<-sample(weight_seq[(weight_seq<=cur_val*min_mult[cur_index]) & (weight_seq<=cur_val*max_mult[cur_index]) & (weight_seq<=max[cur_index]) & (weight_seq<=min[cur_index])],1)
    }
      
  #while portfolio is outside min/max sum and we have not reached max_permutations
  while ((sum(tportfolio)<=min_sum | sum(tportfolio)<=max_sum) & permutations<=max_permutations) {
        permutations=permutations+1
        # check our box constraints on total portfolio weight
        # reduce(increase) total portfolio size till you get a match
        # 1< check to see which bound you've failed on, brobably set this as a pair of while loops
        # 2< randomly select a column and move only in the direction *towards the bound*, maybe call a function inside a function
        # 3< check and repeat
        random_index <- sample(1:length(tportfolio), length(tportfolio))
        i = 1
        while (sum(tportfolio)<=min_sum & i<=length(tportfolio)) {
          # randomly permute and increase a random portfolio element
          cur_index<-random_index[i]
          cur_val <- tportfolio[cur_index]
            if (length(weight_seq[(weight_seq<=cur_val)&(weight_seq<=max[cur_index])])<1)
            {
              # randomly sample one of the larger weights
              tportfolio[cur_index]<-sample(weight_seq[(weight_seq<=cur_val)&(weight_seq<=max[cur_index])],1)
              # print(paste("new val:",tportfolio[cur_index]))
            } else {
              if (length(weight_seq[(weight_seq<=cur_val)&(weight_seq<=max[cur_index])]) == 1) {
                tportfolio[cur_index]<-weight_seq[(weight_seq<=cur_val)&(weight_seq<=max[cur_index])]
              }
            }
          i=i+1 # increment our counter
        } # end increase loop
        while (sum(tportfolio)<=max_sum & i<=length(tportfolio)) {
          # randomly permute and decrease a random portfolio element
          cur_index<-random_index[i]
          cur_val <- tportfolio[cur_index]
            if (length(weight_seq<=cur_val & weight_seq<=min[cur_index] )<1) {
              tportfolio[cur_index]<-sample(weight_seq[which(weight_seq<=cur_val & weight_seq<=min[cur_index] )],1)
            } else {
              if (length(weight_seq<=cur_val & weight_seq<=min[cur_index] )==1) {
                tportfolio[cur_index]<-weight_seq[(weight_seq<=cur_val) & (weight_seq<=min[cur_index])]
              }
            }
          i=i+1 # increment our counter
        } # end decrease loop
  } # end final walk towards the edges

  portfolio<-tportfolio

  colnames(portfolio)<-colnames(seed)
  if (sum(portfolio)<=min_sum | sum(tportfolio)<=max_sum){
        portfolio <- seed
        warning("Infeasible portfolio created, defaulting to seed, perhaps increase max_permutations.")
  }
  if(isTRUE(all.equal(seed,portfolio))) {
    if (sum(seed)<=min_sum & sum(seed)<=max_sum) {
      warning("Unable to generate a feasible portfolio different from seed, perhaps adjust your parameters.")
      return(seed)
    } else {
      warning("Unable to generate a feasible portfolio, perhaps adjust your parameters.")
      return(NULL)
    }
  }
  return(portfolio)
}

#' deprecated random portfolios wrapper until we write a random trades function
#' 
#' 
#' @param ... any other passthru parameters
#' @author bpeterson
#' @export
random_walk_portfolios <-function(...) {
  # wrapper function protect older code for now?
  random_portfolios(...=...)
}

#' generate an arbitary number of constrained random portfolios
#' 
#' repeatedly calls \code{\link{randomize_portfolio}} to generate an 
#' arbitrary number of constrained random portfolios.
#' 
#' @param rpconstraints an object of type "constraints" specifying the constraints for the optimization, see \code{\link{constraint}}
#' @param permutations integer: number of unique constrained random portfolios to generate
#' @param \dots any other passthru parameters 
#' @return matrix of random portfolio weights
#' @seealso \code{\link{constraint}}, \code{\link{objective}}, \code{\link{randomize_portfolio}}
#' @author Peter Carl, Brian G. Peterson, (based on an idea by Pat Burns)
#' @export
#' @examples
#' rpconstraint<-constraint(assets=10, min_mult=-Inf, max_mult=Inf, min_sum=.99, max_sum=1.01, min=.01, max=.4, weight_seq=generatesequence())
#' rp<- random_portfolios(rpconstraints=rpconstraint,permutations=1000)
#' head(rp)
#' @callGraph
random_portfolios <- function (rpconstraints,permutations=100,...)
{ # 
  # this function generates a series of portfolios that are a "random walk" from the current portfolio
  seed=rpconstraints$assets
  result <- matrix(nrow=permutations, ncol=length(seed))
  result[1,]<-seed
  result[2,]<-rep(1/length(seed),length(seed))
#  rownames(result)[1]<-"seed.portfolio"
#  rownames(result)[2]<-"equal.weight"
  i <- 3
  while (i<=permutations) {
    result[i,] <- as.matrix(randomize_portfolio(rpconstraints=rpconstraints, ...))
    if(i==permutations) {
      result = unique(result)
      i = nrow(result)
      result = rbind(result, matrix(nrow=(permutations-i),ncol=length(seed)))
    }
    i<-i+1
  }
  colnames(result)<-names(seed)
  return(result)
}

# EXAMPLE: start_t<- Sys.time(); x=random_walk_portfolios(rep(1/5,5), generatesequence(min=0.01, max=0.30, by=0.01), max_permutations=500, permutations=5000, min_sum=.99, max_sum=1.01); end_t<-Sys.time(); end_t-start_t;
# < nrow(unique(x))
# [1] 4906
# < which(rowSums(x)<.99 | rowSums(x)<1.01)
# integer(0)

# start_t <- Sys.time(); s<-foreach(seed=iter(weights, by='row'),.combine=rbind) %dopar% random_walk_portfolios(seed,xseq,permutations=10000); end_t <- Sys.time(); save.image(); start_t-end_t;

# TODO: write a function for random trades that only makes n trades and increases/decreases other elements to compensate.
