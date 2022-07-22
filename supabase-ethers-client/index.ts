import {createClient, PostgrestResponse, SupabaseClient, UserCredentials} from '@supabase/supabase-js';
const supabase:SupabaseClient = function () {
  const [SUPABASE_URL, SUPABASE_KEY] = [process.env.SUPABASE_URL, process.env.SUPABASE_KEY]
  if (!SUPABASE_URL || !SUPABASE_KEY) {
    throw new Error('missing env vars')
  }
  return createClient(SUPABASE_URL, SUPABASE_KEY);
}()

function signup(creds: UserCredentials, pubkey: string) {
    supabase.auth
    .signUp(creds, {data: {pubkey: pubkey}})
    .then((response) => {
      response.error ? console.log(response.error.message) : console.log('token', response)
    })
    .catch((err) => {
      console.log('err', err)
    })
}

async function get_jwt():Promise<string> {
  let ret:PostgrestResponse<any> = await supabase.rpc("login_by_signature", {signature:'0x57216e09b1fd78b8e64ddbc20930f321d38fb6401a43d802a060aa229b4d9a41003866f4cd584fc58a0b483fb6a1b8fcba3033a03ba38793d3c5c6257cc323b71b',signer:'0xfF6fb5Ef289410592023F92F580B0ca783538027'})
  if (!ret.body) {
    throw new Error("")
  }
  return ret.body as any as string
}

async function do_stuff() {
  let r = await supabase.from('foo').insert({'data': new Date().toString()})
  console.log(r)
}

async function main() {
  let [email, password, pubkey] = [process.env.EMAIL, process.env.PASSWORD, process.env.PUB_KEY]
  console.log([email, password, pubkey])
  if (!email || !password || !pubkey) {
    console.log('missing env vars')
    return
  }
  let creds = {email:email, password:password}
  // signup(creds, pubkey)
  // return
  //https://supertokens.com/docs/thirdpartypasswordless/supabase-intergration/backend
  // https://medium.com/@gracew/using-supabase-rls-with-a-custom-auth-provider-b31564172d5d
  let token //= await supabase.auth.signIn(creds)
  // supabase.auth.setAuth('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhdWQiOiJhdXRoZW50aWNhdGVkIiwiZXhwIjoxNjU4NDE0MDE3LCJzdWIiOiI2ZWYwNGIxOS1mMjhiLTQzOGYtYjczOS01MTMwN2I5NzJmMzciLCJlbWFpbCI6InRhcmFzQGdsZWsubmV0IiwicGhvbmUiOiIiLCJhcHBfbWV0YWRhdGEiOnsicHJvdmlkZXIiOiJlbWFpbCIsInByb3ZpZGVycyI6WyJlbWFpbCJdfSwidXNlcl9tZXRhZGF0YSI6eyJwdWJrZXkiOiIweGZGNmZiNUVmMjg5NDEwNTkyMDIzRjkyRjU4MEIwY2E3ODM1MzgwMjcifSwicm9sZSI6ImF1dGhlbnRpY2F0ZWQifQ.PCcmZVSsVEfC6FEPuSR7ixaYZKC7GmLjudazniWBFps')
  let jwt = await get_jwt()
  console.log('jwt', jwt)
  supabase.auth.setAuth(jwt)
  
  await do_stuff()
  console.log('token', token)
}
main()