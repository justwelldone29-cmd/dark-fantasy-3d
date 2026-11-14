"""Создаёт настройки экспорта; секреты не попадают в репозиторий."""
import json
import os
from pathlib import Path


def quoted(value):
    return json.dumps(str(value), ensure_ascii=False)


config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config')))
settings = config / 'godot' / 'editor_settings-4.5.tres'
settings.parent.mkdir(parents=True, exist_ok=True)
settings.write_text(
    '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
    f'export/android/android_sdk_path = {quoted(os.environ["ANDROID_HOME"])}\n'
    f'export/android/java_sdk_path = {quoted(os.environ["JAVA_HOME"])}\n',
    encoding='utf-8',
)
release = os.environ.get('RELEASE_BUILD') == 'true'
password = os.environ.get('KEYSTORE_PASSWORD', '') if release else 'android'
alias = os.environ.get('KEY_ALIAS', '') if release else 'androiddebugkey'
keystore = Path(os.environ['RUNNER_TEMP']) / ('release.keystore' if release else 'debug.keystore')
if release and (not password or not alias or not keystore.is_file()):
    raise SystemExit('Для release нужны ANDROID_KEYSTORE_BASE64, ANDROID_KEYSTORE_PASSWORD и ANDROID_KEY_ALIAS')

preset = '''[preset.0]
name="Android"
platform="Android"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="assets/CREDITS.txt"
exclude_filter="assets/animations/kaykit/combat.glb,ci/*,README.md,.github/*,export_presets.cfg,*.keystore,*.jks"
export_path="build/game.apk"
script_export_mode=2

[preset.0.options]
custom_template/debug=""
custom_template/release=""
gradle_build/use_gradle_build=false
architectures/armeabi-v7a=false
architectures/arm64-v8a=true
version/code=9
version/name="0.5.2"
package/unique_name="org.example.darkfantasymobile"
package/name="Dark Fantasy Mobile"
package/signed=true
screen/immersive_mode=true
'''
kind = 'release' if release else 'debug'
for key, value in [('keystore', keystore), ('user', alias), ('password', password)]:
    preset += f'keystore/{kind if key == "keystore" else kind + "_" + key}={quoted(value)}\n'
Path('export_presets.cfg').write_text(preset, encoding='utf-8')
