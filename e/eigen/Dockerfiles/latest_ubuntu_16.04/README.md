Using Eigen Docker Image

.	Run the docker container:
$docker run .it .name=eigen eigen bash
.	Install gcc and cpp
.	Then set cpath to Eigen location:
$export CPATH=/usr/local/include/eigen3
.	Now create a sample.cpp program as follows:
#include <iostream>
#include <Eigen/Dense>
using Eigen::MatrixXd;
int main()
{
MatrixXd m(2,2);
m(0,0) = 3;
m(1,0) = 2.5;
m(0,1) = -1;
m(1,1) = m(1,0) + m(0,1);
std::cout << m << std::endl;
}

.	Now compile and run:
$ g++ sample.cpp
$./a.out
.	Output should be as follows:
3 -1
2.5 1.5



