# BASH LOAD BALANCER FOR UNMANAGED CLUSTERS
You need to have ssh daemons running on your nodes.

How to use:

Develop a program <run_single_core> to run on *one* CPU core. The program should accept command-line parameters a b c...

Once your program is ready, create a file <parameter list> with one realization of a b c... per line.
  
Update "start_conveyor.sh" with the number of cores per each node.

Schedule your batch job: time ./CONVEYOR/start_conveyor.sh ./<run_single_core> <parameter list>
  
Use "start_conveyor.sh" together with "downloader.sh" if some of the dependencies are not present on the disk yet (not downloaded or computed by a preceding stage). Once a dependency is ready, the scheduler will start its corresponding task, provided that there is enough available cores somewhere in your cluster.
