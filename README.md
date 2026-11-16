# Time Lag Between Locations

MoveApps

Github repository: https://github.com/movestore/TimeLag_BetweenLocations

## Description
Calculates the time lag between consecutive locations of each track and adds it to the data (in seconds). Adds the median time lag per individual to the track data and provides histograms, violin plots (to discover multiple sampling settings of a tag) and a summary table, in a unit of choice.

## Documentation
This App calculates the time lag between each pair of consecutive locations of a track. The time lag is a segment characteristic and is assigned to the first location of each segment. Therefore the time lag of the last location of each track is set to NA.

A column named `timelag` is appended to the event data that is returned for further use in the next Apps. The time lags in this column are **always in seconds**, independent of the unit selected in the settings, and the unit (`s`) is stored together with the values.

The median time lag per individual is added to the track data table as `median_timelag`, also **always in seconds**. It represents the typical interval between consecutive recorded locations and provides a robust summary of the realised sampling frequency because it is less affected by occasional long gaps than the mean. Knowing the median time lag helps researchers assess the typical sampling frequency of each tag and choose realistic recording or resampling intervals for future analyses and deployments.

Histograms of the time lag distribution of all individuals together and of each individual are created automatically and can be downloaded as a PDF. Each histogram shows the median time lag as a dashed line, and its value in the subtitle. In addition, violin plots compare the time lag distributions of all individuals side by side, with the median of each individual marked as a red point. Several humps in a violin can reveal that a tag was recording with more than one sampling setting (e.g. high-resolution bursts in between a lower regular fix rate). Optionally, a maximum time lag can be set: longer time lags are then not shown in the histograms and violin plots, so that a few long gaps do not hide the distribution of the frequent, shorter time lags. These time lags are only left out of the plots, never removed from the data. The unit used in all plots can be chosen in the settings; it only changes how the time lags are displayed, not the values stored in the output data.

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group.

#### Required data properties
The App should work for any kind of location data. A time lag can only be calculated for tracks with at least two locations.

### Input type
`move2::move2_loc`

### Output type
`move2::move2_loc`

### Artefacts
`timelag_histogram.pdf`: PDF with histograms of the time lags. If the data contain more than one individual, the first page shows all individuals together, followed by one page per individual (sorted by track ID). If the data contain one individual, the PDF contains only the page of that individual. Each histogram shows the median time lag as a dashed line, with its value in the subtitle. The x-axis and the median are shown in the unit selected in the setting `Units of the plots`. If `Maximum time lag shown in the plots` is set, every histogram has the same x-axis from 0 to this value, or to the longest time lag if that is shorter (100 bins of equal width), and the subtitle states how many time lags are not shown.

`timelag_violin.pdf`: PDF with one page of violin plots of the time lags, one violin per individual (sorted by track ID), with a boxplot inside (without outlier points). The violins are drawn horizontally: one row per individual (the first track ID at the top), with the time lag on the x-axis and the track ID written to the left of each violin. The median of each individual is marked on its violin with a red point, with its value (number only) written just above the violin; the legend at the top right ("Median [unit]") gives the unit of these values. The page is 11 inches wide and grows in height with the number of individuals, so that long track IDs stay readable also with many individuals. The time lag axis and the medians are shown in the unit selected in `Units of the plots`. If `Maximum time lag shown in the plots` is set, only the time lags up to this value are drawn, and the subtitle states how many are not shown.

`timelag_summary.csv`: table with one row per individual (sorted by track ID), to download without R. Columns: the track ID (named like the track ID column of the data), `n_locations` (number of locations), `n_timelags` (number of time lags, i.e. locations − 1), `median_timelag_s` (median time lag in seconds, identical to `median_timelag` in the track data), `median_timelag_<unit>`, `min_timelag_<unit>` and `max_timelag_<unit>` (median, shortest and longest time lag in the unit selected in `Units of the plots`, e.g. `median_timelag_h`), and, only if `Maximum time lag shown in the plots` is set, `n_timelags_above_max_lag` (number of time lags not shown in the plots). All values are calculated from all time lags, also those not shown in the plots. Individuals with only one location have `n_timelags` = 0 and NA in the time lag columns.

In both PDFs the medians are always calculated from all time lags, also those not shown, so they are identical to `median_timelag`: there is one definition of the median everywhere in the App. When time lags are not shown, the subtitles say so ("... not shown (the median(s) include them)"). For the same reason, the boxplots in the violin plot do not draw their own median line (ggplot would calculate it from the plotted time lags only); the red point is the only median shown. If a median is larger than the maximum time lag shown, its value is still given in the text, but no dashed line is drawn in the histogram and no point in the violin plot; in the violin plot the value is then written at the right end of the row, marked "(beyond axis)".

### Settings
`Units of the plots` (units): Unit in which the time lags and the median time lag are displayed in the histograms (`timelag_histogram.pdf`) and the violin plots (`timelag_violin.pdf`). This setting only affects the plots; the columns `timelag` and `median_timelag` in the output data are always in seconds. Available units are: `Seconds` (s), `Minutes` (min), `Hours` (h), `Days` (d), `Weeks` (weeks), `Month` (month) and `Years` (years). Default: `Minutes`.

`Maximum time lag shown in the plots` (max_lag): Optional maximum time lag, in the unit selected in `Units of the plots`, e.g. `400` with unit `Hours` means 400 h. Time lags above this value are not drawn in the histograms and violin plots, which improves the view of the frequent, shorter time lags when a few long gaps stretch the axis. **This only affects the plots: no time lags are removed from the data**, and the columns `timelag` and `median_timelag` and the medians shown in the plots always include all time lags. Each plot states how many time lags are not shown. Default: empty (all time lags are plotted).

### Changes in output data
The App adds to the event data the column `timelag`. It contains the time lag from each location to the next location of the same track, always in seconds (unit `s`, stored in the column with the `units` package), regardless of the unit selected for the plots. To use another unit downstream, convert it, e.g. `units::set_units(data$timelag, "h")`. The last location of each track has the value NA.

**Note for users of earlier versions of this App:** in earlier versions, the column `timelag` was stored in the unit selected in the setting `Units`. Since this version, `timelag` (and the new `median_timelag`) are **always in seconds**, and the unit setting only affects the plots. Workflows or subsequent Apps that use the plain numeric values of `timelag` (e.g. `as.numeric(timelag)` or a fixed threshold) need to be adapted; code that works with the stored unit (`units` package) is not affected.

The App adds to the track data table the column `median_timelag`. It contains the median of the time lags of each individual, always in seconds (unit `s`).

All other data remain unchanged.

### Errors and null handling
**Input data:** The full input data set, with the added columns, is returned for further use in the next App. The input data cannot be empty.

**Tracks with only one location:** No time lag can be calculated. The `timelag` and `median_timelag` values of this track are NA, its histogram page shows a message instead of bars and "Median: NA", it gets no violin, and its row in `timelag_summary.csv` has `n_timelags` = 0 and NA in the time lag columns.

**Long gaps in the data:** Rare long time lags (e.g. days without recorded locations) stretch the x-axis of the histograms, so the bars of the shorter, more frequent time lags can appear compressed at the left. The same happens to the y-axis of the violin plots. Use the setting `Maximum time lag shown in the plots` to leave them out of the plots. These long time lags are real gaps in the tracking data and are never removed from the data by the App. They do not affect the median.

**Maximum time lag hides all time lags:** If all time lags of an individual are above `Maximum time lag shown in the plots`, its histogram page shows a message instead of bars. If this is the case for all individuals, `timelag_violin.pdf` shows a message instead of a plot. Individuals with fewer than two time lags up to this value get no violin (a violin needs at least two values).

### Technical details
- The time lags are calculated with `mt_time_lags()` from the `move2` package. Units are handled with the `units` package, so the unit is stored together with the values.
- The time lags and the median are always calculated and stored in seconds. For the plots they are converted to the selected unit with `units::set_units()`.
- The units `Month` and `Years` are average lengths (a month is about 30.4 days, a year about 365.25 days).
- The median is calculated per individual, ignoring the NA of the last location of each track.
- The histograms are created with `ggplot2` using 100 bins over the range of the time lags.
- The violin plots are created with `ggplot2` (`geom_violin()` scaled to equal width, with `geom_boxplot()` inside) and coloured per individual with the viridis palette. The PDF gets wider with more individuals so that the labels stay readable.