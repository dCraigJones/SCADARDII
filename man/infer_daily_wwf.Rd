% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/SSOAP.R
\name{infer_daily_wwf}
\alias{infer_daily_wwf}
\title{Calculate Wet-Weather Flow (WWF).}
\usage{
infer_daily_wwf(date, flow, rain)
}
\arguments{
\item{date}{vector of date for flow and rain data}

\item{flow}{vector of flow data, in GPD}

\item{rain}{vector of rain, in inches}
}
\value{
vector of flow minus DWF
}
\description{
Calculate Wet-Weather Flow (WWF).
}
\examples{
data(DF)
infer_daily_wwf(DF$date, DF$Buffalo, DF$rain)
}
