# cat 
yarn build > /dev/null 2>&1

MIN=`cat dist/plv8_verifier.js`


cat << EndOfMessage
CREATE OR REPLACE FUNCTION login_by_signature(signature varchar, signer varchar)
  RETURNS VARCHAR AS
  \$\$
  DECLARE jwt VARCHAR;
  BEGIN
    PERFORM verifySignature(signature, signer,'password.nonce');
    SELECT sign(cast('{"role": "authenticated", "exp":' || round(extract(epoch from now())+3600)::varchar ||'}' as json),'$JWT_SECRET') INTO jwt;
    RETURN jwt;
  END;
  \$\$ LANGUAGE plpgsql;

create or replace function verifySignature(signature varchar, signer varchar, message varchar)
returns bool as \$\$
if (!plv8.verifySignature) {
    $MIN
}
return plv8.verifySignature(signature, signer, message);
\$\$ language plv8;

EndOfMessage