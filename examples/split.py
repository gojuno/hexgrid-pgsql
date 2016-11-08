import os
import sys

for line in sys.stdin:
    if line.startswith('=>'):
        _, file = line.split('=> ')
        line = next(sys.stdin)
        with open(os.path.join('results', file.strip()), 'w') as fd:
            fd.write(line.strip())
