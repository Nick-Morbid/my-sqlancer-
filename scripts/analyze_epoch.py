#!/usr/bin/env python3
import argparse, csv, gzip, io, json, re
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('--epoch',required=True); a=p.parse_args(); root=Path(a.epoch)
stats={'server_statements':0,'server_successful_statements':0,'server_failed_statements':0,
       'server_success_percent':None,'latest_executed_queries':None,
       'latest_successful_statement_percent':None,'feedback_updates':0,
       'unsupported_feature_messages':0}
text=''
for chunk in sorted((root/'runtime').rglob('*.chunk.gz')):
    if 'stdout' in chunk.name:
        with gzip.open(chunk,'rt',errors='replace') as f: text += f.read()
progress=re.findall(r'Executed (\d+) queries .*successful statements:\s*([0-9.]+)%',text)
if progress:
    stats['latest_executed_queries']=int(progress[-1][0]); stats['latest_successful_statement_percent']=float(progress[-1][1])
stats['feedback_updates']=len(re.findall(r'Success rate for (?:query pairs|statements):',text))
stats['unsupported_feature_messages']=len(re.findall(r'is not available|unsupported',text,re.I))
active={}
for chunk in sorted((root/'postgres').rglob('*.chunk.gz')):
    if '.csv.bytes-' not in chunk.name and '.csv.csv.bytes-' not in chunk.name: continue
    try:
        with gzip.open(chunk,'rb') as raw:
            for row in csv.reader(io.TextIOWrapper(raw,errors='replace',newline='')):
                if len(row)<23 or row[22] != 'SQLancerPlusPlus-24h': continue
                msg,session,severity=row[13],row[5],row[11]
                statement=msg.startswith('statement: ') or (msg.startswith('execute ') and ':' in msg)
                if statement:
                    stats['server_statements']+=1; stats['server_successful_statements']+=1; active[session]=True
                elif severity in {'ERROR','FATAL','PANIC'} and active.get(session):
                    stats['server_successful_statements']-=1; stats['server_failed_statements']+=1; active[session]=False
    except (csv.Error,EOFError,UnicodeDecodeError): pass
if stats['server_statements']:
    stats['server_success_percent']=round(100*stats['server_successful_statements']/stats['server_statements'],6)
(root/'metrics.json').write_text(json.dumps(stats,indent=2)+'\n')

