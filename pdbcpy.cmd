@echo on
for /R %1 %%f in (*.pdb) do copy "%%f" "%2\*"