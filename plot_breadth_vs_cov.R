#!/opt/R/4.5.0/bin/R

#### LIBS ####
library(ggplot2)
library(dplyr)
library(tidyverse)
library(ggtext)

#### RAW DATA ####
df <- read.delim(file = "wCquin.coverages_report.tsv", header = T)

#### MAIN ####
# Fix NAs
df[df=="#DIV/0!"] <- NA

# Since some specimens were sequenced in 2 batches, summarise each pair of rows from the same specimen into their mean
df %>% separate(col = Sample, into = c("Sample", "Batch"), sep = ".batch_") -> df 

df_new <- as.data.frame(matrix(ncol = ncol(df), nrow = 0))
colnames(df_new) <- colnames((df))

for (i in 1:nrow(df)) {
  # get sample and batch
  sample <- df$Sample[i]
  batch <-  df$Batch[i]
  # if batch is 1, it's first time we encounter the sample, just copy it to the new df
  if (batch == "1") {
    nextrow = nrow(df_new) + 1 # add one row
    for (c in colnames(df_new)){
      df_new[nextrow, c] <- df[i, c] # for each column just copy the value
    }
    # else if batch == 2 we have 2 batches, we need to make the average of numeric variables (others, like species, are the same for both batches)
  } else if (batch == "2") {
    subset <- df[df$Sample == sample,] # get subset of rows of that sample
    goodrow <- which(df_new$Sample == sample) # get which row of thewnew df has that sample already
    
    for (c in colnames(df_new)) { # for each column, if numeric, substitute the value by the mean of the ones in the subset for that sample
      if (class(df[, c]) == "numeric") {
        df_new[goodrow, c] <- mean(subset[, c])
      }
    }
  }
}

df <- df_new
rm(df_new)

# Create species column
df$species <- str_split_i(df$Sample, pattern = '\\.', i = 2)
df$species <- if_else(df$species == "sin", "L. sinapis", df$species)
df$species <- if_else(df$species == "juv", "L. juvernica", df$species)
df$species <- if_else(df$species == "rea", "L. reali", df$species)


# Plot breadth against depth
pt <- ggplot(data = df, aes(x = Mean_cov, y = Breadth, color = species)) +
  geom_point() + labs(title = expression(paste(italic("Wolbachia"), " coverages from ", italic("Leptidea"), " samples")),
                      x = "Mean depth of coverage",
                      y = "Breadth of coverage") +
  scale_color_discrete(palette = c("#8a3694", "#f0ea10", "#1d83c5"), name = "Species",
                       labels = c(expression(italic("L. juvernica")), expression(italic("L. reali")), expression(italic("L.sinapis")))) +
  theme_linedraw() + theme(plot.title = element_text(hjust = 0.5))

ggsave(filename = "Figure_S1a.breadth_vs_depth.png", plot = pt, dpi = 300)

# Plot again, with xlim so that the revelant part of the plot is better seen
pt <- ggplot(data = df, aes(x = Mean_cov, y = Breadth, color = species)) +
  geom_point() + xlim(0, 50) + 
  labs(title = expression(paste(italic("Wolbachia"), " coverages from ", italic("Leptidea"), " samples (zoom in)")),
                                x = "Mean depth of coverage",
                                y = "Breadth of coverage") +
  scale_color_discrete(palette = c("#8a3694", "#f0ea10", "#1d83c5"), name = "Species",
                       labels = c(expression(italic("L. juvernica")), expression(italic("L. reali")), expression(italic("L.sinapis")))) +
  theme_linedraw() + theme(plot.title = element_text(hjust = 0.5))

ggsave(filename = "Figure_S1a.breadth_vs_depth.zoomed.png", plot = pt, dpi = 300)
