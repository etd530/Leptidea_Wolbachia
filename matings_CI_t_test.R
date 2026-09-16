#!/usr/bin/env Rscript

df <- read.delim2(file = "Table_1.tsv")

# test with multiple categories
for (i in 1:nrow(df)){
  fem <- df$Population..female.[i]
  mal <- df$Population..male.[i]
  df$mating_FxM[i] <- paste(fem, mal, sep=" x ")
}

df$Hatch.rate <- as.double(df$Hatch.rate)

kruskal.test(formula = Hatch.rate~mating_FxM, data = df)
pairwise.wilcox.test(df$Hatch.rate, df$mating_FxM, p.adjust.method = "fdr")

# test grouping non-CI matings with CI-expected matings
for (i in 1:nrow(df)){
  fem <- df$Population..female.[i]
  mal <- df$Population..male.[i]
  mating_FxM <- paste(fem, mal, sep=" x ")
  if(fem == "Ireland" & mal == "Sweden"){
    df$expected_CI[i] <- "Yes"
  } else {
    df$expected_CI[i] <- "No"
  }
}

wilcox.test(df$Hatch.rate~df$expected_CI)
t.test(df$Hatch.rate~df$expected_CI)

# test for fecundity differences in CI vs. non-CI matings
wilcox.test(df$Number.of.eggs.laid~df$expected_CI)
t.test(df$Number.of.eggs.laid~df$expected_CI)
