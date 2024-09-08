#ifndef MS_DMAC_AHBL_H
#define MS_DMAC_AHBL_H

#include <MS_DMAC_AHBL_regs.h>
#include <stdint.h>

void MS_DMAC_enable (uint32_t dmac_base, char enable);

void MS_DMAC_setSourceDataType(uint32_t dmac_base, int value);

void MS_DMAC_setDestinationDataType (uint32_t dmac_base, int value);

// void MS_DMAC_sourceAddrAutoIncrement(uint32_t dmac_base, int value);

// void MS_DMAC_destinationAddrAutoIncrement(uint32_t dmac_base, int value);
 
void MS_DMAC_setControlReg (uint32_t dmac_base, int value);

int MS_DMAC_getControlReg(uint32_t dmac_base);

void MS_DMAC_setSourceAddr(uint32_t dmac_base, int value);

int MS_DMAC_getSourceAddr(uint32_t dmac_base);

void MS_DMAC_setDestinationAddr(uint32_t dmac_base, int value);

int MS_DMAC_getDestinationAddr(uint32_t dmac_base);

void MS_DMAC_setCount(uint32_t dmac_base, int value);

int MS_DMAC_getCount(uint32_t dmac_base);

void MS_DMAC_setSWTrigger(uint32_t dmac_base, int value);

int MS_DMAC_getSWTrigger(uint32_t dmac_base);

int MS_DMAC_getStatus(uint32_t dmac_base);

#endif