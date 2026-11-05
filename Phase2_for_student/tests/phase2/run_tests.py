#!/usr/bin/env python3
"""Phase 2 regression runner. Default: NC-Sim sample plus sequential/reset suite.
No third-party Python packages are required. Run from Phase2_for_student/.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys
import time

HERE=Path(__file__).resolve().parent


def validate():
    from model import execute, self_test
    self_test()
    manifest=json.loads((HERE/'manifest.json').read_text())['cases']
    listed=(HERE/'sequence.list').read_text().splitlines()
    if listed!=['tests/phase2/programs/'+case['name'] for case in manifest]:
        raise ValueError('sequence.list must contain every manifest case in order')
    names=set()
    for case in manifest:
        if case['name'] in names:raise ValueError('Duplicate case '+case['name'])
        names.add(case['name']);folder=HERE/'programs'/case['name']
        for name,digest in case['sha256'].items():
            if hashlib.sha256((folder/name).read_bytes()).hexdigest()!=digest:
                raise ValueError('Test asset changed: '+str(folder/name)+'; regenerate or update manifest')
        lines=(folder/'imem.fill').read_text().splitlines()
        if len(lines)!=256 or not all(re.fullmatch(r'[0-9A-F]{8} // .+',s) for s in lines):
            raise ValueError('Invalid/commentless program '+case['name'])
        words=[int(s.split()[0],16) for s in lines]
        end=words.index(0)
        if words[end-2:end]!=[0xF0000000]*2:raise ValueError('Missing termination padding '+case['name'])
        data=[int(s,16) for s in (folder/'dmem.fill').read_text().splitlines()]
        expected=[int(s,16) for s in (folder/'expected.hex').read_text().splitlines()]
        if len(data)!=256 or len(expected)!=256:raise ValueError('Incomplete memory '+case['name'])
        final,stores,end_pc,_=execute(words,data)
        if final!=expected or end_pc!=case['end_pc'] or len(stores)!=case['expected_stores']:
            raise ValueError('Reference mismatch '+case['name'])
        metadata=[int(s) for s in (folder/'meta.txt').read_text().split()]
        if metadata!=[len(stores),end_pc,int(case['trace_check'])]:
            raise ValueError('Metadata mismatch '+case['name'])
        parsed=[]
        for i,line in enumerate((folder/'expected.dump').read_text().splitlines()):
            match=re.fullmatch(r'Memory location # (\d+) : ([0-9a-f]{16})',line)
            if not match or int(match[1])!=i:raise ValueError('Bad expected dump '+case['name'])
            parsed.append(int(match[2],16))
        if parsed!=expected:raise ValueError('Dump/hex mismatch '+case['name'])
        trace=[int(s,16) for s in (folder/'stores.fill').read_text().splitlines() if not s.startswith('//')]
        if trace!=[(a<<64)|v for a,v in stores]:raise ValueError('Store trace mismatch '+case['name'])
    return manifest


def sample_pass(text,returncode):
    return (returncode==0 and 'TEST PASSED:' in text and 'The program completed in ' in text
            and not any(s in text for s in ['TEST FAILED','MISMATCH','WARNING: no end-of-program','HOST TIMEOUT']))


def sequence_pass(text,returncode,expected_programs):
    match=re.search(r'SEQUENCE PASSED programs=(\d+) reset_interruptions=14',text)
    return (returncode==0 and match is not None and int(match[1])==expected_programs
            and 'FAIL' not in text and 'HOST TIMEOUT' not in text)


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check-only',action='store_true')
    parser.add_argument('--backend',choices=['ncsim','iverilog'],default='ncsim')
    parser.add_argument('--mode',choices=['all','sequence','standalone','sample'],default='all',
                        help='all runs original sample and all cases in one persistent simulation')
    parser.add_argument('--case',help='One case through the original testbench; implies standalone mode')
    parser.add_argument('--model',action='append',default=[],help='External DesignWare model file for Icarus; repeat as needed')
    parser.add_argument('--iverilog',default='iverilog');parser.add_argument('--vvp',default='vvp')
    parser.add_argument('--timeout',type=int,default=900,help='Wall-clock seconds per tool process')
    args=parser.parse_args()
    cases=validate()
    if args.check_only:
        print('Validated %d programs, expected memory images, store traces and reference model'%len(cases));return 0
    root=Path.cwd()
    if not(root/'design/cardinal_cpu.v').is_file() or not(root/'makefile').is_file():
        parser.error('Run from Phase2_for_student/ with tests/phase2 installed inside it')
    try: rel=HERE.relative_to(root)
    except ValueError:parser.error('The tests/phase2 directory must be inside the project root')
    if str(rel)!='tests/phase2':parser.error('Install the suite at tests/phase2 (paths in sequence.list use this location)')
    if args.case:
        if args.case not in {c['name'] for c in cases}:parser.error('Unknown case '+args.case)
        cases=[c for c in cases if c['name']==args.case];args.mode='standalone'
    if args.backend=='iverilog' and not args.model:parser.error('Supply real external DW model files with --model; no replacement models are bundled')
    logs=root/'work'/'phase2-results';logs.mkdir(parents=True,exist_ok=True)
    records=[]
    started=time.strftime('%Y-%m-%dT%H:%M:%S%z')
    hashes={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
            for p in sorted((root/'design').glob('*.v'))}
    hashes.update({str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest()
                   for p in [root/'include/imem.v',root/'include/dmem.v',root/'tb/tb_cardinal_cpu.v',root/'makefile']})
    try: revision=subprocess.check_output(['git','rev-parse','HEAD'],cwd=root,stderr=subprocess.DEVNULL,universal_newlines=True).strip()
    except (OSError,subprocess.CalledProcessError):revision='not available; use source file hashes'
    def run(command,name):
        print('Running '+name,flush=True)
        try:
            result=subprocess.run(command,cwd=root,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,
                                  universal_newlines=True,timeout=args.timeout)
            code,text=result.returncode,result.stdout
        except subprocess.TimeoutExpired as exc:
            text=exc.stdout or b''
            if isinstance(text,bytes):text=text.decode(errors='replace')
            code,text=124,text+'\nHOST TIMEOUT\n'
        except OSError as exc:code,text=127,str(exc)
        (logs/(name+'.log')).write_text(text)
        return code,text
    def compile_top(top,tb):
        if args.backend=='ncsim':
            command=['make','-B','elab~','TOP='+top,'TB_FILE='+tb]
        else:
            command=[args.iverilog,'-g2005','-s',top,'-o',str(logs/(top+'.vvp'))]
            command += [str(p) for p in sorted((root/'design').glob('*.v'))]+args.model+[tb]
        code,text=run(command,'compile_'+top)
        records.append({'test':'compile_'+top,'passed':code==0,'returncode':code})
        return code==0
    def simulate(top,tb,extra,name,sequence=False):
        if args.backend=='ncsim':
            command=['make','sim' if sequence else 'test','TOP='+top,'TB_FILE='+tb,
                     'SIM_SCRIPT_FILE_NO_GUI=tests/phase2/run.tcl']+extra
        else:
            command=[args.vvp,str(logs/(top+'.vvp'))]
            command += [item if item.startswith('+') else '+'+item for item in extra]
        return run(command,name)
    try:
        if args.mode in ['all','sample','standalone']:
            if not compile_top('tb_cardinal_cpu','tb/tb_cardinal_cpu.v'):raise RuntimeError('Original testbench compilation failed')
            jobs=[None] if args.mode in ['all','sample'] else cases
            for case in jobs:
                prefix='tests/phase2/programs/'+case['name']+'/' if case else ''
                name=case['name'] if case else 'provided_sample'
                expected='expected.dump' if case else 'expected_dmem.dump'
                extra=['IMEM='+prefix+'imem.fill','DMEM='+prefix+'dmem.fill','EXPECTED='+prefix+expected,
                       'DUMP=work/phase2-results/'+name+'.actual.dump']
                code,text=simulate('tb_cardinal_cpu','tb/tb_cardinal_cpu.v',extra,name)
                good=sample_pass(text,code)
                if case:good=good and 'TEST PASSED: all 256 memory locations match' in text
                records.append({'test':name,'passed':bool(good),'returncode':code})
                print(('PASS ' if good else 'FAIL ')+name,flush=True)
        if args.mode in ['all','sequence']:
            top='tb_phase2_sequence';tb='tests/phase2/tb_phase2_sequence.v'
            if not compile_top(top,tb):raise RuntimeError('Sequential testbench compilation failed')
            extra=['SIM_ARGS=+CASELIST=tests/phase2/sequence.list'] if args.backend=='ncsim' else ['+CASELIST=tests/phase2/sequence.list']
            code,text=simulate(top,tb,extra,'sequence',True)
            good=sequence_pass(text,code,len(cases)+14)
            records.append({'test':'sequence','passed':bool(good),'returncode':code,
                            'expected_runs':len(cases)+14,
                            'case_passes':len(re.findall(r'^CASE PASS ',text,re.M)),
                            'case_failures':re.findall(r'^CASE FAIL (.+)$',text,re.M)})
            print('PASS sequence' if good else 'FAIL sequence',flush=True)
    except RuntimeError as exc:
        print(str(exc),file=sys.stderr)
    finally:
        result={'backend':args.backend,'external_models':args.model,'started':started,'source_revision':revision,
                'source_sha256':hashes,'manifest_sha256':hashlib.sha256((HERE/'manifest.json').read_bytes()).hexdigest(),
                'records':records,'passed':bool(records) and all(r['passed'] for r in records)}
        (logs/'results.json').write_text(json.dumps(result,indent=2)+'\n')
        lines=['# Phase 2 run results','', 'Backend: '+args.backend,'Started: '+started,'Revision: '+revision,
               '', '**Overall: '+('PASS' if result['passed'] else 'FAIL')+'**','']
        lines += ['- '+r['test']+': '+('PASS' if r['passed'] else 'FAIL') for r in records]
        lines += ['','Source hashes and detailed records: results.json.','Raw logs/actual dumps are verification artifacts; exclude them from the final submission.']
        (logs/'RESULTS.md').write_text('\n'.join(lines)+'\n')
    print('Results saved in work/phase2-results; copy the outcome into your report before make clean.')
    return 0 if result['passed'] else 1

if __name__=='__main__':sys.exit(main())
