import { verifyTypedData } from '@ethersproject/wallet';
import * as msg from './msg';

/**
 * Verify a eip-712 signature
 */
 export function verifySignature(signature: string, expectedSignerAddress: string, message: string): boolean {
    /*
    This is still an experimental feature. If using it, please specify the exact version of ethers you are using (e.g. spcify "5.0.18", not "^5.0.18") as the method name will be renamed from _signTypedData to signTypedData once it has been used in the field a bit.
    */
    const recoveredAddress = verifyTypedData(msg.domain, msg.types, msg.createMessage(message), signature);
    return recoveredAddress === expectedSignerAddress;
  }