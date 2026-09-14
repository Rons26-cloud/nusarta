// Operator-only simulator callback sender. Never invokes a payment provider.
import { createHmac } from 'node:crypto';
const [transferId,status='success']=process.argv.slice(2);
const allowed=new Set(['processing','success','failed','reversed']);
if(!/^[0-9a-f-]{36}$/i.test(transferId??'') || !allowed.has(status)) throw Error('Supply a simulation transfer UUID and valid status');
const callbackUrl=new URL(process.env.NUSARTA_SIMULATOR_CALLBACK_URL??'http://127.0.0.1:54321/functions/v1/brankas-callback');
if(!['localhost','127.0.0.1','[::1]'].includes(callbackUrl.hostname)) throw Error('This helper is restricted to a local callback server');
const secret=process.env.NUSARTA_SIMULATOR_CALLBACK_SECRET;
if(!secret || secret.length<32) throw Error('Configure the local simulator callback secret outside source control');
const raw=JSON.stringify({transfer_id:transferId,status,timestamp:Date.now()});
const signature=createHmac('sha256',secret).update(raw).digest('hex');
const response=await fetch(callbackUrl,{method:'POST',headers:{'content-type':'application/json','x-nusarta-simulator-signature':signature},body:raw});
console.log('SIMULATOR_CALLBACK_HTTP_STATUS: '+response.status);
if(!response.ok) process.exitCode=1;
