#' Summary of measurement nonequivalence effects
#'
#' \code{dmacs_summary} returns a summary of measurement non-equivalence
#' effects given lists of parameters.
#'
#' \code{dmacs_summary} is called by \code{\link{lavaan_dmacs}} and
#' \code{\link{mplus_dmacs}}, which are the only functions in this
#' package intended for casual users
#'
#' @param LambdaList is a list, indexed by groups, of factor loading
#' matrices (dataframes are allowed).
#' @param NuList is a list, indexed by groups, of vectors of indicator
#' intercepts.
#' @param MeanList is a list, indexed by groups, of vectors of factor means.
#' For unidimensional models, this is simply a list of factor means.
#' @param VarList is a list, indexed by groups, of vectors of factor variances.
#' For unidimensional models, this is simply a list of factor variances.
#' @param SDList is a list, indexed by groups, of vectors of indicator
#' observed standard deviations used as the denominator of the dmacs effect
#' size. This will usually either be pooled standard deviations or the
#' standard deviation of the reference group. Each group, including the
#' reference group, must be included in SDList (although the standard
#' deviations for the reference group are ignored).
#' @param Groups is a vector of group names. If no value is provided,
#' dmacs_summary will try to use \code{names(LambdaList)}; if LambdaList
#' has no names, then the groups will be numbered.
#' @param RefGroup can be the name of the reference group (as a string),
#' or the index of the reference group (as a number). RefGroup defaults to
#' the first group if no value is provided. It is strongly recommended to
#' provide the reference group as a string, since group names in data are
#' often ordered by their appearance in the data, not alphabetically.
#' @param ThreshList is a list, indexed by groups, of lists, indexed by items, of
#' vectors of thresholds (for categorical indicators). For categorical
#' indicators, do \strong{not} provide a matrix of thresholds for each group.
#' Defaults to \code{NULL} for continuous indicators.
#' @param ThetaList is a list, indexed by groups, of vectors of item residual
#' variances for categorical items. Defaults to \code{NULL} for continuous
#' indicators.
#' @param categorical is a Boolean variable declaring whether the variables
#' in the model are ordered categorical. Models in which some variables are
#' categorical and others are continuous are not supported. If no value is
#' provided, categorical defaults to \code{FALSE}, although if multiple
#' thresholds are provided for an item, categorical will be forced to
#' \code{TRUE}. A graded response model with probit link (e.g., DWLS in
#' lavaan or WLSMV in Mplus) is used for categorical variables. If you desire
#' for other categorical models (e.g., IRT parameterization) to be supported,
#' e-mail the maintainer.
#'
#' @return A list, indexed by groups, of lists of measurement nonequivalence
#' effects  from Nye and Drasgow (2011), including dmacs, expected bias in the mean score by item,
#' expected bias in the mean total score, and expected bias in the variance
#' of the total score. Expected bias in the variance of the total score is
#' only supplied for unidimensional models with linear indicators (i.e., not categorical)
#' in the current version of this package.
#'
#' @examples
#' LambdaList <- list(Group1 <- matrix(c(1.00, 0.74,  1.14, 0.92), ncol = 1),
#'                    Group2 <- matrix(c(1.00, 0.76,  1.31, 0.98), ncol = 1))
#' NuList     <- list(Group1 <- c(0.00, 1.28, -0.82, 0.44),
#'                    Group2 <- c(0.00, 0.65, -0.77, 0.47))
#' MeanList   <- list(Group1 <- 0.21,
#'                    Group2 <- 0.19)
#' VarList    <- list(Group1 <- 1.76,
#'                    Group2 <- 1.34)
#' SDList     <- list(Group1 <- c(2.12, 1.85,  1.12, 3.61),
#'                    Group2 <- c(NA, NA, NA, NA))
#' Groups <- c("Group1", "Group2")
#' RefGroup <- "Group2"
#' dmacs_summary(LambdaList, NuList, MeanList, VarList, SDList,
#'               Groups, RefGroup)
#'
#' @section References:
#' Nye, C. & Drasgow, F. (2011). Effect size indices for analyses of
#' measurement equivalence: Understanding the practical importance of
#' differences between groups. \emph{Journal of Applied Psychology, 96}(5),
#' 966-980.
#' @export



dmacs_summary <- function (LambdaList, NuList,
                           MeanList, VarList, SDList,
                           Groups = NULL, RefGroup = 1,
                           ThreshList = NULL, ThetaList = NULL,
                           categorical = FALSE) {

  ## See if we need to get group names, and if we do, try to grab them from the names of LambdaList. Otherwise, just number the groups
  if (is.null(Groups)) {
    if (is.null(names(LambdaList))) {
      Groups <- c(1:length(LambdaList))
    } else {
      Groups <- names(LambdaList)
    }
  }

  ## If RefGroup is a string, lets turn it into an index
  if (is.character(RefGroup)) {
    RefGroup <- match(RefGroup, Groups)
  }

  # The categorical and continuous cases are different from each other
  if ( categorical) { # now we are categorical
    ## if only two groups, then call DIF effect summary single right away, else iterate over the focal groups
    if (length(Groups) == 2) {
      dmacs_summary_single(LambdaF = LambdaList[-RefGroup][[1]],
                           NuF     = NuList[-RefGroup][[1]],
                           ThreshF = ThreshList[-RefGroup][[1]],
                           ThetaF  = ThetaList[-RefGroup][[1]],
                           MeanF   = MeanList[-RefGroup][[1]],
                           VarF    = VarList[-RefGroup][[1]],
                           SD      = SDList[-RefGroup][[1]],
                           LambdaR = LambdaList[[RefGroup]],
                           NuR     = NuList[[RefGroup]],
                           ThreshR = ThreshList[[RefGroup]],
                           ThetaR  = ThetaList[[RefGroup]],
                           categorical = categorical)
    } else {
      mapply(dmacs_summary_single,
             LambdaF = LambdaList[-RefGroup],
             NuF     = NuList[-RefGroup],
             ThreshF = ThreshList[-RefGroup],
             ThetaF  = ThetaList[-RefGroup],
             MeanF   = MeanList[-RefGroup],
             VarF    = VarList[-RefGroup],
             SD      = SDList[-RefGroup],
             MoreArgs = list(LambdaR = LambdaList[[RefGroup]],
                             NuR     = NuList[[RefGroup]],
                             ThreshR = ThreshList[[RefGroup]],
                             ThetaR  = ThetaList[[RefGroup]],
                             categorical = categorical),
             SIMPLIFY = FALSE)
    }
  } else { # Continuous indicators
    ## if only two groups, then call DIF effect summary single right away, else iterate over the focal groups
    if (length(Groups) == 2) {
      dmacs_summary_single(LambdaF = LambdaList[-RefGroup][[1]],
                           NuF     = NuList[-RefGroup][[1]],
                           MeanF   = MeanList[-RefGroup][[1]],
                           VarF    = VarList[-RefGroup][[1]],
                           SD      = SDList[-RefGroup][[1]],
                           LambdaR = LambdaList[[RefGroup]],
                           NuR     = NuList[[RefGroup]],
                           categorical = categorical)
    } else {
      mapply(dmacs_summary_single,
             LambdaF = LambdaList[-RefGroup],
             NuF     = NuList[-RefGroup],
             MeanF   = MeanList[-RefGroup],
             VarF    = VarList[-RefGroup],
             SD      = SDList[-RefGroup],
             MoreArgs = list(LambdaR = LambdaList[[RefGroup]],
                             NuR     = NuList[[RefGroup]],
                             categorical = categorical),
             SIMPLIFY = FALSE)
    }
  }






}



#' Summary of measurement nonequivalence effects for a single group
#'
#' \code{dmacs_summary_single} returns a summary of measurement non-equivalence
#' effects given parameters for a focal and reference group.
#'
#' \code{dmacs_summary_single} is called by \code{dmacs_summary}, which
#' in turn is called by \code{\link{lavaan_dmacs}} and
#' \code{\link{mplus_dmacs}}, which are the only functions in this
#' package intended for casual users
#'
#' @param LambdaR is the factor loading of the indicator onto the factor of
#' interest for the reference group.
#' @param LambdaF is the factor loading of the indicator onto the factor of
#' interest for the focal group.
#' @param NuR is the indicator intercept for the reference group.
#' @param NuF is the indicator intercept for the focal group.
#' @param MeanF is the factor mean in the focal group
#' @param VarF is the factor variances in the focal group.
#' @param SD is the indicator standard deviations to be used as
#' the denominator of the dmacs effect size. This will usually either be
#' pooled standard deviation for the indicator or the standard deviation
#' for the indicator in the reference group.
#' @param ThreshR is a vector of thresholds (for categorical indicators)
#' for the reference group. Defaults to \code{NULL} for continuous
#' indicators.
#' @param ThreshF is a vector of thresholds (for categorical indicators)
#' for the focal group. Defaults to \code{NULL} for continuous
#' indicators.
#' @param ThetaR is the indicator residual variance in the
#' reference group. Defaults to \code{NULL} for continuous
#' indicators.
#' @param ThetaF is the indicator residual variance in the
#' focal group. Defaults to \code{NULL} for continuous
#' indicators.
#' @param categorical is a Boolean variable declaring whether the variables
#' in the model are ordered categorical. Models in which some variables are
#' categorical and others are continuous are not supported. If no value is
#' provided, categorical defaults to \code{FALSE}, although if multiple
#' thresholds are provided for an item, categorical will be forced to
#' \code{TRUE}. A graded response model with probit link (e.g., DWLS in
#' lavaan or WLSMV in Mplus) is used for categorical variables. If you desire
#' for other categorical models (e.g., IRT parameterization) to be supported,
#' e-mail the maintainer.
#'
#' @return A list of measurement nonequivalence effects from Nye and Drasgow
#' (2011), including dmacs,
#' expected bias in the mean score by item, expected bias in the mean total
#' score, and expected bias in the variance of the total score. Expected bias
#' in the variance of the total score is only supplied for unidimensional
#' models in the current version of this package
#'
#' @examples
#' LambdaF <- matrix(c(1.00, 0.74,  1.14, 0.92), ncol = 1)
#' LambdaR <- matrix(c(1.00, 0.76,  1.31, 0.98), ncol = 1)
#' NuF     <- c(0.00, 1.28, -0.82, 0.44)
#' NuR     <- c(0.00, 0.65, -0.77, 0.47)
#' MeanF   <- 0.21
#' VarF    <- 1.76
#' SD      <- c(2.12, 1.85,  1.12, 3.61)
#' dmacs_summary_single(LambdaR, LambdaF, NuR, NuF, MeanF, VarF, SD)
#'
#' @section References:
#' Nye, C. & Drasgow, F. (2011). Effect size indices for analyses of
#' measurement equivalence: Understanding the practical importance of
#' differences between groups. \emph{Journal of Applied Psychology, 96}(5),
#' 966-980.
#' @export


dmacs_summary_single <- function (LambdaR, LambdaF,
                                  NuR, NuF,
                                  MeanF, VarF, SD,
                                  ThreshR = NULL, ThreshF = NULL,
                                  ThetaR = NULL, ThetaF = NULL,
                                  categorical = FALSE) {

  ## Categorical and continuous work a bit differently from each other
  if ( categorical) { # Now we are categorical
    categorical <- TRUE
    if (!is.list(ThreshR)) stop("Thresholds must be in a list indexed by item. The thresholds for each item should be a vector")

    ## If unidimensional, then things are straightforward, otherwise not so much!!
    if (ncol(LambdaR) == 1) {
      DMACS <- mapply(item_dmacs,
                      LambdaR, LambdaF,
                      NuR, NuF,
                      MeanF, VarF, SD,
                      ThreshR, ThreshF,
                      ThetaR, ThetaF,
                      categorical)
      names(DMACS) <- rownames(LambdaR)

      DMACS_signed <- mapply(item_dmacs_signed,
                             LambdaR, LambdaF,
                             NuR, NuF,
                             MeanF, VarF, SD,
                             ThreshR, ThreshF,
                             ThetaR, ThetaF,
                             categorical)
      names(DMACS_signed) <- rownames(LambdaR)

      ItemDeltaMean <- mapply(delta_mean_item,
                              LambdaR, LambdaF,
                              NuR, NuF,
                              MeanF, VarF,
                              ThreshR, ThreshF,
                              ThetaR, ThetaF,
                              categorical)
      names(ItemDeltaMean) <- rownames(LambdaR)

      MeanDiff <- sum(ItemDeltaMean, na.rm = TRUE)
      names(MeanDiff) <- colnames(LambdaR)

      list(DMACS = DMACS, DMACS_signed = DMACS_signed, ItemDeltaMean = ItemDeltaMean, MeanDiff = MeanDiff)

    } else {

      ## Need to give MeanF and VarF (which are vectors indexed by factor) the same structure as LambdaR (an array indexed by itemsxfactors)
      MeanF <- as.vector(MeanF)
      MeanF <- matrix(rep(MeanF, nrow(LambdaR)), nrow = nrow(LambdaR), byrow = TRUE)
      VarF  <- as.vector(VarF)
      VarF  <- matrix(rep(VarF, nrow(LambdaR)), nrow = nrow(LambdaR), byrow = TRUE)

      DMACS <- as.data.frame(matrix(mapply(item_dmacs,
                                           LambdaR, LambdaF,
                                           NuR, NuF,
                                           MeanF, VarF, SD,
                                           ThreshR, ThreshF,
                                           ThetaR, ThetaF,
                                           categorical),
                                    nrow = nrow(LambdaR)))
      colnames(DMACS) <- colnames(LambdaR)
      rownames(DMACS) <- rownames(LambdaR)

      DMACS_signed <- as.data.frame(matrix(mapply(item_dmacs_signed,
                                                  LambdaR, LambdaF,
                                                  NuR, NuF,
                                                  MeanF, VarF, SD,
                                                  ThreshR, ThreshF,
                                                  ThetaR, ThetaF,
                                                  categorical),
                                            nrow = nrow(LambdaR)))
      colnames(DMACS_signed) <- colnames(LambdaR)
      rownames(DMACS_signed) <- rownames(LambdaR)


      ## ItemDeltaMean has the same possible issues as DMACS
      ItemDeltaMean <- as.data.frame(matrix(mapply(delta_mean_item,
                                                   LambdaR, LambdaF,
                                                   NuR, NuF,
                                                   MeanF, VarF,
                                                   ThreshR, ThreshF,
                                                   ThetaR, ThetaF,
                                                   categorical),
                                            nrow = nrow(LambdaR)))
      colnames(ItemDeltaMean) <- colnames(LambdaR)
      rownames(ItemDeltaMean) <- rownames(LambdaR)

      MeanDiff <- colSums(ItemDeltaMean, na.rm = TRUE)

      list(DMACS = DMACS, DMACS_signed = DMACS_signed, ItemDeltaMean = ItemDeltaMean, MeanDiff = MeanDiff)


    }

  } else { # Now we are continuous
    ## If unidimensional, then things are straightforward, otherwise not so much!!
    if (ncol(LambdaR) == 1) {
      DMACS <- mapply(item_dmacs, LambdaR, LambdaF,
                                  NuR, NuF,
                                  MeanF, VarF, SD, categorical = FALSE)
      names(DMACS) <- rownames(LambdaR)

      DMACS_signed <- mapply(item_dmacs_signed, 
                             LambdaR, LambdaF,
                             NuR, NuF,
                             MeanF, VarF, SD, categorical = FALSE)
      names(DMACS_signed) <- rownames(LambdaR)

      ItemDeltaMean <- mapply(delta_mean_item, LambdaR, LambdaF,
                                               NuR, NuF,
                                               MeanF, VarF, categorical = FALSE)
      names(ItemDeltaMean) <- rownames(LambdaR)

      MeanDiff <- sum(ItemDeltaMean, na.rm = TRUE)
      names(MeanDiff) <- colnames(LambdaR)

      VarDiff <- delta_var(LambdaR, LambdaF, VarF)
      names(VarDiff) <- colnames(LambdaR)
      list(DMACS = DMACS, ItemDeltaMean = ItemDeltaMean, MeanDiff = MeanDiff, VarDiff = VarDiff)


    } else {

      ## Need to give MeanF and VarF (which are vectors indexed by factor) the same structure as LambdaR (an array indexed by itemsxfactors)
      MeanF <- as.vector(MeanF)
      MeanF <- matrix(rep(MeanF, nrow(LambdaR)), nrow = nrow(LambdaR), byrow = TRUE)
      VarF  <- as.vector(VarF)
      VarF  <- matrix(rep(VarF, nrow(LambdaR)), nrow = nrow(LambdaR), byrow = TRUE)

      DMACS <- as.data.frame(matrix(mapply(item_dmacs,
                                           LambdaR, LambdaF,
                                           NuR, NuF,
                                           MeanF, VarF, SD, categorical = FALSE),
                                    nrow = nrow(LambdaR)))
      colnames(DMACS) <- colnames(LambdaR)
      rownames(DMACS) <- rownames(LambdaR)

      DMACS_signed <- as.data.frame(matrix(mapply(item_dmacs_signed,
                                           LambdaR, LambdaF,
                                           NuR, NuF,
                                           MeanF, VarF, SD, categorical = FALSE),
                                    nrow = nrow(LambdaR)))
      colnames(DMACS_signed) <- colnames(LambdaR)
      rownames(DMACS_signed) <- rownames(LambdaR)


      ## ItemDeltaMean has the same possible issues as DMACS
      ItemDeltaMean <- as.data.frame(matrix(mapply(delta_mean_item,
                                                   LambdaR, LambdaF,
                                                   NuR, NuF,
                                                   MeanF, VarF, categorical = FALSE),
                                            nrow = nrow(LambdaR)))
      colnames(ItemDeltaMean) <- colnames(LambdaR)
      rownames(ItemDeltaMean) <- rownames(LambdaR)

      MeanDiff <- colSums(ItemDeltaMean, na.rm = TRUE)

      ## delta_var needs to be redesigned for multidimensional models, so let's leave it off for now
      #VarDiff <- delta_var(LambdaR, LambdaF, VarF)


      list(DMACS = DMACS, DMACS_signed = DMACS_signed, ItemDeltaMean = ItemDeltaMean, MeanDiff = MeanDiff)#, VarDiff = VarDiff)
    }

  }

}


#' Summary of measurement nonequivalence effects
#'
#' \code{lavaan_dmacs} returns a summary of measurement non-equivalence
#' effects given a fitted multigroup lavaan object.
#'
#' @param fit is a fitted lavaan multi-group object. Only CFA models are
#' supported, and be sure to have an anchor item.
#' @param RefGroup can be the name of the reference group (as a string),
#' or the index of the reference group (as a number). RefGroup defaults to
#' the first group if no value is provided. It is strongly recommended to
#' provide the reference group as a string, since group names in data are
#' often ordered by their appearance in the data, not alphabetically. When
#' \code{long = TRUE}, RefGroup is either the index of the reference timepoint
#' or the name of the latent factor at the reference timepoint.
#' @param dtype describes the pooling of standard deviations for use in the
#' denominator of the dmacs effect size. Possibilities are "pooled" for
#' pooled standard deviations, or "glass" for always using the standard
#' deviation of the reference group.
#' @param MEtype described the type of measurement equivalence testing
#' being performed. Defaults to "Group" for multigroup testing. Other
#' option is "Longitudinal" (or "Long") for longitudinal testing.
#' Only unidimensional models are supported with longitudinal data.
#' Note that output will always use indicator names from the reference
#' timepoint.
#'
#' @return A list, indexed by group or timepoint, of lists of measurement nonequivalence
#' effects from Nye and Drasgow (2011), including dmacs, expected bias in
#' the mean score by item,
#' expected bias in the mean total score, and expected bias in the variance
#' of the total score. Expected bias in the variance of the total score is
#' only supplied for unidimensional models in the current version of this
#' package
#'
#' @examples
#' HS.model <- '  visual  =~ x1 + x2 + x3
#'                textual =~ x4 + x5 + x6
#'                speed   =~ x7 + x8 + x9 '
#'fit <- lavaan::cfa(HS.model,
#'                   data = lavaan::HolzingerSwineford1939,
#'                   group = "school")
#'lavaan_dmacs(fit, RefGroup = "Pasteur")
#'
#'
#' @section References:
#' Nye, C. & Drasgow, F. (2011). Effect size indices for analyses of
#' measurement equivalence: Understanding the practical importance of
#' differences between groups. \emph{Journal of Applied Psychology, 96}(5),
#' 966-980.
#' @export


lavaan_dmacs <- function (fit, RefGroup = 1, dtype = "pooled", MEtype = "Group") {
  if (grepl("ong", MEtype, fixed = TRUE)) { # Long, Longitudinal, long, longitudinal
    ## Groups are time-points. We ignore correlated residuals!

    # Make a vector of factor names
    Groups <- colnames(lavaan::lavInspect(fit, what = "est")$lambda)

    # If RefTime is a name, turn it into an index
    if (is.character(RefGroup)) { RefGroup <- match(RefGroup, Groups) }

    # Store the estimates and the data, because I am about to reference them a LOT of times
    FitEst  <- lavaan::lavInspect(fit, "est")
    FitData <- lavaan::lavInspect(fit, "data")

    ## factor loadings, item intercepts, factor means, and factor variances are easy
    LambdaList <- lapply(Groups, function(x) {
      Lambdas <- FitEst$lambda[FitEst$lambda[,x] != 0, x]
      matrix(Lambdas, ncol = 1, dimnames = list(names(Lambdas)))
    })
    names(LambdaList) <- Groups

    NuList <- lapply(1:length(Groups), function (x) {
      if (is.null(FitEst$nu)) {
        # fill in zeros, because if intercepts are not in the model, they are automatically zero
        rep(0, length(rownames(LambdaList[[x]])))
      } else {
        FitEst$nu[rownames(LambdaList[[x]]),]
      }
    })
    names(NuList) <- Groups

    MeanList   <- lapply(Groups, function(x) {
      if (is.null(FitEst$alpha)) {
        # If factor mean is not mentioned in the model, it must be zero!
        0
      } else {
        FitEst$alpha[x,1]
      }
    })
    names(MeanList) <- Groups

    VarList    <- lapply(Groups, function(x) {
      FitEst$psi[x,x]
    })
    names(VarList) <- Groups

    ## compute the sds for use in Equation 3 of Nye and Drasgow (2011)
    if (dtype == "pooled") {
      refsd  <- colSD(FitData[,rownames(LambdaList[[RefGroup]])], na.rm = TRUE)
      refn   <- colSums(!is.na(FitData[,rownames(LambdaList[[RefGroup]])]))
      SDList <- lapply(1:length(Groups), function (x) {
        focsd <- colSD(FitData[, rownames(LambdaList[[x]])], na.rm = TRUE)
        focn  <- colSums(!is.na(FitData[, rownames(LambdaList[[x]])]))
        ((focn-1)*focsd+(refn-1)*refsd)/((focn-1)+(refn-1))
      })
    } else if (dtype == "glass") { ## Glass says to always use the SD of the reference group
      SDs    <- colSD(FitData[,rownames(LambdaList[[RefGroup]])], na.rm = TRUE)
      SDList <- lapply(1:length(Groups), function (x) {SDs})
      names(SDList) <- Groups
    } else {
      stop("Only \"pooled\" and \"glass\" SD types are supported")
    }

    ## Check to see if we are using categorical or linear variables, because Thresh and Theta only apply to categorical
    if (length(lavaan::lavNames(fit, type = "ov.ord")) == 0) {
      categorical  <- FALSE
      ThreshList <- NULL
      ThetaList <- NULL
    } else {
      categorical  <- TRUE

      ## Make a list of thresholds indexed by group
      ThreshList <- lapply(1:length(Groups), function (x) {
        # Fetch indicator names so we can grepl them
        ItemNames <- rownames(LambdaList[[x]])

        # Return a list index by items
        lapply(ItemNames, function (y) {
          # now we need to fetch the thresholds for this item.
          FitEst$tau[grepl(paste0(y, "\\|"), rownames(FitEst$tau))]
        })
      })

      ## make a list of residual variances indexed by group
      ThetaList <- lapply(1:length(Groups), function (x) {
        diag(FitEst$theta)[rownames(LambdaList[[x]])]
      })

    }

  } else {

    # Now we are doing multi-group measurement equivalence testing
    Groups <- names(lavaan::lavInspect(fit, "est"))

    ## If RefGroup is a string, turn it into an index
    if (is.character(RefGroup)) {
      RefGroup <- match(RefGroup, Groups)
    } else {
      warning(paste("It is recommended that you provide the name of the reference group as a string; see ?lavaan_dmacs. The reference group being used is", Groups[RefGroup]))
    }

    ## factor loadings, item intercepts, factor means, and factor variances are easy
    LambdaList <- lapply(lavaan::lavInspect(fit, "est"), function(x) {x$lambda})
    NuList     <- lapply(lavaan::lavInspect(fit, "est"), function(x) {x$nu})
    MeanList   <- lapply(lavaan::lavInspect(fit, "est"), function(x) {x$alpha})
    VarList    <- lapply(lavaan::lavInspect(fit, "est"), function(x) {diag(x$psi)})


    ## compute the sds for use in Equation 3 of Nye and Drasgow (2011)
    if (dtype == "pooled") {
      refsd  <- colSD(lavaan::lavInspect(fit, "data")[[RefGroup]], na.rm = TRUE)
      refn   <- colSums(!is.na(lavaan::lavInspect(fit, "data")[[RefGroup]]))
      SDList <- lapply(lavaan::lavInspect(fit, "data"), function(x) {
        focsd <- colSD(x, na.rm = TRUE)
        focn  <- colSums(!is.na(x))
        ((focn-1)*focsd+(refn-1)*refsd)/((focn-1)+(refn-1))
      })
    } else if (dtype == "glass") { ## Glass says to always use the SD of the reference group
      SDs    <- colSD(lavaan::lavInspect(fit, "data")[[RefGroup]], na.rm = TRUE)
      SDList <- lapply(1:length(Groups), function (x) {SDs})
      names(SDList) <- Groups
    } else {
      stop("Only \"pooled\" and \"glass\" SD types are supported")
    }


    ## Check to see if we are using categorical or linear variables, because Thresh works differently in those cases
    if (length(lavaan::lavNames(fit, type = "ov.ord")) == 0) {
      categorical  <- FALSE
    } else {
      categorical  <- TRUE

      ## Need the item names so we can grepl them
      ItemNames <- rownames(lavaan::lavInspect(fit, "est")[[1]]$lambda)

      ## I don't know why I am not doing this as nested for loops!! Nesting lapply inside of lapply is awful
      ThreshList <- lapply(lavaan::lavInspect(fit, "est"), function(x) {
        ## This next line makes a LIST indexed by item, which ensures that the mapply in DIF_effect_summary_single iterates over the thresholds properly
        lapply(ItemNames,
               ## The funny paste0 is in case one item name is an extension of another item name (e.g., item10 vs item1)
               function (iname, threshlist) {threshlist[grepl(paste0(iname, "\\|"), rownames(threshlist))]},
               x$tau)
      })

      # Now we need to get the thetas, too!!
      ThetaList <- lapply(lavaan::lavInspect(fit, "est"), function(x) {diag(x$theta)})
    }
  }


  Results <- dmacs_summary(LambdaList, NuList,
                           MeanList, VarList, SDList,
                           Groups, RefGroup,
                           ThreshList, ThetaList,
                           categorical)


  ## Note to self - we may need to insert some names here!!

  Results
}

