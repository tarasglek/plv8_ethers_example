import { verifySignature } from './verifier';
/*
builds file that can get ingested in gen_sql_plv8_functions.sh
*/

plv8.verifySignature = verifySignature
// verifySignature(signature, signer, message);