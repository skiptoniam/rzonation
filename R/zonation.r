#'Run the program zonation from R
#'
#'Runs the zonation software for conservation planning on a set of GeoTiff files
#'and returns the output as a list.
#'
#'@param features file paths of the GeoTiff files for features in the conservation plan.
#'
#'@export

zonation                                                                      <-
  function(features)                                                           {

  zp                                                                          <-
    base::getOption('rzonation.path')                                          ;

  if (!base::nzchar(zp))                                                       {
     base::stop('zonation binary not found')                                 ;};

  dir                                                                         <-
    base::tempdir()                                                            ;

  datfile                                                                     <-
    base::tempfile(tmpdir = dir)                                               ;

  base::paste(
    '[Settings]',
    'removal rule = 1',
    'warp factor = 1000',
    'edge removal = 1',
    'add edge points = 0',
    'annotate name = 0',
    sep = '\n'
  )                                                                          %>%
  base::cat(file = datfile)                                                    ;

  spfile                                                                      <-
    base::tempfile(tmpdir = dir)                                               ;

  features                                                                   %>%
  base::paste0('1 1 1 1 1 ', ., '\n', collapse = '')                         %>%
  base::cat(file = spfile)                                                     ;

  resstem                                                                     <-
    base::tempfile(tmpdir = dir)                                               ;

  base::paste(
    base::getOption('rzonation.path'),
    '-r',
    datfile,
    spfile,
    resstem,
    '0.0 0 1.0 1'
  )                                                                          %>%
  base::system(ignore.stdout = TRUE)                                           ;

  features_info                                                               <-
    base::paste0(resstem, '.features_info.txt')                              %>%
    readr::read_tsv(
      file      = .,
      col_names = base::c(
                    'weight',
                    'dist_sum',
                    'ig_retain',
                    't_viol_fract_rem',
                    'dist_mean_x',
                    'dist_mean_y',
                    'map_file_name'
                  ),
      col_types = 'cdddddc',
      skip      = 2
    )                                                                        %>%
    dplyr::mutate(
      weight = base::as.numeric(x = weight)
    )                                                                          ;

  nfeatures                                                                   <-
    features                                                                 %>%
    base::length(x = .)                                                        ;

  curves                                                                      <-
    readr::read_table(
      file      = base::paste0(resstem, '.curves.txt'),
      col_names = base::c(
                    'prop_landscape_lost',
                    'cost_need_for_top_frac',
                    'min_prop_rem',
                    'ave_prop_rem',
                    'w_prop_rem',
                    'ext_1',
                    'ext_2',
                    base::paste0(
                      'prop_',
                      tools::file_path_sans_ext(x = x),
                      '_rem'
                    )
                  ),
      col_types = base::paste0(
                               'didddddd',
                               base::rep(
                                 x     = 'd',
                                 times = nfeatures
                               ),
                    collapse = ''
                  ),
      skip      = 1
    )                                                                          ;

  rasters                                                                     <-
    resstem                                                                  %>%
    base::basename(path = .)                                                 %>%
    base::list.files(path = dir, pattern = ., full.names = TRUE)             %>%
    base::grep(pattern = '\\.tif$', x = ., value = TRUE)                     %>%
    raster::stack(x = .)                                                     %>%
    magrittr::set_names(
      value = base::c('rank', 'wrscr')
    )                                                                        %>%
    raster::readAll(object = .)                                                ;

  run_info                                                                    <-
    readr::read_file(
      file = base::paste0(resstem, '.run_info.txt')
    )                                                                          ;

  base::list(
    features_info = features_info,
    curves        = curves,
    rasters       = rasters,
    run_info      = run_info
  )                                                                          ;};

utils::globalVariables('weight')                                               ;

