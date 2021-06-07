## AWS HordeSAT Example

This is an example of how to create a repository for a solver to be used in SAT Comp 2021

There are two files that you must take note of. 

### Dockerfile

The first is the Dockerfile.
Most of this should simply be copied. 
The parts that you should change are where we create the container that will build your solver:

    FROM ubuntu:16.04 AS builder
    RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt install -y cmake build-essential zlib1g-dev libopenmpi-dev git wget unzip build-essential zlib1g-dev iproute2 cmake python python-pip build-essential gfortran wget curl
    # Clone Hordesat
    RUN git clone https://github.com/biotomas/hordesat
    # Build Hordesat - change for your own solver
    RUN cd hordesat && ./makehordesat.sh

Here you should install whatever dependencies are needed to build your solver and then fetch the code and build it.

Then you must also modify the section of the Dockerfile that creates the container that will run your solver:

    FROM horde_base AS horde_liaison
    RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive apt install -y awscli python3 mpi
    
    # Copy the Hordesat binaries from the build container - change this line for your solver
    COPY --from=builder /hordesat/hordesat /hordesat/hordesat
    
Here we install the dependencies needed to run the solver and then copy the binaries from the build container.
Please do not modify any other lines in the Dockerfile as they are used by the competition. Feel free to email us at [sat-comp-2021@amazon.com](mailto:sat-comp-2021@amazon.com) with any questions.

### mpi-run.sh

This is the script that will be run in the container. 
For the main node it logs its IP address so that the system can provide that IP to the worker nodes. 
It then waits for worker nodes to register.


## License

This library is licensed under the MIT-0 License. See the LICENSE file.

