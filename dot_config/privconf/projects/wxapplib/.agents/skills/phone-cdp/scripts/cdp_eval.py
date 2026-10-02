#!/usr/bin/env python3
import json, subprocess, sys, os, re
URL = os.environ.get('AUTO_MCP_URL', 'https://miniprogram-automator-mcp.mcp.woa.com')
TOKEN = os.environ['TAI_TOKEN']
SIDFILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'mcp-sid.txt')

def curl(payload, extra=None):
    args = ['curl','-sS','-m','150','-X','POST',URL,
        '-H',f'Authorization: Bearer {TOKEN}','-H','Content-Type: application/json',
        '-H','Accept: application/json, text/event-stream']
    if os.path.exists(SIDFILE):
        args += ['-H', f'mcp-session-id: {open(SIDFILE).read().strip()}']
    if extra: args += extra
    args += ['-D', '/tmp/hdr.txt', '-d', json.dumps(payload)]
    return subprocess.run(args, capture_output=True, text=True).stdout

def ensure_session():
    if os.path.exists(SIDFILE): return
    curl({'jsonrpc':'2.0','id':1,'method':'initialize','params':{'protocolVersion':'2025-06-18','capabilities':{},'clientInfo':{'name':'opencode','version':'1.0'}}})
    hdr = open('/tmp/hdr.txt').read()
    m = re.search(r'mcp-session-id:\s*(\S+)', hdr, re.I)
    if m: open(SIDFILE,'w').write(m.group(1))
    curl({'jsonrpc':'2.0','method':'notifications/initialized'})

def rpc(payload):
    out = curl(payload)
    for line in out.splitlines():
        if line.startswith('data: '):
            return json.loads(line[6:])
    return {'raw': out[:800]}

def call(name, args, i=[100]):
    i[0]+=1
    r = rpc({'jsonrpc':'2.0','id':i[0],'method':'tools/call','params':{'name':name,'arguments':args}})
    res = r.get('result',{})
    for c in res.get('content',[]):
        if c.get('type')=='text':
            try: return json.loads(c['text'])
            except: return c['text']
    return res

def cdp(method, params=None):
    return call('send_command', {'type':'cdp','method':method,'params':params or {},'timeout':30})

def ev(expr, **kw):
    p = {'expression': expr, 'returnByValue': True}
    p.update(kw)
    return cdp('Runtime.evaluate', p)

if __name__ == '__main__':
    ensure_session()
    expr = sys.argv[1] if len(sys.argv)>1 else '1+1'
    print(json.dumps(ev(expr), ensure_ascii=False)[:3000])
