@echo off
set MAPROOT="../../_maps/"
set TGM=0
python3 mapmerger.py %1 %MAPROOT% %TGM%
pause
