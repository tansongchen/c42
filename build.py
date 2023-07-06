from shutil import rmtree, copyfile
from typing import Tuple, Dict
from os import makedirs

D = Dict[str, str]

def read() -> Tuple[D, D, D, D]:
    componentKey = {'': ''}
    componentName = {'': ''}
    with open('assets/keymap.dat') as keymapFile:
        for line in keymapFile:
            component, key, name = line.strip('\n').split('\t')
            componentKey[component] = key
            componentName[component] = name if name else component

    with open('assets/brevity.dat') as brevityFile:
        brevity = dict([line.strip('\n').split('\t') for line in brevityFile])
    with open('assets/specialty.dat') as specialtyFile:
        specialty = dict([line.strip('\n').split('\t') for line in specialtyFile])

    disassembly = {}
    full = {}
    with open('assets/decomposition.dat') as decompositionFile:
        toFull = lambda c: chr(ord(c) + 65248)
        for line in decompositionFile:
            char, s1, s2, s3, py, isPartial = line.strip('\n').split('\t')
            if isPartial == '1': continue
            PY = ''.join([toFull(char) for char in py.upper()])
            disassembly[char] = (componentName[s1] + componentName[s2] + componentName[s3] + PY)[:3]
            full[char] = (componentKey[s1] + componentKey[s2] + componentKey[s3] + py)[:3]
    return brevity, specialty, disassembly, full

def write(brevity: D, specialty: D, disassembly: D, full: D):
    rmtree('build', ignore_errors=True)
    makedirs('build')
    makedirs('build/opencc')
    copyfile('config/c42.dict.meta.yaml', 'build/c42.dict.yaml')
    copyfile('config/c42a.dict.meta.yaml', 'build/c42a.dict.yaml')

    with open('build/c42.dict.yaml', 'a') as c42Dict:
        for char, code in brevity.items():
            c42Dict.write('%s\t%s\n' % (char, code))
            c42Dict.write('　\t%s\n' % code)

    with open('build/c42a.dict.yaml', 'a') as c42aDict:
        key = 'abcdefghijklmnopqrstuvwxyz;'
        all3 = [x + y + z for x in key for y in key for z in key]
        c3 = set()
        for char, code in full.items():
            c3.add(code)
            if char in brevity or char in specialty:
                c42aDict.write('%s\t~%s\n' % (char, code))
            else:
                c42aDict.write('%s\t%s\n' % (char, code))
        for code in [x for x in all3 if x not in c3]:
            c42aDict.write('　\t~%s\n' % code)
        for char, code in specialty.items():
            c42aDict.write('%s\t%s\n' % (char, code))

    with open('build/opencc/char.txt', 'w') as filterBrevityChar:
        for char, code in brevity.items():
            if len(char) > 1 or char == '　': continue
            if code != full[char][:2]:
                if code[-1] in ',./':
                    filterBrevityChar.write('%s\t~%s\n' % (char, code))
                else:
                    filterBrevityChar.write('%s\t~~%s\n' % (char, code))
            else:
                filterBrevityChar.write('%s\t%s\n' % (char, code))

    with open('build/opencc/word.txt', 'w') as filterBrevityWord:
        for char, code in brevity.items():
            if len(char) == 1: continue
            filterBrevityWord.write('%s\t%s\n' % (char, code))

    with open('build/opencc/disassembly.txt', 'w') as filterDisassembly:
        for char, code in disassembly.items():
            filterDisassembly.write('%s\t%s\n' % (char, code))

    with open('build/opencc/phrase.txt', 'w') as filterPhrase:
        association = {k: [] for k in full}
        association['的'] = []
        with open('assets/wordFrequencies.dat') as f:
            for line in f:
                word, _ = line.strip().split()
                char = word[0]
                if len(association.get(char, [])) < 5:
                    association[char].append(word)
        for char, phraseList in association.items():
            if phraseList:
                filterPhrase.write('%s %s\n' % (char, ' '.join([p[1:] for p in phraseList])))

    for name in ('c42.schema', 'c42a.schema', 'symbols_for_c'):
        copyfile(f'config/{name}.yaml', f'build/{name}.yaml')
    for name in ('char', 'word', 'disassembly'):
        copyfile(f'config/{name}.json', f'build/opencc/{name}.json')

if __name__ == '__main__':
    write(*read())
