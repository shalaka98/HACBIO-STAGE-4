rm(list = ls())
setwd("/home/hp/Documents/HackbioCancer")
BiocManager::install("ConsensusClusterPlus")
BiocManager::install("pheatmap")
BiocManager::install("sesameData")

# Import libraries
library("TCGAbiolinks")
library("edgeR")
library("limma")
library("EDASeq")
library("sesameData")
library("SummarizedExperiment")
library("gplots")
library("biomaRt")
library("pheatmap")
library("dplyr")
library("ConsensusClusterPlus")

countData <- as.matrix(read.csv("Normalized_count_Data_lgg.csv", row.names = 1))

# View the first few rows to confirm the data was read correctly
head(countData)

#filtering using median absolute deviation | using variance is an alternative option
mads <- apply(countData, 1, mad)
cluster_lgg <- countData[rev(order(mads))[1:5000],]
cluster_lgg <- sweep(cluster_lgg, 1, apply(cluster_lgg, 1, median, na.rm = TRUE))

#hierarchical clustering as unsupervised clustering method
results = ConsensusClusterPlus(cluster_lgg, maxK = 20, reps = 1000, pItem = 0.8, pFeature = 1, 
                               title = "final_cluster", clusterAlg = "hc", distance = "pearson", 
                               seed=1262118388.71279, plot="png")

# The result is a list where you can check the consensus matrix, clusters, and other metrics
# Extract clusters from the optimal K (e.g., K = 4)
optimalK <- 4  # Set based on visual inspection of the consensus heatmap
# Extract cluster assignments for K = 4
clusterAssignments <- results[[optimalK]]$consensusClass
clusterAssignments
# Create annotations with cleaned sample labels
sampleLabels <- colnames(countData)

# Clean sample labels by removing trailing numbers
idh_status_cleaned <- gsub("Mutant.*", "Mutant", sampleLabels)
idh_status_cleaned <- gsub("WT.*", "WT", idh_status_cleaned)

annotations <- data.frame(IDH_Status = idh_status_cleaned)
rownames(annotations) <- sampleLabels
View(annotations)
# Assign row and column names to the consensus matrix
rownames(results[[optimalK]]$consensusMatrix) <- colnames(cluster_lgg)
colnames(results[[optimalK]]$consensusMatrix) <- colnames(cluster_lgg)

# Plot the consensus matrix heatmap with annotations
pheatmap(
  results[[optimalK]]$consensusMatrix,     # Consensus matrix
  annotation_col = annotations,            # Annotations for IDH mutation status
  show_colnames = FALSE,
  show_rownames = FALSE,
  clustering_distance_rows = "correlation",
  clustering_distance_cols = "correlation",
  clustering_method = "complete",
  main = paste("Consensus Matrix for K =", optimalK),
  filename = "heatmap_output.png"           # Save the plot as PNG
)

# Track how many "Mutant" and "WT" samples are in each cluster
cluster_summary <- data.frame(
  Cluster = clusterAssignments,
  IDH_Status = annotations$IDH_Status
)

# Count the number of Mutants and WT in each cluster
cluster_count <- table(cluster_summary$Cluster, cluster_summary$IDH_Status)

# Print the summary
print(cluster_count)

#creating a tracking plot for clusters
barplot(cluster_count, beside = TRUE, legend = TRUE,
        col = c("blue", "red", "green","yellow"), main = "Distribution of IDH Status in Expression Clusters",
        xlab = "Cluster", ylab = "Sample Count")










