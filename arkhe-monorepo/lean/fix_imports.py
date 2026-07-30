import os

def fix_file(path):
    with open(path, 'r') as f:
        content = f.read()

    # We need to make sure the imports are right after the module docstring `/-! ... -/`
    import re
    # Match the module docstring
    m = re.match(r'(/-\!.*?-\/)\s*(.*)', content, re.DOTALL)
    if m:
        docstring = m.group(1)
        rest = m.group(2)

        imports = []
        lines = rest.split('\n')
        other_lines = []
        for line in lines:
            if line.startswith('import '):
                imports.append(line)
            else:
                other_lines.append(line)

        new_content = '\n'.join(imports) + '\n\n' + docstring + '\n\n' + '\n'.join(other_lines)
        with open(path, 'w') as f:
            f.write(new_content)
    else:
        # no module docstring
        pass

for root, _, files in os.walk('CathedralArkhe'):
    for f in files:
        if f.endswith('.lean'):
            fix_file(os.path.join(root, f))
