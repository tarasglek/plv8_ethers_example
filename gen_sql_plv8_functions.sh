# cat 
yarn build > /dev/null 2>&1

MIN=`cat dist/plv8_verifier.js`
cat << EndOfMessage
create or replace function verifySignature(signature varchar, signer varchar, message varchar)
returns bool as \$\$
if (!plv8.verifySignature) {
    $MIN
}
return plv8.verifySignature(signature, signer, message);
\$\$ language plv8;

EndOfMessage