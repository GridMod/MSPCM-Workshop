# Copy interval generation for ramping analysis

if(!'Type' %in% names(interval.generation)){
  interval.generation[, Type:=gen.type.mapping[name]]
}
setkey(interval.generation,name,Type,scenario)
if(!'Type' %in% names(total.installed.cap)){
  total.installed.cap[, Type:=gen.type.mapping[name]]
}
setkey(total.installed.cap,name,Type,scenario)
interval.ramp.data = merge(interval.generation[,.(scenario, name, Type, generation=value, time)],
                           total.installed.cap[,.(scenario, name, Type, capacity=value)], by=c('name','Type','scenario'))
interval.ramp.data[, day:=as.POSIXlt(time)[[8]]]


# Plotting functions
ramp_plot <- function(df,facet_scen=TRUE,facet_cols=3) {
  
  if (facet_scen){
    p <- line_plot(df,c('scenario','Type','day'),'day','ramp',y.lab='Ramp',color = 'Type')
    p <- p + facet_wrap(~scenario,ncol=facet_cols)
  } else{
    p <- line_plot(df,c('scenario','Type','day'),'day','ramp',y.lab='Ramp',color = 'Type', linetype='scenario')
    p <- p + facet_wrap(~Type,ncol=facet_cols)
  }
  p <- p + scale_color_manual(values=gen.color)
  
  return(p)
}


# Calculate ramping as the range by day
ramp.day.gen <- interval.ramp.data[, .(ramp=(max(generation)-min(generation))/max(capacity), capacity=max(capacity)), 
                                   by=.(scenario,name,Type,day)]
ramp.day <- ramp.day.gen[, .(ramp=sum(ramp*capacity)/sum(capacity)), by=.(scenario,Type,day)]
ramp_plot(ramp.day,FALSE) + ylab('Ramp, Fraction of Capacicty')


# Calculate ramping as the max change in an hour
ramp.hour.gen <- interval.ramp.data[, .(ramp=max(diff(generation))/max(capacity), capacity=max(capacity)), 
                                    by=.(scenario,name,Type,day)]
ramp.hour <- ramp.hour.gen[, .(ramp=sum(ramp*capacity)/sum(capacity)), by=.(scenario,Type,day)]
ramp_plot(ramp.hour) + ylab('Ramp, Daily average Fraction\nof Capacity per hour')


# Calculate ramping as the coefficient of variance
ramp.var.gen <- interval.ramp.data[, .(ramp=sd(generation)/mean(generation)*100,capacity=max(capacity)), 
                                   by=.(scenario,name,Type,day)]
ramp.var.gen[is.na(ramp), ramp:=0]
ramp.var <- ramp.var.gen[, .(ramp=sum(ramp*capacity)/sum(capacity)), by=.(scenario,Type,day)]
ramp_plot(ramp.var,FALSE,5)


