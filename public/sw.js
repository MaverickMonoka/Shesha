const CACHE='shesha-shell-v2';
const SHELL=['/','/manifest.webmanifest','/shesha-icon-192.png','/shesha-icon-512.png','/shesha-wordmark.webp','/shesha-emblem.webp'];
self.addEventListener('install',event=>event.waitUntil((async()=>{
 const cache=await caches.open(CACHE);
 const page=await fetch('/',{cache:'reload'});
 if(!page.ok)throw new Error('App shell unavailable');
 const html=await page.clone().text();await cache.put('/',page);
 const assets=[...html.matchAll(/(?:src|href)=["'](\/assets\/[^"']+)["']/g)].map(x=>x[1]);
 // Install only once the app's own script and stylesheet can load offline.
 await cache.addAll(assets);
 await Promise.allSettled(SHELL.slice(1).map(url=>cache.add(url)));
 await self.skipWaiting();
})()));
self.addEventListener('activate',event=>event.waitUntil((async()=>{
 const keys=await caches.keys();await Promise.all(keys.filter(k=>k.startsWith('shesha-shell-')&&k!==CACHE).map(k=>caches.delete(k)));await self.clients.claim();
})()));
self.addEventListener('fetch',event=>{
 const req=event.request,url=new URL(req.url);
 if(req.method!=='GET'||url.origin!==self.location.origin||url.pathname.startsWith('/api/')||url.pathname.startsWith('/v1/'))return;
 if(req.mode==='navigate'){event.respondWith((async()=>{
  try{const fresh=await fetch(req);if(fresh.ok&&fresh.headers.get('content-type')?.includes('text/html')){const cache=await caches.open(CACHE);await cache.put('/',fresh.clone())}return fresh}
  catch{return(await caches.match('/'))||new Response('Reconnect to open SHESHA.',{status:503,headers:{'Content-Type':'text/plain'}})}
 })());return}
 if(['script','style','image','font'].includes(req.destination)){event.respondWith((async()=>{
  const cached=await caches.match(req);if(cached)return cached;
  const response=await fetch(req);if(response.ok){const cache=await caches.open(CACHE);await cache.put(req,response.clone())}return response;
 })())}
});
