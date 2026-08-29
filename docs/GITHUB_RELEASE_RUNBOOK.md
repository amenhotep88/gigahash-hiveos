# GitHub и выпуск GigaHash HiveOS package

## 1. Репозиторий и модель релиза

- Repository: `https://github.com/amenhotep88/gigahash-hiveos`
- Active branch: `main`
- Active product: один обычный GigaHash ZK HiveOS package
- Current tag scheme: official-wrapper package version, например `v1.9.0`
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
tar -tzf gigahash-1.9.0.tar.gz
git diff --check
git status --short
```

Для текущей v1.9 ожидаемый package SHA-256:

```text
c1c3376117cf9827de6153d5e67f1a05b5b89dfc21fe64394294599eb484a67f
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
