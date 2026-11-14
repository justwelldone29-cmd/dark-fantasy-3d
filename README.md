# Северный предел — Dark Fantasy Mobile 0.4.0

Мобильный прототип RPG на Godot 4.5.1: **вид от третьего лица**, сенсорный джойстик,
свайп камеры, прыжок, ближний бой, три стража и цель в крепости.

[Скачать APK для Android arm64, версия 0.4.0](https://github.com/justwelldone29-cmd/dark-fantasy-3d/raw/refs/heads/main/apk/dark-fantasy-mobile.apk)

В этой версии: одобренный скелет с материалами кости и гладкой железной брони,
его исходный риг и анимации; полный The Forgotten Knight (223 711 треугольников,
без упрощения геометрии), анимации Quaternius с ретаргетингом на 50 костей;
девять больших и средних сосен LOLIPOP, PBR-камень и земля, холодный свет и туман.
Маленькие сосны не используются. Размеры skinned-модели рассчитываются по позе.

## Запуск проекта

Открыть `project.godot` в **Godot 4.5.1** и нажать F5. Сцена `scenes/Main.tscn` уже
соединяет игрока, UI, бой, врагов и окружение. Слева — плавающий джойстик,
справа — обзор и кнопки. Кнопка «Авторы» открывает лицензии в игре.

Основные файлы:
- `scripts/Player.gd`, `HumanoidVisual.gd`: контроллер и полная модель героя.
- `scripts/MobileUI.gd`: сенсорный ввод и кнопки.
- `scripts/Combat.gd`: урон, направление удара, препятствия и кулдаун.
- `scripts/Enemy.gd`, `ImportedEnemy.gd`: ИИ, модель, её анимации и смерть.
- `scripts/WorldBuilder.gd`, `PineForest.gd`: крепость, материалы и MultiMesh-сосны.
- `assets/CREDITS.txt`: авторы, источники, лицензии и изменения моделей.

## Автоматическая сборка APK

`.github/workflows/build_apk.yml` запускается на каждом push в `main` и вручную.
Ubuntu устанавливает Java 17, SDK Android 35, Build Tools 35.0.0, Godot 4.5.1
и **совпадающие export templates 4.5.1** из официального GitHub-релиза Godot.
После импорта и проверок проект экспортируется в APK. Упаковка assets дополнительно
сжимается без изменения их содержимого, APK выравнивается и подписывается заново.
Готовый файл — артефакт `dark-fantasy-android-<номер>`.

Обычная debug-сборка работает без Secrets. Для ручной release-сборки нужны:
- `ANDROID_KEYSTORE_BASE64`: keystore, закодированный в Base64;
- `ANDROID_KEYSTORE_PASSWORD`: одинаковый пароль keystore и ключа;
- `ANDROID_KEY_ALIAS`: alias ключа.

Для обновления установленной игры используйте один и тот же ключ. CI создаёт
новый debug-ключ на каждый запуск; опубликованный здесь APK подписан сохранённым
локальным debug-ключом. Он предназначен для проверки, а не для публикации в магазине.

Локально настройте `RUNNER_TEMP`, `ANDROID_HOME`, `JAVA_HOME`, выполните
`python3 ci/configure_export.py`, затем:

```sh
godot --headless --path . --editor --import
godot --headless --path . --script ci/verify_humanoid.gd
godot --headless --path . --script ci/verify_gameplay.gd
godot --headless --path . --export-debug Android build/game.apk
```

Проверены импорт, полная геометрия героя, сопоставление костей, основные анимации,
сигналы обработчика сенсорного джойстика и перемещение игрока, урон, кулдаун и смерть.
Сцена осмотрена в Compatibility renderer на Linux. Производительность и установка
на физическом Android-устройстве в этой среде не проверялись.

## Авторы

The Forgotten Knight — [dark_igorek](https://sketchfab.com/3d-models/the-forgotten-knight-d14eb14d83bd4e7ba7cbe443d76a10fd), CC BY 4.0.
Геометрия сохранена, добавлены ретаргетинг и крепление меча.

Low Poly Skull — [ImageParSeconde](https://sketchfab.com/3d-models/low-poly-skull-f3f370aaaa524ccab93ee77b86c81ba2), CC BY 4.0.
Изменены UV, материалы и сглаживание брони; риг и девять клипов сохранены.

Pine trees pack — [LOLIPOP](https://sketchfab.com/3d-models/pine-trees-pack-lowpoly-game-ready-lods-e1e9c07b8e2e445c943fec660beefba2), CC BY 4.0.
Выбраны big/large/medium LOD0, изменены масштаб и размещение.

[Лицензия CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Quaternius UAL, Kenney Graveyard Kit, Poly Haven PBR и ambientCG Rock058 — CC0.
Подробности и ссылки: [assets/CREDITS.txt](assets/CREDITS.txt).
Материалы скелета созданы локально; материалы PlanetAlexander и Metal056A не использованы.
