example of how to do eip712 verification in postgres via ethers + plv8.

Load env vars:
```
dotenv allow
```


Load in postgres:
```
./gen_sql_plv8_functions.sh | psql -h db.ajewkstjnorcwlczewie.supabase.co -p 5432 -d postgres -U postgres
```
Then in psql execute:
```
select verifySignature('0x12609bd9580f4550071b4076603f0f040d7088edb30ecc6879c3a47c9cd2cd831cfa1ec4e27e52a76da2e5601fb29f4e297331167bc9ba31f4a9236d57a6137c1c','0xfF6fb5Ef289410592023F92F580B0ca783538027','hello');
```