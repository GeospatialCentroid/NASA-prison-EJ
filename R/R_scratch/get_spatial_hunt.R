function (url, out_fields = c("*"), where = "1=1", token = "", 
          sf_type = NULL, head = FALSE, ...) {
  layer_info <- jsonlite::fromJSON(httr::content(httr::POST(url, 
                                                            query = list(f = "json", token = token), encode = "form", 
                                                            config = httr::config(ssl_verifypeer = FALSE)), as = "text"))
  if (is.null(sf_type)) {
    if (is.null(layer_info$geometryType)) 
      stop("return_geometry is NULL and layer geometry type \n(e.g. ", 
           "'esriGeometryPolygon' or ", "'esriGeometryPoint' or ", 
           "'esriGeometryPolyline' ", ")\ncould not be infered from server.")
    sf_type <- layer_info$geometryType
  }
  query_url <- paste(url, "query", sep = "/")
  esri_features <- get_esri_features(query_url, out_fields, 
                                     where, token, head, ...)
  simple_features <- esri2sfGeom(esri_features, sf_type)
  return(simple_features)
}
