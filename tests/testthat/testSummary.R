test_that("dmacs_summary is not broken", {

  LambdaList <- list(Group1 <- matrix(c(1.00, 0.74,  1.14, 0.92), ncol = 1),
                     Group2 <- matrix(c(1.00, 0.76,  1.31, 0.98), ncol = 1))
  LambdaList2 <- list(Group1 <- matrix(c(1.00, 0.74, 0, 0, 0, 0,  1.14, 0.92), ncol = 2),
                     Group2 <- matrix(c(1.00, 0.76, 0, 0, 0, 0,  1.31, 0.98), ncol = 2))
  ThreshList <- list(Group1 <- c(0.00, 1.28, -0.82, 0.44),
                     Group2 <- c(0.00, 0.65, -0.77, 0.47))
  ThreshList2 <- list(Group1 <- list(0.00, 1.28, -0.82, 0.44),
                     Group2 <- list(0.00, 0.65, -0.77, 0.47))
  ThreshList3 <- list(Group1 <- list(c(-1, 0.00, 1.5), c(-0.25, 1.28), c(-1.61, -0.82, 0, 1.11), 0.44),
                      Group2 <- list(c(-1.28, 0.23, 1.25), c(-0.25, 1.66), c(-1.61, -1.18, -0.25, 0.87), 0.25))
  ThreshList4 <- list(Group1 <- list(c(-1, 0.00, 1.5), c(-0.25, 1.28), c(-1.61, -0.82, 0, 1.11), 0.44),
                      Group2 <- list(c(-1.28, 0.23, 1.25), c(-0.25, 1.66), c(-1.61, -1.18, -0.25), 0.25))
  MeanList   <- list(Group1 <- 0.21,
                     Group2 <- 0.19)
  VarList    <- list(Group1 <- 1.76,
                     Group2 <- 1.34)
  SDList     <- list(Group1 <- c(2.12, 1.85,  1.12, 3.61),
                     Group2 <- c(2.38, 1.44,  1.67, 2.15))
  Groups <- c("Group1", "Group2")
  RefGroup <- "Group2"

  expect_equal(dmacs_summary(LambdaList, ThreshList, MeanList, VarList, SDList, Groups, RefGroup), list(DMACS = c(0.00000000, 0.38997060, 0.24811349, 0.02880497), ItemDeltaMean = c(0.00000000, 0.83021704, -0.11369383, -0.05651525), MeanDiff = 0.660008, VarDiff = -1.782), tolerance = .00001)
  expect_known_output(dmacs_summary(LambdaList2, ThreshList, MeanList, VarList, SDList, Groups, RefGroup), "d_sum_multi.rds", update = FALSE)
  expect_error(dmacs_summary(LambdaList, ThreshList, MeanList, VarList, SDList, Groups, RefGroup, categorical = TRUE),"Thresholds must be in a list indexed by item. The thresholds for each item should be a vector")
  expect_equal(dmacs_summary(LambdaList, ThreshList2, MeanList, VarList, SDList, Groups, RefGroup, categorical = TRUE), list(DMACS = c(0.000000000, 0.083322420, 0.022104064, 0.004459561), ItemDeltaMean = c(0.000000000, -0.160378048,  0.003161234,  0.011124317), MeanDiff = -0.1460925), tolerance = .00001)
  expect_equal(dmacs_summary(LambdaList, ThreshList3, MeanList, VarList, SDList, Groups, RefGroup), list(DMACS = c(0.02577838, 0.04575298, 0.22451775, 0.01621731), ItemDeltaMean = c(-0.05325132,  0.08741389, -0.26369274, -0.05811619), MeanDiff = -0.2876464), tolerance = .00001)
  expect_error(dmacs_summary(LambdaList, ThreshList4, MeanList, VarList, SDList, Groups, RefGroup), "Item must have same number of thresholds in both reference and focal group")
  expect_equal(dmacs_summary(LambdaList, ThreshList, MeanList, VarList, SDList), list(DMACS = c(0.00000000, 0.46819121, 0.13742292, 0.04046284), ItemDeltaMean = c(0.00000000, -0.72487849, 0.09526908, 0.04792394), MeanDiff = -0.5816855, VarDiff = 1.273), tolerance = .00001)
})

## dmacs_summary_single is tested by dmacs_summary
