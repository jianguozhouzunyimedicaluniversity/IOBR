#' Generate reference gene matrix from DEGs result
#'
#' @param dds raw count data from RNA-seq
#' @param pheno  data frame or matrix;un-normalized counts of RNA-seq
#' @param mode mode "oneVSothers" or "pairs"; two modes for identifying significantly differentially expressed genes
#' @param FDR character vector; cell type class of the samples
#' @param dat data frame or matrix; normalized transcript quantification data (like FPKM, TPM). Note: cell's median expression level of the identified probes will be the output of reference_matrix.
#' @importFrom  DESeq2 DESeqDataSetFromMatrix
#' @importFrom  DESeq2 DESeq
#'
#' @return
#' @author Rongfang Shen
#' @export
#'
#' @example
generateRef_rnaseq <- function(dds, pheno, mode = "oneVSothers", FDR = 0.05, dat){
  if (!all(colnames(dds) == colnames(dat))){
    stop("The sample order of dds and dat much be identical")
  }
  dds <- round(dds, 0)
  keep <- rowSums(dds) >= 0.05 *ncol(dds)
  dds <- dds[keep,]
  dds <- na.omit(dds)
  samples <- data.frame(row.names = colnames(dds), cell = pheno)
  ncells <- unique(pheno)
  if (mode == "pairs"){
    dds <- DESeq2::DESeqDataSetFromMatrix(dds,
                                    colData = samples,
                                    design = ~ cell)
    dds <- DESeq2::DESeq(dds)
    contrasts <- list()
    # generate contrast list
    for (i in 1:length(ncells)){
      cellA <- ncells[i]
      othercells <- setdiff(ncells, cellA)
      z1 <- length(othercells)
      for (j in 1:length(othercells)){
        cellB <- othercells[j]
        z <- (i - 1) * z1 + j
        contrasts[[z]]   <- c("cell", cellA, cellB)
      }
    }
    res <- lapply(contrasts, function(z){
      DESeq2::results(dds, contrast = z)
    })
  }
  if (mode == "oneVSothers"){
    res <- list()
    for (i in 1:length(ncells)){
     cellA <- ncells[i]
     samples$group <- NA
     samples$group <- ifelse(samples$cell == cellA, cellA, "others")
     dds2 <- DESeq2::DESeqDataSetFromMatrix(dds,
                                   colData = samples,
                                   design = ~ group)
     dds2 <- DESeq2::DESeq(dds2)
     res[[i]] <- DESeq2::results(dds2, contrast = c("group", cellA, "others"))
    }
  }
  resData <- lapply(res, function(x){
    tmp <- as.data.frame(x[order(x$padj), ])
    tmp <- data.frame(probe = rownames(tmp), tmp)
    tmp <- tmp[tmp$padj < FDR, ]
    return(tmp)
  })
  median_value <- t(dat) %>% as.data.frame() %>%
    split(., pheno) %>% purrr::map(function(x) matrixStats:: colMedians(as.matrix(x)))
  median_value <- do.call(cbind, median_value)
  rownames(median_value) <- rownames(dat)

  con_nums <- c()
  for (i in 50:200){
    probes <- resData %>% purrr::map(function(x)Top_probe(dat = x, i = i)) %>%
      unlist() %>% unique()
    tmpdat <- median_value[probes, ]
    #condition number
    con_num <- kappa(tmpdat)
    con_nums <- c(con_nums, con_num)
  }
  i <- c(50:200)[which.min(con_nums)]
  probes <- resData %>% map(function(x)Top_probe(dat = x, i = i)) %>%
    unlist() %>% unique()
  reference <- median_value[probes, ]
  reference <- data.frame(NAME = rownames(reference), reference)
  G <- i
  condition_number <- min(con_nums)
  return(list(reference_matrix = reference, G = G, condition_number = condition_number,
              whole_matrix = median_value))
}

