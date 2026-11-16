library("move2")
library("ggplot2")
library("units")

## Plot colours
barFill   <- "#3182BD"   # blue bars (individuals)
allFill   <- "#08519C"   # darker blue bars (all individuals)
medColour <- "#E6550D"   # orange median line and label
stripFill <- "#DEEBF7"   # light blue panel header

## Helper: median of a time lag vector, keeping its unit
medianLag <- function(timelag) {
  m <- median(as.numeric(timelag), na.rm = TRUE)
  units(m) <- units(timelag)
  m
}

## Helper: text telling how many time lags are above the cutoff and not plotted
hiddenText <- function(nHidden, maxLag, plotUnit) {
  if (nHidden == 0) return(NULL)
  paste0(nHidden, " time lag", if (nHidden > 1) "s", " > ", maxLag, " ",
         plotUnit, " not shown")
}

## Helper: styled histogram of time lags with the median as a dashed line.
## 'tl': time lags already converted to 'plotUnit' (may contain NAs).
## 'cutoff': NULL or a units value; time lags above it are not plotted.
## The median is always calculated from all time lags, not only the plotted ones.
## 'axisMax': numeric upper end of the x-axis (in 'plotUnit'), used when a
## cutoff is set so that all pages share the same axis and bins.
histWithMedian <- function(tl, track, plotUnit, cutoff = NULL, maxLag = NULL,
                           axisMax = NULL, fill = barFill) {
  med <- medianLag(tl)
  keep <- !is.na(tl)
  nHidden <- 0
  if (!is.null(cutoff)) {
    nHidden <- sum(keep & tl > cutoff)
    keep <- keep & tl <= cutoff
  }
  plotData <- data.frame(timelag = tl[keep], track = rep(track, length.out = sum(keep)))
  subtitle <- paste0("Median: ", signif(as.numeric(med), 3), " ", plotUnit)
  if (nHidden > 0) subtitle <- paste0(subtitle, "   |   ", hiddenText(nHidden, maxLag, plotUnit),
                                      if (nHidden > 1) " (the median includes them)" else " (the median includes it)")
  ## nothing left to plot (no time lags, or all above the cutoff): message page
  if (nrow(plotData) == 0) {
    msg <- if (nHidden > 0) paste0("All time lags are > ", maxLag, " ", plotUnit)
           else "No time lags available"
    return(ggplot(data.frame(track = track)) +
             annotate("text", x = 0, y = 0, label = msg, size = 5, colour = "grey30") +
             labs(subtitle = subtitle) +
             theme_void(base_size = 12) +
             theme(plot.title       = element_text(face = "bold", size = 15),
                   plot.subtitle    = element_text(colour = medColour, face = "bold"),
                   strip.background = element_rect(fill = stripFill, colour = NA),
                   strip.text       = element_text(face = "bold", size = 12)))
  }
  ## median line only if it lies inside the plotted range
  showMed <- !is.na(med) && (is.null(cutoff) || med <= cutoff)
  p <- ggplot(plotData, aes(timelag))
  if (is.null(cutoff)) {
    p <- p + geom_histogram(bins = 100, fill = fill, colour = "white", linewidth = 0.1)
  } else {
    ## with a cutoff: same x-axis (0 to axisMax) and same 100 bins on every page
    p <- p +
      geom_histogram(binwidth = axisMax / 100, boundary = 0,
                     fill = fill, colour = "white", linewidth = 0.1) +
      coord_cartesian(xlim = c(0, axisMax))
  }
  if (showMed) {
    p <- p + geom_vline(xintercept = med, colour = medColour,
                        linetype = "dashed", linewidth = 0.8)
  }
  p +
    scale_y_continuous(expand = expansion(mult = c(0, 0.05))) +
    labs(x = "Time lag", y = "Number of time lags", subtitle = subtitle) +
    theme_minimal(base_size = 12) +
    theme(plot.title         = element_text(face = "bold", size = 15),
          plot.subtitle      = element_text(colour = medColour, face = "bold"),
          axis.title         = element_text(colour = "grey30"),
          axis.line.x        = element_line(colour = "grey40"),
          panel.grid.minor   = element_blank(),
          panel.grid.major.x = element_blank(),
          strip.background   = element_rect(fill = stripFill, colour = NA),
          strip.text         = element_text(face = "bold", size = 12))
}

## Helper: violin + boxplot of the time lags per track, in 'plotUnit'.
## 'lags' is a data.frame with columns 'track' and 'TL' (units, no NAs).
## 'cutoff': NULL or a units value; time lags above it are not plotted.
## The violins are always horizontal: one row per track (sorted by track ID,
## first ID at the top), the time lag on the x-axis, and the track ID on the
## left. The median of each track is marked on its violin with a red point and
## its value (number only) written just above it; a legend explains that the
## red point is the median, with the unit. The median is calculated from all
## time lags of the track, not only the plotted ones; if it is larger than
## the cutoff, its value is written at the right end of the row instead.
## One definition of the median everywhere: the red point is the only median
## shown (identical to 'median_timelag'); the boxplot's own median line, which
## ggplot would compute from the plotted time lags only, is not drawn.
violinPlot <- function(lags, plotUnit, cutoff = NULL, maxLag = NULL) {
  ids <- sort(unique(lags$track))
  lags$label <- factor(lags$track, levels = rev(ids))
  ## fixed colour per track, also if all time lags of a track are above the cutoff
  lags$track <- factor(lags$track, levels = ids)
  med <- tapply(as.numeric(lags$TL), lags$track, median)[ids]
  medDf <- data.frame(label = factor(ids, levels = rev(ids)), med = med,
                      text = as.character(signif(med, 3)))
  medLegend <- paste0("Median [", plotUnit, "]")
  title <- "Time lag distribution per individual"
  subtitle <- NULL
  if (!is.null(cutoff)) {
    nHidden <- sum(lags$TL > cutoff)
    lags <- lags[lags$TL <= cutoff, , drop = FALSE]
    title <- paste0(title, " (time lags up to ", maxLag, " ", plotUnit, ")")
    subtitle <- hiddenText(nHidden, maxLag, plotUnit)
    if (!is.null(subtitle)) subtitle <- paste0(subtitle, if (nHidden > 1) " (the medians include them)" else " (the medians include it)")
  }
  ## medians inside the plotted range get a point; the others only a text at
  ## the right end of the row
  axisEnd <- max(as.numeric(lags$TL))
  inside <- is.null(cutoff) | medDf$med <= axisEnd
  medDf$textPos <- ifelse(inside, medDf$med, axisEnd)
  medDf$hjust <- ifelse(inside, 0.5, 1)
  medDf$text[!inside] <- paste0(medDf$text[!inside], " (beyond axis)")
  medDf$med <- set_units(medDf$med, plotUnit, mode = "standard")
  medDf$textPos <- set_units(medDf$textPos, plotUnit, mode = "standard")
  p <- ggplot(lags, aes(x = label, y = TL)) +
    ## violins slightly thinner than the row, so the median value fits in the
    ## white gap above each violin
    geom_violin(aes(fill = track), scale = "width", width = 0.7) +
    geom_boxplot(aes(fill = track), width = 0.2, colour = "grey30", alpha = 0.2,
                 outliers = FALSE, median.colour = NA) +
    geom_point(data = medDf[inside, , drop = FALSE],
               aes(x = label, y = med, colour = medLegend),
               size = 2.8, inherit.aes = FALSE) +
    geom_text(data = medDf, aes(x = label, y = textPos, label = text, hjust = hjust),
              position = position_nudge(x = 0.42), size = 3.2,
              colour = "red", inherit.aes = FALSE) +
    scale_fill_viridis_d(drop = FALSE) +
    scale_colour_manual(values = setNames("red", medLegend), name = NULL) +
    guides(fill = "none") +
    labs(title = title, subtitle = subtitle, x = NULL, y = "Time lag") +
    coord_flip() +
    theme_bw() +
    theme(legend.position      = "top",
          legend.justification = "right",
          legend.margin        = margin(0, 0, 0, 0),
          legend.text          = element_text(size = 10),
          plot.title           = element_text(size = 11),
          plot.subtitle        = element_text(size = 10, colour = "grey30"))
  p
}

## 'units' is the unit used for the plots only. The 'timelag' and
## 'median_timelag' columns added to the data are always in seconds.
## 'max_lag' (optional, in 'units'): time lags above this value are not shown
## in the plots (histograms and violin plots). They are NOT removed from the data.
rFunction <- function(data, units = "min", max_lag = NULL, ...) {
  plotUnit <- units

  ## Time lag between consecutive locations, assigned to the first location of
  ## each segment (last location of each track is NA). Always stored in
  ## seconds (class "units", unit "s"), independent of the selected plot unit.
  data$timelag <- mt_time_lags(data, "s")
  logger.info(paste0("Time lags calculated in seconds for ",
                     mt_n_tracks(data), " track(s)."))

  ## Median time lag per track, added to the track data table in seconds
  trackIdCol <- mt_track_id_column(data)
  medLag <- tapply(as.numeric(data$timelag), as.character(mt_track_id(data)),
                   median, na.rm = TRUE)
  trackData <- mt_track_data(data)
  medianTimelag <- as.numeric(medLag[as.character(trackData[[trackIdCol]])])
  units(medianTimelag) <- "s"
  trackData$median_timelag <- medianTimelag
  data <- mt_set_track_data(data, trackData)
  logger.info("Column 'median_timelag' (in seconds) added to the track data table.")

  ## Time lags in the plot unit, and the optional plotting cutoff
  tlPlot <- set_units(data$timelag, plotUnit, mode = "standard")
  trackIds <- as.character(mt_track_id(data))
  cutoff <- NULL
  axisMax <- NULL
  if (!is.null(max_lag) && length(max_lag) == 1 && !is.na(max_lag)) {
    cutoff <- set_units(as.numeric(max_lag), plotUnit, mode = "standard")
    ## histogram x-axis ends at the cutoff, or at the longest time lag if that
    ## is shorter, so the axis is not stretched beyond the data
    shown <- as.numeric(tlPlot)[!is.na(tlPlot) & tlPlot <= cutoff]
    axisMax <- if (length(shown) > 0 && max(shown) > 0) min(as.numeric(cutoff), max(shown))
               else as.numeric(cutoff)
    nAbove <- sum(!is.na(tlPlot) & tlPlot > cutoff)
    logger.info(paste0("Plots only show time lags <= ", max_lag, " ", plotUnit,
                       "; ", nAbove, " time lag(s) above this value are not plotted ",
                       "but remain in the data."))
  }
  logger.info(paste0("Plots are shown in '", plotUnit, "'."))

  ## Histogram artefact: all individuals (only if more than one track),
  ## followed by one page per individual; median shown on each plot
  pdf(appArtifactPath("timelag_histogram.pdf"), width = 8, height = 5.5)
  if (mt_n_tracks(data) > 1) {
    print(histWithMedian(tlPlot, "All", plotUnit, cutoff, max_lag, axisMax,
                         fill = allFill) +
            ggtitle("All Individuals"))
  }
  for (id in sort(unique(trackIds))) {
    sel <- trackIds == id
    print(histWithMedian(tlPlot[sel], id, plotUnit, cutoff, max_lag, axisMax) +
            facet_grid(~ track))
  }
  dev.off()

  ## Violin plot artefact: one violin per individual.
  ## Violins are always horizontal, one row per track; the page is 11 inches
  ## wide and grows in height with the number of tracks.
  lags <- data.frame(track = trackIds, TL = tlPlot)
  lags <- lags[!is.na(lags$TL), , drop = FALSE]
  nViolin <- length(unique(lags$track))
  pdf(appArtifactPath("timelag_violin.pdf"),
      width = 11, height = max(5, 1.5 + 0.55 * nViolin))
  if (nrow(lags) == 0) {
    logger.info("No time lags to plot; the violin plot PDF is empty.")
    plot.new(); text(0.5, 0.5, "No time lags available")
  } else if (!is.null(cutoff) && !any(lags$TL <= cutoff)) {
    logger.info(paste0("No time lags <= ", max_lag, " ", plotUnit, "; nothing to plot."))
    plot.new(); text(0.5, 0.5, paste("No time lags up to", max_lag, plotUnit))
  } else {
    print(violinPlot(lags, plotUnit, cutoff, max_lag))
  }
  dev.off()

  ## Summary table artefact: one row per track (sorted by track ID), with the
  ## median in seconds (identical to 'median_timelag') and in the plot unit.
  ## Always calculated from all time lags, independent of 'max_lag'.
  tlS   <- as.numeric(data$timelag)
  tlU   <- as.numeric(tlPlot)
  ids   <- sort(unique(trackIds))
  safe  <- function(f, x) if (all(is.na(x))) NA_real_ else f(x, na.rm = TRUE)
  summ  <- data.frame(
    id          = ids,
    n_locations = as.integer(table(trackIds)[ids]),
    n_timelags  = sapply(ids, function(i) sum(!is.na(tlS[trackIds == i]))),
    median_s    = sapply(ids, function(i) safe(median, tlS[trackIds == i])),
    median_u    = sapply(ids, function(i) safe(median, tlU[trackIds == i])),
    min_u       = sapply(ids, function(i) safe(min,    tlU[trackIds == i])),
    max_u       = sapply(ids, function(i) safe(max,    tlU[trackIds == i])),
    row.names = NULL
  )
  names(summ) <- c(trackIdCol, "n_locations", "n_timelags", "median_timelag_s",
                   paste0(c("median_timelag_", "min_timelag_", "max_timelag_"), plotUnit))
  if (!is.null(cutoff)) {
    summ$n_timelags_above_max_lag <- sapply(ids, function(i)
      sum(!is.na(tlU[trackIds == i]) & tlU[trackIds == i] > as.numeric(cutoff)))
  }
  write.csv(summ, appArtifactPath("timelag_summary.csv"), row.names = FALSE)
  logger.info("Summary table 'timelag_summary.csv' written (one row per track).")

  return(data)
}
