curl http://www.ic.unicamp.br/~edson/disciplinas/mc404/2019-2s/ab/labs/lab05/bridge.py > /tmp/bridge.py
riscv32-unknown-elf-gdb uoli.x -ex 'target remote | python3 /tmp/bridge.py'
