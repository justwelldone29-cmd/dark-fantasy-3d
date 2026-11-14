"""Сжимает файлы assets без изменения текстур и геометрии. После нужен zipalign и подпись."""
import sys, zipfile
source,destination=sys.argv[1:]
with zipfile.ZipFile(source) as src, zipfile.ZipFile(destination,'w',allowZip64=True) as dst:
    for item in src.infolist():
        if item.filename.startswith('META-INF/'):continue
        data=src.read(item.filename)
        if item.filename.startswith('assets/'):
            item.compress_type=zipfile.ZIP_DEFLATED
        dst.writestr(item,data,compresslevel=6)
