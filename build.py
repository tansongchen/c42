from shutil import rmtree, copytree
from typing import Tuple, Dict

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
    copytree('config', 'build')
    copytree('opencc', 'build/opencc')
    copytree('lua', 'build/lua')

    with open('build/c42.dict.yaml', 'a') as c42Dict:
        for char, code in brevity.items():
            c42Dict.write(f'{char}\t{code}\n')
            c42Dict.write(f'　\t{code}\n')

    with open('build/c42a.dict.yaml', 'a') as c42aDict:
        selections = 0
        key = 'abcdefghijklmnopqrstuvwxyz;'
        allL3Codes = [x + y + z for x in key for y in key for z in key]
        existingL3Codes = set()
        for char, code in full.items():
            if char in brevity:
                c42aDict.write(f'{char}\t~{code}\n')
            elif char in specialty:
                specialtyCode = specialty[char]
                c42aDict.write(f'{char}\t~{code}\n')
                c42aDict.write(f'{char}\t{specialtyCode}\n')
                existingL3Codes.add(specialtyCode)
            else:
                c42aDict.write(f'{char}\t{code}\n')
                # may need selection
                if code in existingL3Codes:
                    selections += 1
                existingL3Codes.add(code)
        for code in [x for x in allL3Codes if x not in existingL3Codes]:
            c42aDict.write(f'　\t{code}\n')
        print('selections:', selections)

    with open('build/opencc/char.txt', 'w') as filterBrevityChar:
        for char, code in brevity.items():
            if len(char) > 1 or char == '　': continue
            if code != full[char][:2]:
                if code[-1] in ',./':
                    filterBrevityChar.write(f'{char}\t~{code}\n')
                else:
                    filterBrevityChar.write(f'{char}\t~~{code}\n')
            else:
                filterBrevityChar.write(f'{char}\t{code}\n')

    with open('build/opencc/word.txt', 'w') as filterBrevityWord:
        for char, code in brevity.items():
            if len(char) == 1: continue
            filterBrevityWord.write(f'{char}\t{code}\n')

    with open('build/opencc/disassembly.txt', 'w') as filterDisassembly:
        for char, code in disassembly.items():
            filterDisassembly.write(f'{char}\t{code}\n')

    with open('build/phrase.txt', 'w') as filterPhrase:
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
                filterPhrase.write(f'{char}: {0}; {" ".join([p[1:] for p in phraseList])}\n')

if __name__ == '__main__':
    write(*read())
