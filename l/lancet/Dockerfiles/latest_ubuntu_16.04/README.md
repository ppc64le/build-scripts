Lancet (package)

Build and run the container:

$docker build -t lancet .
$docker run --name demo_lancet -i -t lancet /bin/bash

Test the working of Container:
        Now inside the container type python and enter the  python shell.
	Now run the following program line by line:

>>> import lancet
>>> example_name   = 'prime_quintuplet'
>>> integers       = lancet.Range('integer', 100, 115, steps=16, fp_precision=0)
>>> factor_cmd     = lancet.ShellCommand(executable='factor', posargs=['integer'])
>>> lancet.Launcher(example_name, integers, factor_cmd, output_directory='output')()
INFO:root:Launcher: Group 0: executing 16 processes...
>>> def load_factors(test):
...    with open(test, 'r') as f:
...        factor_list = f.read().replace(':', '').split()
...    return dict(enumerate(int(el) for el in factor_list))
...
>>> output_files   = lancet.FilePattern('filename', './output/*-prime*/streams/*.o*')
>>> output_factors = lancet.FileInfo(output_files, 'filename',
...                                  lancet.CustomFile(metadata_fn=load_factors))
>>> primes = sorted(factors[0] for factors in output_factors.specs
...                 if factors[0]==factors[1]) # i.e. if the input integer is the 1st factor
>>> primes

Output of above command:
[101, 101, 101, 101, 103, 103, 103, 103, 107, 107, 107, 107, 109, 109, 109, 109, 113, 113, 113, 113]
