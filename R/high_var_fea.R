


#' Extract top varity features form statistical results
#'
#' @param result a tibble
#' @param target name of variables
#' @param name_padj
#' @param name_logfc
#' @param n
#' @param padj_cutoff
#' @param logfc_cutoff
#' @author Dongqiang Zeng
#' @return
#' @export
#'
#' @examples
high_var_fea<-function(result, target, name_padj = "padj", padj_cutoff = 1, name_logfc,logfc_cutoff = 0, n = 10 ){

  colnames(result)[which(colnames(result)==name_padj)]<-"padj"
  colnames(result)[which(colnames(result)==name_logfc)]<-"logfc"
  colnames(result)[which(colnames(result)==target)]<-"target"

  topVarFeature1<-result%>%
    # filter(!is.na(target)) %>%
    dplyr::filter(padj < padj_cutoff) %>%
    dplyr::arrange(padj) %>%
    dplyr::filter(logfc < - abs(logfc_cutoff)) %>%
    dplyr::select(target,padj,logfc)

  topVarFeature2<-result %>%
    # filter(!is.na(target)) %>%
    dplyr::filter(padj < padj_cutoff) %>%
    dplyr::arrange(padj) %>%
    dplyr::filter(logfc > abs(logfc_cutoff)) %>%
    dplyr::select(target,padj,logfc)

  if(dim(topVarFeature1)[1]<n)
    warning(paste0("The cutoff was too strict for down regulated features, only ", dim(topVarFeature1)[1] ,"  variables were found in the result"))

  if(dim(topVarFeature2)[1]<n)
    warning(paste0("The cutoff was too strict for up regulated features, only ", dim(topVarFeature2)[1] ,"  variables were found in the result"))

  if(dim(topVarFeature1)[1]==0) warning(paste0("No down regulated features was found"))

  if(dim(topVarFeature2)[1]==0) warning(paste0("No up regulated features was found"))

  topVarFeature<-c(as.character(topVarFeature1$target)[1:n],
                   as.character(topVarFeature2$target)[1:n])
  topVarFeature<-topVarFeature[!is.na(topVarFeature)]
  return(topVarFeature)
}
