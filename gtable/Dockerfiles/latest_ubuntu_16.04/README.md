gtable (Rpackage)

Build and run the container:

$docker build -t gtable .
$docker run --name demo_gtable -i -t gtable /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:


> library(gtable)
> library(grid)
> a <- gtable(unit(1:3, c("cm")), unit(5, "cm"))
> a <- gtable(unit(1:3, c("cm")), unit(5, "cm"))
> a
TableGrob (1 x 3) "layout": 0 grobs
> gtable_show_layout(a)
> rect <- rectGrob(gp = gpar(fill = "black"))
> a <- gtable_add_grob(a, rect, 1, 1)
> a
TableGrob (1 x 3) "layout": 1 grobs
  z     cells   name               grob
1 1 (1-1,1-1) layout rect[GRID.rect.17]
> plot(a)
> dim(a)
[1] 1 3
> t(a)
TableGrob (3 x 1) "layout": 1 grobs
  z     cells   name               grob
1 1 (1-1,1-1) layout rect[GRID.rect.17]
> plot(t(a))
> b <- gtable(unit(c(2, 2, 2), "cm"), unit(c(2, 2, 2), "cm"))
>
> b <- gtable_add_grob(b, rect, 2, 2)
> b[1, ]
TableGrob (1 x 3) "layout": 0 grobs
> b[, 1]
TableGrob (3 x 1) "layout": 0 grobs
> b[2, 2]
TableGrob (1 x 1) "layout": 1 grobs
  z     cells   name               grob
1 1 (1-1,1-1) layout rect[GRID.rect.17]
> rownames(b) <- 1:3
> rownames(b)[2] <- 200
> colnames(b) <- letters[1:3]
> dimnames(b)
[[1]]
[1]   1 200   3

[[2]]
[1] "a" "b" "c"
