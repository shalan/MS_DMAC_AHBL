#ifndef MS_DMAC_AHBL_C
#define MS_DMAC_AHBL_C

#include <MS_DMAC_AHBL.h>

void MS_DMAC_enable (uint32_t dmac_base, char enable){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    if(enable){
        dmac->control |= 0x1; 
    }
    else {

        dmac->control &= 0xFFFFFFFE; 
    }
}

//0: byte, 1: half word, 2: word

void MS_DMAC_setSourceDataType(uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    if (value < 0 || value > 2){
        return;
    }
    else {
        unsigned int mask = ((1 << MS_DMAC_AHBL_CONTROL_REG_STYPE_LEN) - 1) << MS_DMAC_AHBL_CONTROL_REG_STYPE;

        // Clear the bits at the specified offset in the original number
        dmac->control &= ~mask;

        // Set the bits with the given value at the specified offset 
        dmac->control |= (value << MS_DMAC_AHBL_CONTROL_REG_STYPE);
    }

}

//0: byte, 1: half word, 2: word
void MS_DMAC_setDestinationDataType (uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    if (value < 0 || value > 2){
        return;
    }
    else {

        unsigned int mask = ((1 << MS_DMAC_AHBL_CONTROL_REG_DTYPE_LEN) - 1) << MS_DMAC_AHBL_CONTROL_REG_DTYPE;

        // Clear the bits at the specified offset in the original number
        dmac->control &= ~mask;

        // Set the bits with the given value at the specified offset
        dmac->control |= (value << MS_DMAC_AHBL_CONTROL_REG_DTYPE);

    }
    
}

// void MS_DMAC_sourceAddrAutoIncrement(uint32_t dmac_base, int value){
    
//     MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
//     if (value < 0 || value > 4){
//         return;
//     }
//     else {

//         unsigned int mask = ((1 << MS_DMAC_AHBL_CONTROL_REG_SAI_LEN) - 1) << MS_DMAC_AHBL_CONTROL_REG_SAI;

//         // Clear the bits at the specified offset in the original number
//         dmac->control &= ~mask;

//         // Set the bits with the given value at the specified offset
//         dmac->control |= (value << MS_DMAC_AHBL_CONTROL_REG_SAI);

//     }
// }

// void MS_DMAC_destinationAddrAutoIncrement(uint32_t dmac_base, int value){
    
//     MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
//     if (value < 0 || value > 4){
//         return;
//     }
//     else {

//         unsigned int mask = ((1 << MS_DMAC_AHBL_CONTROL_REG_DAI_LEN) - 1) << MS_DMAC_AHBL_CONTROL_REG_DAI;

//         // Clear the bits at the specified offset in the original number
//         dmac->control &= ~mask;

//         // Set the bits with the given value at the specified offset
//         dmac->control |= (value << MS_DMAC_AHBL_CONTROL_REG_DAI);

//     }
// }


void MS_DMAC_setControlReg (uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    dmac->control = value;
}

int MS_DMAC_getControlReg(uint32_t dmac_base){
    
    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    return (dmac->control);
}

void MS_DMAC_setSourceAddr(uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    dmac->saddr = value;

}
int MS_DMAC_getSourceAddr(uint32_t dmac_base){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    return (dmac->saddr);

}

void MS_DMAC_setDestinationAddr(uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    dmac->daddr = value;

}
int MS_DMAC_getDestinationAddr(uint32_t dmac_base){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    return (dmac->daddr);

}

void MS_DMAC_setCount(uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    dmac->count = value;

}
int MS_DMAC_getCount(uint32_t dmac_base){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    return (dmac->count);

}

void MS_DMAC_setSWTrigger(uint32_t dmac_base, int value){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    dmac->swtrig = value;

}
int MS_DMAC_getSWTrigger(uint32_t dmac_base){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    return (dmac->swtrig);

}
int MS_DMAC_getStatus(uint32_t dmac_base){

    MS_DMAC_AHBL_TYPE* dmac = (MS_DMAC_AHBL_TYPE*)dmac_base;
    return (dmac->status);

}

#endif //MS_DMAC_AHBL_C

