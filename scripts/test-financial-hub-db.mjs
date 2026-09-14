// PostgreSQL WASM tests: real SQL/RLS, isolated in memory, no hosted credentials.
import { readFile, readdir } from 'node:fs/promises';
import assert from 'node:assert/strict';
import { PGlite } from '../.local-backups/hub-tools/node_modules/@electric-sql/pglite/dist/index.js';
const db=new PGlite();
let count=0;
const check=async(name,run)=>{await run();count++;console.log('PASS '+name);};
const scalar=async(sql,args=[])=>Object.values((await db.query(sql,args)).rows[0])[0];
try {
 await db.exec(`create role anon; create role authenticated; create role service_role bypassrls;
 create schema auth; create table auth.users(id uuid primary key,email text,raw_user_meta_data jsonb default '{}'::jsonb);
 create function auth.uid() returns uuid language sql stable as 'select nullif(current_setting(''request.jwt.claim.sub'',true),'''')::uuid';
 grant usage on schema auth,public to authenticated,service_role,anon;
 grant execute on function auth.uid() to authenticated,service_role;`);
 const names=await readdir('supabase/migrations');
 for(const name of names.filter(n=>/^(001_|002_|003_|005_|006_|008_)/.test(n)||n.endsWith('_financial_hub_boundaries.sql')).sort()) {
   // These optional extensions are unused by the tested domain; UUID generation is built in.
   const sql=(await readFile('supabase/migrations/'+name,'utf8')).replace(/create extension if not exists "(?:pgcrypto|citext)";/g,'');
   await db.exec(sql);
 }
 await db.exec('grant all on all tables in schema public to service_role; grant usage,select on all sequences in schema public to service_role;');
 const u='00000000-0000-0000-0000-000000000001', other='00000000-0000-0000-0000-000000000002';
 await db.query('insert into auth.users(id) values ($1),($2)',[u,other]);
 await db.query('insert into profiles(id) values ($1),($2) on conflict do nothing',[u,other]);
 const institution=await scalar(`insert into institutions(code,name,institution_type,provider_support) values ('BCA','BCA','bank','{"simulation_supported":true}') returning id`);
 await check('sandbox disabled by default',()=>assert.rejects(db.query('select hub_connect_simulated($1,$2)',[u,institution]),/sandbox_disabled/));
 await db.exec("update feature_flags set enabled=true where id='financial_hub_sandbox'");
 const connect=async(user)=> (await db.query('select * from hub_connect_simulated($1,$2)',[user,institution])).rows[0];
 const a=await connect(u), b=await connect(u), foreign=await connect(other);
 await check('multiple accounts retain distinct identity and simulated provenance',async()=>{assert.notEqual(a.id,b.id);assert.equal(a.balance_source,'simulated');assert.equal(Number(a.balance),1000000);});
 const create=async(source=a.id,amount=100000,key='test-key-00000001',owner=u,own=null,identifier='1234567890')=>
  (await db.query('select * from hub_create_transfer($1,$2,$3,$4,$5,$6,$7,null)',[owner,source,institution,identifier,amount,key,own])).rows[0];
 await check('source ownership',()=>assert.rejects(create(foreign.id),/source_not_eligible/));
 await check('negative amount',()=>assert.rejects(create(a.id,-1),/invalid_transfer/));
 await check('fractional IDR',()=>assert.rejects(create(a.id,1.5),/invalid_transfer/));
 await check('insufficient balance',()=>assert.rejects(create(a.id,1000001),/insufficient_balance/));
 await check('own destination ownership',()=>assert.rejects(create(a.id,100,'test-key-00000002',u,foreign.id,foreign.external_id),/destination_not_owned/));
 await check('same account destination',()=>assert.rejects(create(a.id,100,'test-key-00000003',u,a.id,a.external_id),/destination_not_owned/));
 const t=await create();
 await check('transaction creation pending execution mode and mask',async()=>{assert.equal(t.status,'pending');assert.equal(t.execution_mode,'SANDBOX_SIMULATED_SOURCE');assert.equal(t.destination_account_reference,'•••• 7890');});
 await check('idempotent duplicate',async()=>assert.equal((await create()).id,t.id));
 await check('idempotency changed payload rejected',()=>assert.rejects(create(a.id,200000),/idempotency_conflict/));
 await check('pending reserves source balance',()=>assert.rejects(create(a.id,950000,'test-key-00000004'),/insufficient_balance/));
 const event=async(status,id=t.id)=>(await db.query('select * from hub_apply_simulation_event($1,$2)',[id,status])).rows[0];
 await event('processing');await event('success');
 await check('webhook success updates balance once',async()=>assert.equal(Number(await scalar('select balance from accounts where id=$1',[a.id])),900000));
 await event('success');await event('processing');
 await check('duplicate and out of order event',async()=>{assert.equal(Number(await scalar('select balance from accounts where id=$1',[a.id])),900000);assert.equal(await scalar('select status from future_transfers where id=$1',[t.id]),'success');});
 await event('reversed');await event('reversed');
 await check('reversal exactly once',async()=>assert.equal(Number(await scalar('select balance from accounts where id=$1',[a.id])),1000000));
 await db.query("select set_config('request.jwt.claim.sub',$1,false)",[other]);
 await db.exec('set role authenticated');
 await check('RLS hides another user accounts and balances',async()=>assert.equal(Number(await scalar('select count(*) from accounts where user_id=$1',[u])),0));
 await check('RLS hides another user transfers',async()=>assert.equal(Number(await scalar('select count(*) from future_transfers')),0));
 await check('client cannot write provider outcome',()=>assert.rejects(db.query("update future_transfers set status='success' where id=$1",[t.id]),/permission denied/));
 await check('client cannot fabricate a connection',()=>assert.rejects(db.query("update accounts set balance_source='live' where id=$1",[foreign.id]),/connection_server_only/));
 await check('client cannot inflate connected balance',()=>assert.rejects(db.query('update accounts set balance=9000000 where id=$1',[foreign.id]),/connection_server_only/));
 await check('client cannot invoke privileged transfer',()=>assert.rejects(create(),/permission denied/));
 await check('default account ownership',()=>assert.rejects(db.query('select hub_set_primary($1)',[a.id]),/account_not_owned/));
 await check('client cannot write connections',()=>assert.rejects(db.query("insert into account_connections(user_id,institution_id) values ($1,$2)",[other,institution]),/permission denied/));
 await check('manual ledger cannot modify connected balance',()=>assert.rejects(db.query("insert into transactions(user_id,account_id,kind,amount) values ($1,$2,'income',100)",[other,foreign.id]),/connected_ledger_server_only/));
 await check('RLS blocks cross-user account modification',async()=>{const result=await db.query("update accounts set name='attacker' where id=$1 returning id",[a.id]);assert.equal(result.rows.length,0);});
 await check('default own account works',async()=>{await db.query('select hub_set_primary($1)',[foreign.id]);assert.equal(await scalar('select is_primary from accounts where id=$1',[foreign.id]),true);});
 await db.exec('reset role');
 const own=await create(a.id,10000,'test-key-own-00001',u,b.id,b.external_id);
 await event('success',own.id);
 await check('own transfer credits destination without platform wallet',async()=>assert.equal(Number(await scalar('select balance from accounts where id=$1',[b.id])),1010000));
 await event('reversed',own.id);
 await check('own reversal restores both account balances',async()=>{assert.equal(Number(await scalar('select balance from accounts where id=$1',[b.id])),1000000);assert.equal(Number(await scalar('select balance from accounts where id=$1',[a.id])),1000000);});
 await db.query('select recompute_account_balance($1)',[a.id]);
 await check('server imported ledger does not overwrite provider snapshot',async()=>assert.equal(Number(await scalar('select balance from accounts where id=$1',[a.id])),1000000));
 for(let i=0;i<3;i++)await create(a.id,1,'rate-limit-test-000'+i);
 await check('rate limit',()=>assert.rejects(create(a.id,1,'rate-limit-test-final'),/rate_limited/));
 console.log('DATABASE_TEST_COUNT: '+count);
} catch(error){console.error(error.message);process.exitCode=1;} finally {await db.close();}
