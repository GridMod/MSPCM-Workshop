#--------------------------------------------------------------------------------------
# Set up ramp data
#--------------------------------------------------------------------------------------

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


#--------------------------------------------------------------------------------------
# Plotting functions
#--------------------------------------------------------------------------------------
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

ramp_boxplot <- function(df){
  p <- ggplot(df,aes(Type,ramp,color=scenario)) + geom_boxplot() +
    scale_color_brewer(palette='Set1',name='') +
    xlab("") + ylab("Ramp") +
    theme( legend.key =       element_rect(color = "grey80", size = 0.4),
           legend.key.size =  grid::unit(0.9, "lines"),
           legend.text =      element_text(size=text.plot/1.1,face = 'bold'),
           axis.text =        element_text(size=text.plot/1.2,face = 'bold'),
           axis.text.x =      element_text(hjust = 0, angle=-35),
           axis.title =       element_text(size=text.plot, face='bold'),
           axis.title.x =     element_text(vjust=-0.3),
           strip.text       = element_text(size = text.plot,face = 'bold'),
           panel.grid.major = element_line(colour = "grey85"),
           panel.grid.minor = element_line(colour = "grey93"),
           aspect.ratio =     0.5,
           panel.spacing =     unit(1.0, "lines") )
  return(p)
}



#--------------------------------------------------------------------------------------
# Ramping calcuations and plotting
#--------------------------------------------------------------------------------------
# Calculate ramping as the range by day
ramp.day.gen <- interval.ramp.data[, .(ramp=(max(generation)-min(generation))/max(capacity), capacity=max(capacity)), 
                                   by=.(scenario,name,Type,day)]
ramp.day <- ramp.day.gen[, .(ramp=sum(ramp*capacity)/sum(capacity)), by=.(scenario,Type,day)]
ramp_plot(ramp.day,FALSE,4) + ylab('Ramp, Fraction of Capacicty')
ramp_boxplot(ramp.day) + ylab('Ramp, Fraction of Capacicty')


# Calculate ramping as the max change in an hour
ramp.hour.gen <- interval.ramp.data[, .(ramp=max(diff(generation))/max(capacity), capacity=max(capacity)), 
                                    by=.(scenario,name,Type,day)]
ramp.hour <- ramp.hour.gen[, .(ramp=sum(ramp*capacity)/sum(capacity)), by=.(scenario,Type,day)]
ramp_plot(ramp.hour) + ylab('Ramp, Daily average Fraction\nof Capacity per hour')
ramp_boxplot(ramp.hour) + ylab('Ramp, Fraction of Capacicty')


# Calculate ramping as the coefficient of variance
ramp.var.gen <- interval.ramp.data[, .(ramp=sd(generation)/mean(generation)*100,capacity=max(capacity)), 
                                   by=.(scenario,name,Type,day)]
ramp.var.gen[is.na(ramp), ramp:=0]
ramp.var <- ramp.var.gen[, .(ramp=sum(ramp*capacity)/sum(capacity)), by=.(scenario,Type,day)]
ramp_plot(ramp.var,FALSE,5)
ramp_boxplot(ramp.var) 



#------------------------------------------------------------------------------|
# Net load 
#------------------------------------------------------------------------------|

# set graph type to 'duration curve' or 'histogram'
plot_net_load <- function(aggregation = 'all', type = "duration curve") {
  
  # argument check
  if (!(aggregation %in% c("all", "interconnection"))) {
    stop("in plot_net_load, please set aggregation to all or interconnection.
         Interconnection functionality only works for the net load graph, not net load ramps")
  }
  
  if (!(type %in% c("duration curve", "histogram"))) {
    stop("in plot_net_load, please set graph type to duration curve or histogram")
  }
  
  # pull data
  interval.generation.region <- merge(interval.generation,region.zone.mapping[,.(name,Region,Zone)],
                                      by.x = 'name',
                                      by.y = 'name', all.x = T)
  
  interval.re.generation <- interval.generation.region[category %in% re.gen.types,
                                                       .(re.generation = sum(value)),
                                                       by = .(time,scenario,Region)]
  
  interval.net.load <- merge(interval.region.load, interval.re.generation,
                             by.x = c("time", "scenario", "name"), 
                             by.y = c("time", "scenario", "Region"), all.x = T)
  
  interval.net.load[, net.load := value - re.generation]
  
  
  if (aggregation == "interconnection" && type == 'duration curve') {
    
    net.load.duration <- interval.net.load[, .(net.load = sort(net.load, decreasing = T),
                                               duration = 1:(.N)),
                                           by = .(scenario,name)]
    
    #plot
    net.load.duration.plot <-ggplot(net.load.duration)+
      geom_line(aes(x=duration, y=net.load, color = scenario), size=1,alpha=0.7)+
      labs(y="Net Load (MW)", x="Hours")+
      scale_color_discrete(name="Scenario")+
      scale_y_continuous(labels = comma) +
      facet_wrap(~name,scales = 'free_y')+
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             strip.text =       element_text(size=rel(0.7)),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"),
             aspect.ratio =     .65)
    
  }
  
  else if (aggregation == "all" && type == 'duration curve') {
    
    net.load.duration <- interval.net.load[,.(net.load = sum(net.load)), by = .(time, scenario)]
    
    net.load.duration <- net.load.duration[, .(net.load = sort(net.load, decreasing = T),
                                               duration = 1:(.N)),
                                           by = .(scenario)]
    
    #plot
    net.load.duration.plot <-ggplot(net.load.duration)+
      geom_line(aes(x=duration, y=net.load, color = scenario), size=1.2,alpha=0.7)+
      labs(y="Net Load (MW)", x="Hours")+
      scale_color_discrete(name="Scenario")+
      scale_y_continuous(labels = comma) +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             strip.text =       element_text(size=rel(0.7)),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"))
    
  }
  
  else if (aggregation == "interconnection" && type == 'histogram') {
    stop("Interconnection facet is currently only available for the duration curve graph type, not for histograms")
    
  }
  
  else {
    ## Net load histogram
    net.load.duration.plot <- ggplot(data = interval.net.load[,.(net.load = sum(net.load)), by = .(time,scenario)], aes(net.load))+  
      geom_histogram(binwidth=500,color='White',fill='navyblue') +  
      facet_wrap("scenario", scales = 'fixed') +  
      xlab("Net Load (MW)") +  
      ylab("Number of Hours") +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"),
             aspect.ratio =     0.65,
             axis.text.x = element_text(angle = -30, hjust = 0),
             strip.text = element_text(size = text.plot, face = 2))
    
  }
  
  return(net.load.duration.plot)
  
  
  }

#------------------------------------------------------------------------------|
# Net load ramp
#------------------------------------------------------------------------------|

# set graph type to 'duration curve' or 'histogram'
plot_net_load_ramps <- function(fueltype = 'total', type = "duration curve", normalized = FALSE, filter.scenarios = NULL) {
  
  #argument check
  if (!(fueltype %in% c('total', 'each'))) {
    stop("in plot_net_load_ramp, please set fuel type total or each")
  }
  
  if (!(type %in% c('duration curve','histogram'))) {
    stop("in plot_net_load_ramp, please set graph type to duration curve or histogram")
  }
  
  
  
  
  interval.re.gen.total <- interval.generation[category %in% re.gen.types,
                                               .(re.generation=sum(value)),
                                               by = .(time,scenario)]
  
  interval.load.total <- interval.region.load[,.('Load'=sum(value)),
                                              by = .(time,scenario)]
  
  interval.net.load.total <- merge(interval.load.total, interval.re.gen.total,
                                   by.x = c("time", "scenario"),
                                   by.y = c("time", "scenario"), all.x = T)
  
  interval.net.load.total[, net.load := Load - re.generation]
  
  interval.net.load.total[, net.load.ramp := net.load - data.table::shift(net.load, n=1L, type = "lag"), 
                          by = .(scenario)]
  
  if(!is.null(filter.scenarios)){
    interval.net.load.total = interval.net.load.total[scenario %in% filter.scenarios,]
  }
  
  #not used... but useful for determining which day has peak net load swing
  peak.swing = interval.net.load.total[,.SD[which.max(net.load.ramp)],by=scenario]
  peak.swing[,day := yday(time)]
  peak.swing[,date:=as.Date(day-1,origin = as.character(min(interval.re.gen.total$time)))]
  
  if (fueltype == "total" && type == 'duration curve') {
    
    #ramp duration
    net.load.ramp <- interval.net.load.total[, .(ramp.rate = sort(net.load.ramp, decreasing = T),
                                                 duration = 1:(.N-1)),
                                             by = .(scenario)]
    #plot 
    
    net.load.ramp.plot <- ggplot(net.load.ramp)+
      geom_line(aes(x=duration, y=ramp.rate, color = scenario), size=1.2,alpha=0.7)+
      scale_color_discrete(name="Scenario")+
      scale_y_continuous(labels = comma) +
      labs(y="Net Load Variation (MW/hour)", x="Hours")+
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             strip.text =       element_text(size=rel(0.7)),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"))
    
  }
  
  else if (fueltype == "total" && type == 'histogram') {
    # #Net load ramp histogram
    net.load.ramp.plot <- ggplot(data = interval.net.load.total, aes(net.load.ramp))+
      geom_histogram(binwidth=250,color='White',fill='tomato3') +
      facet_wrap("scenario") +
      xlab("Net Load Variation (MW/hour)") +
      ylab("Number of Hours") +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"),
             aspect.ratio =     0.65,
             axis.text.x = element_text(angle = -30, hjust = 0),
             strip.text = element_text(size = text.plot, face = 2))
    
  }
  
  else if (fueltype == "each" && type == 'histogram') {
    stop("Fuel type facet is currently only available for the duration curve graph type, not for histograms")
    
  }
  
  else if (fueltype == 'each' && type == 'duration curve' && normalized == FALSE) {
    #ramps duration curve by fuel 
    fuel.ramps <- merge(interval.generation,region.zone.mapping,
                        by= c('name','Type'),
                        all.x = T)
    
    fuel.ramps <- fuel.ramps[, .(Generation = sum(value)),
                             by = .(Type, scenario, time)]
    
    fuel.ramps[, ramp := Generation - data.table::shift(Generation, 1L, type = "lag"),
               by = .(scenario, Type)]
    
    # convert to per mins
    fuel.ramps[,ramp := ramp/(60)]
    
    fuel.ramp.duration <- fuel.ramps[, .(ramp = sort(ramp, decreasing = T),
                                         duration = 1:(.N-1)),
                                     by = .(scenario, Type)]
    
    # plot
    net.load.ramp.plot <- ggplot(fuel.ramp.duration)+
      geom_line(aes(x=duration, y=ramp, color = scenario), size = 0.8)+
      scale_color_discrete(name="Scenario")+
      labs(y="Ramp Rate (MW/min)", x="") +
      scale_y_continuous(labels = comma) +
      facet_wrap(~Type) +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             strip.text =       element_text(size=rel(0.7)),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"),
             aspect.ratio =     .65)
    
  }
  
  else if (fueltype == 'each' && type == 'duration curve' && normalized == TRUE) {
    #normalized ramp duration by fuel
    
    ramps.and.installed.MW <- merge(fuel.ramps,installed.MW[,.(value.GW = sum(value.GW)), 
                                                            by = .(Type,scenario)],
                                    by = c('scenario', 'Type'),
                                    all.x =TRUE)
    
    normalized.ramps <- ramps.and.installed.MW[, normalized.ramp := ramp / (value.GW)]
    
    normalized.ramp.duration <-normalized.ramps[, .(normalized.ramp = sort(normalized.ramp, decreasing = T),
                                                    duration = 1:(.N-1)),
                                                by = .(scenario, Type)]
    
    # plot
    net.load.ramp.plot <- ggplot(normalized.ramp.duration)+
      geom_line(aes(x=duration, y=normalized.ramp, color = scenario), size = 0.8)+
      scale_color_discrete(name="Scenario")+
      labs(y="Net Load Variation (MW/min) per Installed GW", x="") +
      facet_wrap(~Type) +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             strip.text =       element_text(size=rel(0.7)),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"),
             aspect.ratio =     .65)
    
  }
  
  else {
    stop("Normalized ramp rates only calculated for fueltype = each and type = duration curve")
  }
  
  return(net.load.ramp.plot)
  
}


#------------------------------------------------------------------------------|
# Net load swing
#------------------------------------------------------------------------------|

# set graph type to 'duration curve' or 'histogram'
plot_net_load_swing <- function(type = "duration curve", normalized = FALSE,filter.scenarios = NULL) {
  
  
  if (!(type %in% c('duration curve','histogram'))) {
    stop("in plot_net_load_ramp, please set graph type to duration curve or histogram")
  }
  
  interval.re.gen.total <- interval.generation[category %in% re.gen.types,
                                               .(re.generation=sum(value)),
                                               by = .(time,scenario)]
  
  interval.load.total <- interval.region.load[,.('Load'=sum(value)),
                                              by = .(time,scenario)]
  
  interval.net.load.total <- merge(interval.load.total, interval.re.gen.total,
                                   by.x = c("time", "scenario"),
                                   by.y = c("time", "scenario"), all.x = T)
  
  interval.net.load.total[, net.load := Load - re.generation]
  interval.net.load.total[,day:=yday(time)]
  interval.net.load.total = interval.net.load.total[,.(net.load.ramp=max(net.load)-min(net.load)),by = c('scenario','day')]
  
  if(!is.null(filter.scenarios)){
    interval.net.load.total = interval.net.load.total[scenario %in% filter.scenarios,]
  }
  
  if (type == 'duration curve') {
    
    net.load.ramp <- interval.net.load.total[, .(net.load.ramp = sort(net.load.ramp, decreasing = T),day),by = .(scenario)]
    
    #plot 
    
    net.load.day.ramp.plot <- ggplot(net.load.ramp)+
      geom_line(aes(x=day, y=net.load.ramp, color = scenario), size=1.2, alpha=0.7)+
      scale_color_discrete(name="Scenario")+
      labs(y="Net Load Variation (MW/Day)", x="Days")+
      scale_y_continuous(labels = comma) +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             strip.text =       element_text(size=rel(0.7)),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"))
    
  }
  
  else if ( type == 'histogram') {
    # #Net load ramp histogram
    net.load.day.ramp.plot <- ggplot(data = interval.net.load.total, aes(net.load.ramp))+
      geom_histogram(binwidth=250,color='White',fill='tomato3') +
      facet_wrap("scenario") +
      xlab("Net Load Ramp (MW/Day)") +
      ylab("Number of Days") +
      theme( legend.key =       element_rect(color = "grey80", size = 0.4),
             legend.key.size =  grid::unit(0.9, "lines"), 
             legend.text =      element_text(size=text.plot/1.1),
             axis.text =        element_text(size=text.plot/1.2), 
             axis.title =       element_text(size=text.plot, face=2), 
             axis.title.x =     element_text(vjust=-0.3),
             panel.grid.major = element_line(colour = "grey85"),
             panel.grid.minor = element_line(colour = "grey93"),
             panel.spacing =     unit(1.0, "lines"),
             aspect.ratio =     1,
             axis.text.x = element_text(angle = -30, hjust = 0),
             strip.text = element_text(size = text.plot, face = 2))
    
  }
  
  
  
  else {
    stop("Normalized ramp rates only calculated for fueltype = each and type = duration curve")
  }
  
  return(net.load.day.ramp.plot)
  
}


#------------------------------------------------------------------------------|
# Number of starts
#------------------------------------------------------------------------------|

plot_starts <- function(filter.techs = NULL) {
  
  units.started.month <- data.table(query_month(db.day.ahead,'Generator','Units Started',columns = c('category','name')))
  units.started.year <- data.table(query_year(db.day.ahead,'Generator','Units Started',columns = c('category','name')))
  
  units.started <- merge(units.started.year,region.zone.mapping,
                         by.x = 'name',
                         by.y = 'name',
                         all.x = TRUE)
  
  units.started <- units.started[!category %in% re.gen.types,
                                 .(starts = sum(value)),
                                 by = .(scenario,Type)]
  
  units.started[,corescenario := tstrsplit(scenario,"_",keep=1)]
  units.started = merge(units.started,scenario_dict,by.x='corescenario',by.y='scenario')
  
  if(!is.null(filter.techs)){
    units.started = units.started[Type %in% filter.techs, ]
  }
  units.started[,Type:=factor(Type,levels = gen.order[gen.order %in% unique(Type)])]
  
  
  ggplot(units.started)+
    geom_point(aes(x=Type, y=starts, color = RE_penetration,shape = RE_selection), 
               alpha = 0.7, size = 10, position = position_dodge(width = 0.25))+
    scale_color_discrete(name = 'RE Penetration')+
    scale_shape_discrete(name = 'RE Selection Method') +
    scale_y_continuous(labels=comma) +
    labs(y='Total Generator Startups Per Year', x = NULL)
  
}


int.UC = interval.generation[!Type %in% c('Load','Curtailment')]
int.UC[,UC:=as.integer(value>0)]
int.UC = merge(int.UC, installed.MW[,.(scenario,name,Region,Zone,capacity = value)],by=c('scenario','name'),all.x=T)

int.HVDC.UC = NULL
  # interval.line.flow[name=='258009_148002_1_CKT_DC',.(scenario,UC = as.integer(value!=0),time,
  #                                                                 Zone = ifelse(value>=0,'SL-D3','LEYTE'),
  #                                                                 Region = ifelse(value>=0,'Luzon-Interconnect','Visayas-Interconnect'),
  #                                                                 value,
  #                                                                 capacity = 440,
  #                                                                 name = 'HVDC',
  #                                                                 property = 'Generation',
  #                                                                 category = 'HVDC',
  #                                                                 Type = 'HVDC'),]

#------------------------------------------------------------------------------|
# Synchronous Penetration Plot
#------------------------------------------------------------------------------|
plot_snsp = function(aggregation = NULL){
  int.cap = rbind(int.UC,int.HVDC.UC)
  
  #non-sync cap = inverter-based generation
  nsc = int.cap[UC==1 & category %in% c(re.gen.types,'HVDC'), .(ns_committed_cap = sum(abs(value))),by=c('scenario','time',aggregation)]
  #sync cap = non-inverter based caommitted capacity 
  sc = int.cap[UC==1 &!  category %in% c(re.gen.types,'HVDC'), .(s_committed_cap = sum(capacity)),by=c('scenario','time',aggregation)]
  snsp = merge(nsc, sc,by=c('scenario','time',aggregation))
  snsp[,snsp:=ns_committed_cap/(s_committed_cap+ns_committed_cap)]
  
  
  #plot 
  snsp.dat = snsp[, .(snsp = sort(snsp, decreasing = T),duration = 1:(.N)),by=c('scenario',aggregation)]
  
  snsp.plot <- ggplot(snsp.dat)+
    geom_line(aes(x=duration, y=snsp, color = scenario), size=0.8)+
    scale_color_discrete(name="Scenario")+
    labs(y="Non-synchronous penetration", x="Hours of the year")
  if(!is.null(aggregation)){
    snsp.plot = snsp.plot+facet_grid(paste0(aggregation,"~."))
  }
  
  
  
  snsp.plot = snsp.plot +
    scale_y_continuous(labels = scales::percent)+
    theme( legend.key =      element_rect(color="grey80", size = 0.8),
           legend.key.size = grid::unit(1.0, "lines"),
           legend.text =     element_text(size=text.plot/1.2,face='bold'),
           legend.title = element_blank(),
           legend.position = 'right',
           legend.direction = 'vertical',
           #                         text = element_text(family="Arial"),
           axis.text =       element_text(size=text.plot/1.2,face='bold'),
           # axis.text.x =   element_text(face=2),
           axis.title =      element_text(size=text.plot,face='bold'),
           axis.title.y =    element_text(vjust=1.2),
           panel.spacing =    unit(1.5, "lines"),
           # axis.text.x = element_text(angle = -30, hjust = 0),
           strip.text = element_text(size = text.plot/1.2, face = 'bold'),
           panel.grid.major = element_line(colour = "grey85"),
           panel.grid.minor = element_line(colour = "grey93"))
  
  
  return(snsp.plot)
  
}

#------------------------------------------------------------------------------|
# Instantaneous Penetration Duration Curve
#------------------------------------------------------------------------------|
plot_inst_pen_duration = function(aggregation = NULL){
  vg = int.UC[category %in% re.gen.types,.(VG = sum(value)),by=c('scenario','time',aggregation)]
  tot = int.UC[,.(TotalGen = sum(value)),by=c('scenario','time',aggregation)]
  
  penetration = merge(vg, tot,by=c('scenario','time',aggregation))
  penetration[,VG_Penetration:=VG/TotalGen]
  
  
  #plot 
  penetration = penetration[, .(VG_Penetration = sort(VG_Penetration, decreasing = T),duration = 1:(.N)),by=c('scenario',aggregation)]
  
  penetration.plot <- ggplot(penetration)+
    geom_line(aes(x=duration, y=VG_Penetration, color = scenario), size=1)+
    scale_color_discrete(name="Scenario")+
    labs(y="VG Penetration", x="")
  
  if(!is.null(aggregation)){
    penetration.plot = penetration.plot+facet_grid(paste0(".~",aggregation))
  }
  
  penetration.plot = penetration.plot +
    scale_y_continuous(labels = scales::percent)
  
  return(penetration.plot)
}

#------------------------------------------------------------------------------|
# Capacity Factor Plot
#------------------------------------------------------------------------------|


plot_cf = function(filter.techs = NULL){
  cf[,corescenario := tstrsplit(scenario,"_",keep = 1)]
  cf = merge(cf,scenario_dict,by.x = 'corescenario',by.y='scenario')
  
  if(!is.null(filter.techs)){
    cf = cf[Type %in% filter.techs, ]
  }
  cf[,Type:=factor(Type,levels = gen.order[gen.order %in% unique(Type)])]
  
  ggplot(cf)+
    geom_point(aes(x=Type, y=`Capacity Factor (%)`, color = RE_penetration, shape = RE_selection), 
               size = 10, position = position_dodge(width = 0.25),alpha = 0.7)+
    scale_color_discrete(name='RE Penetration') +
    scale_shape_discrete(name='RE Selection Method') +
    
    #geom_bar(aes(x=Type, y=`Capacity Factor (%)`, fill = scenario), stat = 'identity', position = position_dodge(width = 0.25))+# scale_color_discrete(name = 'Scenario')+
    labs(y='Capacity Factor (%)', x = NULL)
}





