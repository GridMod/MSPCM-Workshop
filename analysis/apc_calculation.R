# --------------------------------------------------------------
# APC Calculation
# --------------------------------------------------------------
get_zone_cost <- function(df){
  setkey(df,name)
  setkey(region.zone.mapping,name)
  zone.df <- merge(region.zone.mapping,df)
  return(zone.df[,.(value=sum(value)), by=.(scenario,property,Zone,Region)])
}

get_zone_interval <- function(df){
  setkey(df,name)
  setkey(region.zone.mapping,name)
  zone.df <- merge(region.zone.mapping,df)
  return(zone.df[,.(value=sum(value)), by=.(scenario,property,time,Zone,Region)])
}

# Get total cost
zone.fuel.cost = get_zone_cost(total.fuel.cost)
zone.vom.cost = get_zone_cost(total.vom.cost)
zone.emissions.cost = get_zone_cost(total.emissions.cost)
zone.ss.cost = get_zone_cost(total.ss.cost)

# Get interval import/export costs
interval.tot.generation = merge(interval.generation, interval.pump.load,
                                by=c('scenario','name','time'))
interval.tot.generation[, value:=value.y-value.x]
interval.region.generation = get_zone_interval(interval.generation)

interval.import.export = merge(interval.region.generation, interval.region.load, 
                               by.y = c('scenario','name','time'),
                               by.x = c('scenario','Region','time'))
interval.import.export[, import_export:=value.x-value.y]

interval.import.cost <- merge(interval.import.export, interval.region.price,
                              by=c('scenario','Region','time'))
interval.import.cost[, import_cost:=import_export*value]
interval.import.cost[, import_export:=ifelse(import_cost<0,'export','import')]

# Combine zone costs and calculate APC
zone.cost = rbindlist(list(zone.emissions.cost, zone.fuel.cost, zone.ss.cost, zone.vom.cost))
zone.apc = merge(zone.cost[,.(cost=sum(value)/1000), by=.(scenario,Zone)],
                 interval.import.cost[,.(import_cost=sum(import_cost)/1000000000), by=.(scenario,Zone,import_export)],
                 by=c('scenario','Zone'))
zone.apc[, apc:=cost-import_cost]

# Plot zone APC
ggplot(zone.apc, aes(Zone,apc,fill=scenario))+geom_bar(stat='identity',position='dodge')+
  scale_fill_brewer(palette = 'Set1')

ggplot(zone.apc, aes(Zone,apc,fill=scenario))+geom_bar(stat='identity',position='dodge')+
  scale_fill_brewer(palette = 'Set1')+ylab("APC, $MM")+
  theme(text=element_text(size=16),axis.text=element_text(size=14))

zone.apc.components = rbindlist(list(zone.cost[,.(cost=sum(value)/1000,import_export='generation'), by=.(scenario,Zone)],
                                     interval.import.cost[,.(cost=sum(import_cost)/1000000/24), 
                                                          by=.(scenario,Zone,import_export)]),use.names=TRUE,fill=TRUE)

ggplot(zone.apc.components, aes(scenario,cost,fill=import_export))+geom_bar(stat='identity',position='dodge')+
  scale_fill_brewer(palette = 'Set1',name='APC Cost\nComponent')+facet_wrap(~Zone,ncol=3) +
  ylab('Total Cost, MM$') + 
  theme(text=element_text(size=16),axis.text=element_text(size=14),axis.text.x=element_text(angle=-30,hjust=0))


# --------------------------------------------------------------
# Line loading
# --------------------------------------------------------------
interval.line.flow = interval_line_flow(db)
interval.line.flow[, max_flow := max(abs(value)), by=.(scenario,name)]
interval.line.flow[, fraction_flow:=value/max_flow]
interval.line.flow[, hr_rank:=rank(-fraction_flow,ties.method = 'random'), by=.(scenario,name)]

ggplot(interval.line.flow[name %in% c('A1','B1','C1','CA-1')], aes(hr_rank,fraction_flow, color=name))+
  geom_line() + scale_fill_brewer(palette='Set1')+
  facet_wrap(~scenario,ncol=3) + scale_color_brewer(palette = 'Set1') + 
  ylab("Fractional Flow") + xlab('Hour, ranked')