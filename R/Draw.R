draw_daily_summary <- function(date, flow, rain) {
  Max.Daily.Flow = ceiling(max(flow)/1e3)

  layout(matrix(c(1,2,3,4,4,4), ncol=2, byrow = FALSE), widths=c(1,3))


  dwf <- infer_daily_dwf(date, flow, rain)

  barplot(c(dwf$weekend, dwf$weekday)/1e3
          , main="DWF"
          , names.arg=c("wkend", "wkday")
          #, names.arg=paste(prettyNum(round(c(DWF$weekday, DWF$weekend)/1e3,0), big.mark = ","), "kGPD")
          , col=c("grey90", "white")
          , horiz=TRUE
          , xlab="Daily Flow (kGPD)"
  )
  box(bty="l")

  gwi <- infer_daily_gwi(date, flow, rain)
  gwi <- gwi[gwi>0]
  plot(density(gwi/1e3)
       , main="GWI"
       , xlab="kGPD"
       , lwd=2
       , bty="l"
       , ylab="density"
       , axes=F
  )
  axis(1)

  # R <- rain[Ev]
  # I <- apply(H,1,max)*R
  # fit <- lm(I/1e3~R)
  # r2 <- round(cor(R,I),2)
  # Rt <- round(coef(fit)[2],2)
  #
  # plot(R,I/1e3
  #      , main="RDII"
  #      , xlim=c(0,6)
  #      , ylim=c(0,Rt*6)
  #      , cex=1.5
  #      , pch=4
  #      , lwd=2
  #      , ylab="kGPD/inch"
  #      , xlab="Rain (inch)"
  #      , bty="l"
  # )
  # abline(fit, lty=2)
  #
  uh <- infer_daily_hydrograph(date, flow, rain)

  plot(uh/1e3
       , xlim=c(1,21)
       , type="l"
       , lwd=2
       #, cex=1
       #, pch=1
       , xlab="days"
       , ylab="RDII (kGPD/Inch)"
       , bty="l"
       )

  title("RDII")

  par(mar=c(6,5,3,5)) #Btm, Left, Top, Right
  plot(date, flow/1e3
       , lwd=1
       , type="l"
       , xaxs="i"
       , yaxs="i"
       , xlab=NA
       , ylab="Daily Flow (kGPD)"
       , axes=FALSE
       , ylim=c(0,Max.Daily.Flow)
  )

  lines(date, rain*Max.Daily.Flow/10, type="h", col="blue", lwd=2)

  # Axis Label - Month/Year
  Month <- c("J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D")

  dd <- date[which(lubridate::day(date)==1)]
  dl <- Month[lubridate::month(dd)]

  axis(1, at=dd, labels=dl)

  yd <- which(lubridate::yday(date)==1)
  yl <- lubridate::year(date[yd])

  axis(1, at=date[yd], labels=yl, line=2, lwd=0)

  # Axis Labels - Daily Flow/Rain
  axis(2)
  axis(4, at=seq(0,Max.Daily.Flow,length.out=6), labels=seq(0,10,2))

  mtext("Rain (inches)", side=4, line=3, cex=0.7)


  box(lwd=1)

  # Reference Lines
  # mdwf <- (dwf$weekday+dwf$weekend)/2
  # MA <- unname(max(dwf)+quantile(gwi,0.9)+Rt*5*1e3)
  # Jax5YR <- unname(max(dwf)+quantile(gwi,0.9)+Rt*6.5*1e3)
  # Jax25YR <- unname(max(dwf)+quantile(gwi,0.9)+Rt*9.5*1e3)
  # q75th <- as.numeric(quantile(rain[rain>0.5],0.75)*Rt+dwf[1]/1e3+quantile(gwi,0.75)/1e3)*1e3
  # abline(h=c(mdwf, q75th, MA, Jax5YR, Jax25YR)/1e6, lty=2)
  # axis(2, at=c(mdwf, q75th, MA, Jax5YR, Jax25YR)/1e6, labels=c("dwf", "3Q", "2YR", "5YR", "25YR"), line=1, lwd=0)
  # axis(4, at=c(mdwf, q75th, MA, Jax5YR, Jax25YR)/1e6, labels=c("dwf", "3Q", "2YR", "5YR", "25YR"), line=1, lwd=0)

  legend("top"
         , c("Flow", "Rain")
         , lwd=c(2,2)
         , lty=c(1,1)
         , col=c("black", "blue")
         , inset=c(0.05,0.05)
         , seg.len = 4
         , pch=c(NA,NA)
         , cex=1.0
         , y.intersp=1.0
         , bty = "n"
         , box.col=rgb(1,1,1,0.75)
         , bg=rgb(1,1,1,0.75)
         , horiz=FALSE
         , text.font=2
  )

  #Get.Summary(date, flow, rain, H)

  #return(H)
}

draw_model_qaqc <- function(df) {

  raw <- df %>%
    dplyr::select(date, all=flow, gwi, rdi) %>%
    pivot_longer(-date, names_to="measure", values_to="raw")

  mdl <- df %>%
    dplyr::select(date, all=model, gwi=gwi_model, rdi=rdi_model) %>%
    pivot_longer(-date, names_to="measure", values_to="model")

  tmp <- raw %>%
    left_join(mdl, by=c("date", "measure"))

  tmp %>%
    ggplot(aes(date, raw)) +
    geom_line() +
    geom_line(aes(y=model), col="red") +
    facet_grid(measure ~ ., scales="free_y") +
    labs(x="", y="flow (gpd)")
}

draw_qq <- function(field, model, units="psi", error=0.10, minVal=2) {
    fx <- quantile(field, probs=(2:99/100))
    my <- quantile(model, probs=(2:99/100))

    qqplot(fx, my
           , xlab=paste0("field (", units,")")
           , ylab=paste0("model (", units,")")
           , pch=4
    )
    x <- seq(min(0,10*min(fx, my)),10*max(fx,my),length.out=100)

    yy1 <- error*x+x
    yy2 <- -error*x+x

    zz1 <- x+minVal
    zz2 <- x-minVal

    df <- cbind(yy1, yy2, zz1, zz2)
    yy1 <- apply(df, 1, min)
    yy2 <- apply(df, 1, max)

    polygon(
      c(x,rev(x))
      , c(yy1, rev(yy2))
      , col=rgb(0.25,0.25,0.25,0.25)
      , border=NA
    )

    abline(a=0, b=1, lwd=1, lty=2, col="blue")

    box(lwd=2)

    res <- as.numeric(abs(my-fx))
    mpe <- as.numeric(res/fx)

    pts_failed <- sum(res>minVal & mpe>error)

    subtitle <- paste0(round(error*100,0), "% error or ", minVal ," ", units, " (", 100-pts_failed, "% pass)")

    title(sub=subtitle, adj=1, cex.sub=0.75)
}

draw_diurnal <- function(diurnal) {
  plot(diurnal
   , axes=F
   , xlab=""
   , ylab="BSF (gpm)"
   , type="l"
   , lwd=2
   )
  axis(2)
  axis(1, at=1:7, labels=c("S", "M", "T", "W", "T", "F", "S"))
  box(lwd=2)

}

draw_gwi <- function(datetime, gwi) {
  datetime <- hf$datetime
  gwi <- hf$gwi

  tmp <- data.frame(datetime, gwi)

  use <-   tmp %>% mutate(wk=week(datetime))

  tmp <- tmp %>%
    mutate(wk=week(datetime)) %>%
    group_by(wk) %>%
    summarize(gwi_wk=mean(gwi, na.rm=TRUE)) %>%
    right_join(use, by="wk")

  plot(datetime
   , rollapply(tmp$gwi_wk, 14*24, mean, na.rm=TRUE, fill=NA)
   , type="l"
   , ylab="GWI (gpm)"
   , xlab=""
   , lwd=2
  )

  box(lwd=2)

}

draw_hydrograph <- function(uh, P=7.56) {
  tmp <- model_hydrograph(SCS_6_hr*7.56, uh)

  plot(0:23, tmp[1:24]
    , xlab="time (hrs)"
    , ylab="RDI (gpm)\n25-year 6-hour"
    , type="l"
    , lwd=2
    , axes=FALSE
  )
  axis(2)
  axis(1, at=seq(0,24,6))
  box(lwd=2)

}

draw_ii <- function(datetime, flow, gwi, model, diurnal, uh, STATION_NAME="") {
    layout(matrix(c(1,1,2,2,3,4), nrow=3, byrow=TRUE))
    par(mar=c(1,5,2,2))
    draw_diurnal(diurnal)
    title(STATION_NAME, adj=0)
    draw_gwi(datetime, gwi)
    par(mar=c(5,5,2,2))
    draw_hydrograph(uh)
    draw_qq(flow, model, "gpm", 0.1, 25)
}
