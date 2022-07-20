// eip 712 example https://dev.to/zemse/ethersjs-signing-eip712-typed-structs-2ph8
export const domain = {
    name: 'My App',
    version: '1',
    chainId: 1,
    verifyingContract: '0x1111111111111111111111111111111111111111'
};

export const types = {
    msg: [
      { name: 'msg', type: 'string' },
    ]
};

export function createMessage(message: string): Record<string, any> {
    return { msg: message };
}