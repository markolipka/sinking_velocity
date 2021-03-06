#### particle sinking velocity in fluids 
#### using formulas from Dietrich 1982 (Water Resour. Res.)
#### or Stokes' Law
# by david.kaiser.82@gmail.com, github.com/davidatlarge
sinking.velocity.m.sec <- function(salinity, # in psu
                                   temperature, # in °C
                                   depth, # depth in m
                                   latitude, # latitude in °N, used to calculate pressure for density and gravity
                                   particle.density, # in kg/m^3 
                                   particle.diameter, # in m
                                   powers.p = 6, # powers roundness; defaults to 6 for perfectly round areas, including shperes
                                   CSF = 1, # Corey Shape factor; defaults to 1 for spheres
                                   method = "dietrich" # calculation method, c("dietrich", "stokes")
){
  # load required packages
  require(marelac)
  
  # calculate gravity
  gravity <- gravity(lat = latitude, method = "Moritz")
  # calculate water parameters
  water.density <- sw_dens(S = salinity, t = temperature, P = d2p(depth, lat = latitude)/10+1, method = "UNESCO") # value of d2p is dbar of pressure exerted by water, without air, hence /10 and +1 ; method="Gibbs" by default
  dynamic.viscosity <- viscosity(S = salinity, t = temperature, P = d2p(depth, lat = latitude)/10+1) # viscosity in centipoise (cP); 1 cP = 0.001 kg·m−1·s−1
  dynamic.viscosity <- dynamic.viscosity / 1000 # factor 10^-3 to convert viscosity to [kg/m/s]
  kinematic.viscosity <- dynamic.viscosity / water.density 
  
  # calculate sinking velocity ...
  switch(method,
         "dietrich" = { # ... according to Dietrich 1982
           Dstar <- ((particle.density - water.density) * gravity * particle.diameter^3) / (water.density * kinematic.viscosity^2) # dimensionless size D*; introduces NaN for particles with lower density than water
           R1 <- -3.76715 + 1.92944*(log10(Dstar)) - 0.09815*(log10(Dstar))^2 - 0.00575*(log10(Dstar))^3 + 0.00056*(log10(Dstar))^4 # size and denisty effect
           R2 <- (log10(1-((1-CSF)/0.85))) - (1-CSF)^2.3*tanh(log10(Dstar)-4.6) + 0.3*(0.5-CSF)*(1-CSF)^2 * (log10(Dstar)-4.6) # shape effect
           R3 <- (0.65-((CSF/2.83) * tanh(log10(Dstar)-4.6)))^(1+(3.5-powers.p)/2.5) # roundness effect
           Wstar <- R3 * 10^(R1+R2) 
           sinking.velocity.m.sec <- ((Wstar*(particle.density-water.density) * gravity*kinematic.viscosity) / water.density)^(1/3) # introduced NaN for those particles that have no value for ESD because the dimensions were not measured
         },
         "stokes" = { # ... according to Stokes' Law
           if(particle.diameter > 0.0002) {warning("Particle diameter > 200 µm! \n Stokes' Law will overestimate sinking velocity! \n Use default method = \"dietrich\"!", call. = FALSE)}
           sinking.velocity.m.sec <- (particle.diameter^2*gravity*(particle.density-water.density)) / (18*dynamic.viscosity)
           if(sinking.velocity.m.sec <= 0){sinking.velocity.m.sec <- NaN}
         }
  )
  if(particle.density<water.density){
    warning(paste("Particle density (", round(particle.density), ") < water density (", round(water.density), 
                  ")! Particle will not sink! Returning NaN.", sep = ""),
            call. = FALSE)
  }
  return(sinking.velocity.m.sec)
}