import { ethers } from 'ethers';
import { TypedDataSigner } from '@ethersproject/abstract-signer';
import { verifySignature } from './verifier';
import * as msg from './msg';

/**
 * Sign a message with ethers for eip-712
 */
export async function signMessage(signer: ethers.Signer & TypedDataSigner, message: Record<string, any>): Promise<string> {
      /*
      This is still an experimental feature. If using it, please specify the exact version of ethers you are using (e.g. spcify "5.0.18", not "^5.0.18") as the method name will be renamed from _signTypedData to signTypedData once it has been used in the field a bit.
      */
      const signature = await signer._signTypedData(msg.domain, msg.types, message);
      return signature
}


async function main() {
    const message = 'hello';
    const privateKey = process.env.PRIVATE_KEY;
    const publicKey = process.env.PUB_KEY;
    if (!(!!privateKey && !!publicKey)) {
        throw new Error('PRIVATE_KEY and PUB_KEY env variables must be set');
    }
    // const provider = new ethers.providers.JsonRpcProvider('http://localhost:8545');
    const wallet = new ethers.Wallet(privateKey/*, provider*/);

    const signer = wallet;
    const signature = await signMessage(signer, msg.createMessage((message)));
    console.log('select update_user' + JSON.stringify([signature, publicKey, message]).replace(']', ')').replace('[', '(').replace(/"/g,"'") + ";")
    const verified =  verifySignature(signature, publicKey, message);
    console.log(verified);
}

main()