# RiscV_CPU_with_Accelerator
A RiscV CPU with an accelerator for accelerating neural networks attached to it

The ISA is based on RV-32 instruction set and is appended with customized instructions to accommodate our Accelerator.

Cache and main memory are implemented using registers as memory blocks.

The accelerator is a simple model of systolic array with each block consisting of a mutiplier and an adder.

All the components are attached together using a simplified bus.  
