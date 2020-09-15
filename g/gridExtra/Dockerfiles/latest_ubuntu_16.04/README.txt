GridExtra (Rpackage)
Build and run the container:

$docker build -t grid-extra .
$docker run -it --name=demo_grid_extra grid-extra

Test the working of Container:
Inside the container type R and enter the R shell. Execute following code:

	>> library(gridExtra)
	>> library(grid)
       	>> N <- 5
       	>> xy <- polygon_regular(N)*2
       # draw multiple polygons
       	>> g <- ngonGrob(unit(xy[,1],"cm") + unit(0.5,"npc"),
       		unit(xy[,2],"cm") + unit(0.5,"npc"),
       		n = seq_len(N) + 2, gp = gpar(fill=1:N))
       	>> grid.newpage()
       	>> grid.draw(g)
