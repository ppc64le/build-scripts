Codetools (Rpackage)

Build and run the container:

$docker build -t codetools .
$docker run --name demo_codetools -i -t codetools /bin/bash

Test the working of Container:
        Now inside the container type R and enter the  R shell.
	Now run the following program line by line:
 ```bash
> library(codetools)
> checkUsage(checkUsage)
> checkUsagePackage("codetools",all=TRUE)
addCollectUsageHandler: parameter ‘where’ may not be used
apdef: parameter ‘e’ changed by assignment
checkUsageEnterLocal: parameter ‘type’ changed by assignment
checkUsageFinishLocals: parameter ‘w’ changed by assignment
collectUsageFun: parameter ‘w’ changed by assignment
collectUsageIsLocal: parameter ‘v’ changed by assignment
constantFold : job : isLocal: parameter ‘w’ may not be used
constantFold : job : doExit: parameter ‘e’ may not be used
constantFold : job : doExit: parameter ‘w’ may not be used
constantFoldEnv : isLocal: parameter ‘w’ may not be used
constantFoldEnv : job : doExit: parameter ‘e’ may not be used
constantFoldEnv : job : doExit: parameter ‘w’ may not be used
constantFoldEnv : <anonymous>: parameter ‘e’ may not be used
constantFoldEnv: parameter ‘env’ may not be used
evalseq: parameter ‘e’ changed by assignment
findGlobals : enter: parameter ‘e’ may not be used
findGlobals : enter: parameter ‘w’ may not be used
findLocalsList : collect: parameter ‘e’ may not be used
findLocalsList : collect: parameter ‘w’ may not be used
findLocalsList : isLocal: parameter ‘w’ may not be used
findOwnerEnv: parameter ‘env’ changed by assignment
foldLeaf: parameter ‘e’ changed by assignment
getCollectLocalsHandler : <anonymous>: parameter ‘e’ may not be used
getCollectLocalsHandler : <anonymous>: parameter ‘w’ may not be used
getCollectLocalsHandler : <anonymous>: parameter ‘e’ may not be used
getCollectLocalsHandler : <anonymous>: parameter ‘w’ may not be used
isClosureFunDef: parameter ‘w’ may not be used
isConstantValue: parameter ‘w’ may not be used
makeAssgnFcn: parameter ‘fun’ changed by assignment
makeCodeWalker : <anonymous>: parameter ‘v’ may not be used
makeCodeWalker : <anonymous>: parameter ‘w’ may not be used
makeCodeWalker : <anonymous>: parameter ‘w’ may not be used
makeConstantFolder : <anonymous>: parameter ‘w’ may not be used
makeConstantFolder : <anonymous>: parameter ‘v’ may not be used
makeConstantFolder : <anonymous>: parameter ‘w’ may not be used
makeConstantFolder : <anonymous>: parameter ‘e’ may not be used
makeConstantFolder : <anonymous>: parameter ‘w’ may not be used
makeConstantFolder: parameter ‘foldable’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘e’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘w’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘v’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘w’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘e’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘w’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘e’ may not be used
makeLocalsCollector : <anonymous>: parameter ‘w’ may not be used
makeLocalsCollector: parameter ‘exit’ may not be used
walkCode: local variable ‘h’ used as function with no apparent local function definition
> findGlobals(findGlobals)
 [1] "{"            "<-"           "=="           "assign"       "c"
 [6] "collectUsage" "if"           "list"         "ls"           "mkHash"
[11] "sort"         "unique"
> findGlobals(findGlobals, merge = FALSE)
$functions
 [1] "{"            "<-"           "=="           "assign"       "c"
 [6] "collectUsage" "if"           "list"         "ls"           "mkHash"
[11] "sort"         "unique"


```
