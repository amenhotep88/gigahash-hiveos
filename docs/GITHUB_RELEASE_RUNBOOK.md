# GitHub и выпуск GigaHash HiveOS package

## AMD v2.2 release

AMD выпускается отдельно от NVIDIA:

```text
Workflow: .github/workflows/publish-v2.2-amd.yml
Tag: v2.2.0-amd2
Package: gigahash-amd-2.2.0.tar.gz
Official binary: gigahash-zk-rocm10.0
Official binary SHA256: a9bcf774b394956ef2eb0af15d9886e976abd5ab04c27d0eb5b990e9b7427019
Package SHA256: d18b421071fb2df6abdaa9fcf0eab5da24b04aa1015d21443c497cbaf66ed1db
```

Workflow скачивает официальный ROCm binary, проверяет version/SHA, воспроизводимо создаёт archive, режет его на 137 jsDelivr parts, запускает AMD test/build, коммитит package+parts и создаёт отдельный GitHub Release. Не добавлять AMD assets в NVIDIA release/tag.

Локальный gate перед push:

```bash
bash -n h-common.sh h-config-amd.sh h-run-amd.sh h-stats-amd.sh build-amd.sh
bash tests/test_release_2_2_amd.sh
./build-amd.sh
echo 'd18b421071fb2df6abdaa9fcf0eab5da24b04aa1015d21443c497cbaf66ed1db  gigahash-amd-2.2.0.tar.gz' | sha256sum -c -
tar -tzf gigahash-amd-2.2.0.tar.gz
```

После push проверить workflow, bot commit с `vendor/gigahash-zk-rocm10.0-2.2.tar.gz.part-*`, tag `v2.2.0-amd2`, release asset и jsDelivr Installation URL.

## 1. Репозиторий и модель релиза

- Repository: `https://github.com/amenhotep88/gigahash-hiveos`
- Active branch: `main`
- Active product: один обычный GigaHash ZK HiveOS package
- Current tag scheme: official-wrapper package version, например `v2.0.0`
- Split/PRL assets запрещены текущим решением проекта.

## 2. Авторизация

Read-only проверки разрешены при диагностике. Перед `push`, созданием/изменением Release, удалением asset/tag или force operation необходимо явное разрешение пользователя на конкретное действие.

Никогда не переписывать опубликованную историю без отдельного предупреждения и прямого разрешения. Обычное удаление компонента делается новым коммитом.

## 3. Preflight

```bash
git status --short --branch
git remote -v
git fetch origin
git log --oneline --decorate --graph -12
git diff --check
```

Если working tree содержит чужие изменения, не перезаписывать их. Определить владельца и пересечение со своей задачей.

## 4. Release preparation

1. Проверить официальный URL, binary SHA, `--version`, `--help`.
2. Обновить wrapper constants и versions.
3. Создать deterministic mirror archive и parts.
4. Обновить tests, README, handoff и workflow.
5. Пройти полный local gate.
6. Просмотреть `git diff --stat`, затем полный diff текстовых файлов.
7. Сделать тематический commit без посторонних файлов.

## 5. Required local gate

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
./build.sh
sha256sum gigahash-*.tar.gz
tar -tzf gigahash-2.0.0.tar.gz
git diff --check
git status --short
```

Для текущей v2.0 ожидаемый package SHA-256:

```text
04f47d9b695cf3724e8d90faf9994d8f3c71252cdad834222cf383c7a5e2329c
```

## 6. Push

Перед push ещё раз показать пользователю:

- branch;
- commits to push;
- изменяемые release/workflow files;
- результаты gate.

После разрешения:

```bash
git push origin main
```

Force push не использовать для обычного обновления.

## 7. GitHub Actions

Workflow обязан:

- скачать официальный binary;
- проверить binary SHA и version;
- построить и проверить mirror archive parts;
- запустить все tests;
- собрать один стандартный package;
- проверить package SHA;
- опубликовать только standard package;
- не создавать split/PRL/SRB assets.

## 8. Release verification

После workflow проверить через GitHub UI/API:

- workflow conclusion `success`;
- tag указывает на ожидаемый commit;
- release содержит ровно ожидаемые assets;
- package SHA совпадает;
- jsDelivr installation URL возвращает архив;
- архив открывается и содержит ожидаемые wrapper files.

## 9. Удаление ошибочного asset

Удалять по точному asset ID/name, а не весь Release, если сам Release корректен. Сначала сохранить список:

```text
tag | release id | asset id | asset name | size
```

После удаления повторно получить Release и доказать, что исчез только целевой asset. Git-история и старые commits при этом сохраняются.

## 10. Следующая официальная версия

Не копировать старый workflow механически. Создать новый versioned workflow или аккуратно переименовать текущий, обновив:

- workflow title/path filter;
- official URL/SHA/version;
- mirror timestamp/SHA/part count;
- package name/SHA;
- commit message, tag, title и notes.

Старый Release не перезаписывать новой версией.
