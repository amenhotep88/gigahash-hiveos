# Разработка GigaHash HiveOS wrapper

## 1. Назначение

Репозиторий адаптирует официальный закрытый GigaHash ZK miner для HiveOS. Это wrapper-проект, не fork CUDA miner.

## 2. Карта файлов

| Файл | Ответственность |
|---|---|
| `h-manifest.conf` | имя, версия, пути HiveOS |
| `h-config.sh` | преобразование Flight Sheet в `gigahash.conf` |
| `h-common.sh` | общие функции и нормализация значений |
| `h-run.sh` | проверенная загрузка binary mirror, аргументы и запуск |
| `h-stats.sh` | JSON/console stats → HiveOS JSON |
| `build.sh` | воспроизводимый `gigahash-X.Y.Z.tar.gz` |
| `tests/test_release_2_0.sh` | release invariants текущей версии |
| `vendor/gigahash-zk-2.0.tar.gz.part-*` | jsDelivr mirror parts официального binary archive |
| `.github/workflows/publish-v2.0.yml` | проверка, сборка и GitHub Release |

Отдельный AMD/ROCm пакет:

| Файл | Ответственность |
|---|---|
| `h-manifest-amd.conf` | имя `gigahash-amd`, версия и отдельные HiveOS paths |
| `h-config-amd.sh` | AMD Flight Sheet → config |
| `h-run-amd.sh` | проверка `/dev/kfd`, сборка ROCm mirror, SHA и запуск |
| `h-stats-amd.sh` | AMD native JSON/console stats → HiveOS JSON |
| `build-amd.sh` | воспроизводимый `gigahash-amd-2.2.0.tar.gz` |
| `tests/test_release_2_2_amd.sh` | AMD release invariants |
| `.github/workflows/publish-v2.2-amd.yml` | ROCm binary verification, mirror parts, package и release |

NVIDIA и AMD — два отдельных Custom Miner packages. Общим остаётся только `h-common.sh`; нельзя подменять AMD scripts NVIDIA-версиями или наоборот.

В проекте нет split, PRL или SRBMiner.

## 3. Runtime data flow

```text
HiveOS Flight Sheet
  -> h-config.sh
  -> gigahash.conf: GH_SERVER, GH_PAYOUT, GH_WORKER, GH_EXTRA
  -> h-run.sh
  -> reconstruct mirror archive
  -> verify archive SHA-256
  -> extract and verify binary SHA-256
  -> one gigahash-zk process for all selected GPUs
  -> native JSON stats
  -> h-stats.sh
  -> HiveOS dashboard
```

## 4. Обязательные свойства новой версии

При обновлении официального binary должны одновременно измениться:

- URL и official version;
- official binary SHA-256;
- deterministic mirror archive SHA-256;
- число mirror parts и `GH_PART_LAST`;
- package version в `h-manifest.conf` и `build.sh`;
- stats version;
- release test expectations;
- README и handoff;
- workflow name, URLs, hashes, tag и notes.

Нельзя менять только архив и оставлять старые constants.

## 5. Безопасное получение official binary

1. Скачать только по официальному GigaHash release URL.
2. Зафиксировать URL, размер и SHA-256.
3. Выполнить `--version` и сохранить точный вывод.
4. Прочитать `--help`; новые flags считать опциональными, пока A/B не доказал пользу и стабильность.
5. Не доверять бинарнику, полученному из случайного mirror или пользовательского архива.

## 6. Mirror archive

Причина mirror parts: некоторые HiveOS rigs не могут скачать официальный CDN или GitHub release assets, но читают jsDelivr raw files.

Архив создаётся воспроизводимо:

```bash
tar --sort=name --owner=0 --group=0 --numeric-owner \
  --mtime='UTC YYYY-MM-DD HH:MM:SS' \
  -C "$stage" -czf /tmp/gigahash-zk-X.Y.tar.gz gigahash-zk
```

Далее он режется на части безопасного для jsDelivr размера. `h-run.sh` собирает части строго по порядку, проверяет archive SHA, извлекает binary и проверяет binary SHA.

## 7. Аргументы запуска

Обязательные аргументы формируются wrapper:

- `--server "$GH_SERVER"`
- `--payout-address "$GH_PAYOUT"`
- `--worker-name "$GH_WORKER"`

Extra args добавляются после безопасного разбора `GH_EXTRA`. Не встраивать экспериментальные flags как default. В частности, `--low-cpu` остаётся ручным параметром.

## 8. Статистика

Приоритет:

1. native JSON stats;
2. console-table fallback;
3. корректный `null`/пустой результат вместо выдуманной статистики.

HiveOS использует generic hash units: `1 proof/s` отображается как `1 H/s`. Поэтому `39 kp/s` показывается как `39 kH/s`, хотя смысл — proofs per second.

Не считать локальный `Accepted` абсолютной истиной. Pool API — authoritative для credited shares, balance и payout.

## 9. Тесты перед релизом

Минимальный локальный gate:

```bash
for test_file in tests/*.sh; do bash "$test_file"; done
./build.sh
sha256sum gigahash-2.0.0.tar.gz
tar -tzf gigahash-2.0.0.tar.gz
```

Для AMD дополнительно:

```bash
bash tests/test_release_2_2_amd.sh
./build-amd.sh
sha256sum gigahash-amd-2.2.0.tar.gz
tar -tzf gigahash-amd-2.2.0.tar.gz
```

Ожидаемый AMD package SHA-256 для `2.2.0-amd2`:
`d18b421071fb2df6abdaa9fcf0eab5da24b04aa1015d21443c497cbaf66ed1db`.

Дополнительно проверить:

- `bash -n` для всех shell scripts;
- отсутствие split/PRL/SRB references в текущем дереве;
- package содержит только пять wrapper files;
- checksum совпадает с документированным;
- `git diff --check` не находит whitespace errors.

## 10. Rollout новой версии

1. Релиз и установка только на один контрольный риг.
2. Проверить startup, pool connection, JSON stats, accepted pool shares, VRAM, CPU, hashrate и Xid/OOM.
3. Сравнить с замороженным предыдущим baseline минимум 10–15 минут; для доходности — 24 часа.
4. Затем развернуть на остальных ригах по одному.
5. При общем одновременном падении искать shared cause: binary flag, pool/server, wrapper download или release asset.

## 11. Диагностика на риге

Пользователю выдавать одну команду за шаг. Начальный read-only срез:

```bash
hostname; date -u; pgrep -af '[g]igahash-zk'; nvidia-smi; \
tail -n 100 /var/log/miner/gigahash/gigahash.log
```

Далее менять одну переменную за тест. Не смешивать binary version, OC, server и Extra Config Arguments в одном сравнении.
