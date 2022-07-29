import m5
from m5.objects import *

def modifyO3CPUConfig(options, cpu):
    print('modifying O3 cpu config')
    if options.num_ROB:
        cpu.numROBEntries = options.num_ROB
    if options.num_IQ:
        cpu.numIQEntries = options.num_IQ
    if options.num_LQ:
        cpu.LQEntries = options.num_LQ
    if options.num_SQ:
        cpu.SQEntries = options.num_SQ
    if options.num_PhysReg:
        cpu.numPhysIntRegs = options.num_PhysReg
        cpu.numPhysFloatRegs = options.num_PhysReg
        cpu.numPhysVecRegs = options.num_PhysReg
        cpu.numPhysCCRegs = 0
    cpu.branchPred = LTAGE()
