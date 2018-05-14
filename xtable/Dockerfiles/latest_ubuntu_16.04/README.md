xtable (Rpackage)

Build and run the container:

$docker build -t xtable .
$docker run --name demo_xtable -i -t xtable /bin/bash

Test the working of Container:
Inside the container type R and enter the R shell. Execute following commands:

>> library(xtable)
>> options(xtable.floating = FALSE)
>> options(xtable.timestamp = "")
>> data(tli)
>> xtable(tli[1:10, ])

Output of the last line will be:

% latex table generated in R 3.4.0 by xtable 1.8-2 package
%
\begin{tabular}{rrlllr}
  \hline
 & grade & sex & disadvg & ethnicty & tlimth \\
  \hline
1 &   6 & M & YES & HISPANIC &  43 \\
  2 &   7 & M & NO & BLACK &  88 \\
  3 &   5 & F & YES & HISPANIC &  34 \\
  4 &   3 & M & YES & HISPANIC &  65 \\
  5 &   8 & M & YES & WHITE &  75 \\
  6 &   5 & M & NO & BLACK &  74 \\
  7 &   8 & F & YES & HISPANIC &  72 \\
  8 &   4 & M & YES & BLACK &  79 \\
  9 &   6 & M & NO & WHITE &  88 \\
  10 &   7 & M & YES & HISPANIC &  87 \\
   \hline
\end{tabular}
