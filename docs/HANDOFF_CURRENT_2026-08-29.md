# GigaHash HiveOS — archived handoff

> Этот срез сохранён как история. Текущий authoritative handoff:
> [`HANDOFF_CURRENT_2026-09-04_RU.md`](HANDOFF_CURRENT_2026-09-04_RU.md).

Дата среза: **2026-08-29 UTC**.

Этот файл — главный текущий handoff. История находится в `PROJECT_HISTORY_2026-08-29.md`; устройство проекта — в `HIVEOS_MINER_DEVELOPMENT.md`; GitHub-релизы — в `GITHUB_RELEASE_RUNBOOK.md`.

## 1. Текущее решение

Проект поддерживает только обычный GigaHash ZK Custom Miner для HiveOS.

| Поле | Текущее значение |
|---|---|
| Официальный miner | GigaHash ZK `v2.0` |
| CUDA build | `12.9` |
| HiveOS package | `gigahash-2.0.0.tar.gz` |
| Default pool | `ru1.gigahash.cloud:9100` |
| Wallet template | `%WAL%` |
| Default process model | один процесс GigaHash на весь риг |
| Default instances | `2` внутренних инстанции на GPU |
| Optional mode | `--low-cpu`, только по явному A/B-тесту |
| Repository | `amenhotep88/gigahash-hiveos` |

Split NOCK+PRL прекращён 2026-08-29. Его код, пакеты, SRBMiner vendor-файлы, тесты и release assets удалены из текущего состояния проекта. Git-история не переписывалась. Не восстанавливать split автоматически.

## 2. Граница разработки

Официальный `gigahash-zk-12.9` — закрытый бинарник. В этом репозитории разрабатываются:

- HiveOS manifest/config/run/stats scripts;
- безопасная доставка официального бинарника через jsDelivr mirror parts;
- SHA-256 проверка архива и бинарника;
- нормализация payout/worker шаблонов HiveOS;
- вывод нативной статистики в HiveOS;
- воспроизводимая сборка пакета;
- тесты и GitHub release workflow.

CUDA-алгоритм, proof pipeline, CPU↔GPU синхронизации и собственно хешрейт нельзя исправить в этой обёртке. Наблюдения по производительности передаются разработчику официального майнера.

## 3. Инварианты обычного пакета

1. Один Linux-процесс GigaHash обслуживает все видимые GPU.
2. `--instances 2` не означает два процесса на GPU.
3. По умолчанию бинарник использует все GPU; `--devices` передаётся только через Extra Config Arguments.
4. Worker name передаётся отдельно через `--worker-name`.
5. Payout address должен оставаться чистым адресом; matching `.worker-name` suffix удаляется защитно.
6. Стандартный пакет не включает `--low-cpu` принудительно.
7. Архив и бинарник проверяются по закреплённым SHA-256 до запуска.
8. Restricted HiveOS rigs загружают mirror parts из jsDelivr, а не официальный CDN напрямую.
9. Native JSON stats — основной источник; console parsing — fallback.
10. Локальный `Accepted` майнера не равен pool acceptance и не экспортируется как истинный счётчик пула.

## 4. Текущая конфигурация HiveOS

```text
Miner: Custom
Installation URL: https://cdn.jsdelivr.net/gh/amenhotep88/gigahash-hiveos@main/gigahash-2.0.0.tar.gz
Hash algorithm: blank / ----
Wallet and worker template: %WAL%
Pool URL: ru1.gigahash.cloud:9100
Pass: blank
Extra Config Arguments: blank by default
```

При необходимости `--instances 2` задаётся нативному майнеру, но текущая обёртка и наблюдаемый JSON показывают две внутренние инстанции на GPU. Не добавлять `--low-cpu` без отдельного сравнительного теста.

## 5. Рабочие риги и последний стабильный срез

Срез API пула 2026-08-29 около 09:00 UTC:

| Worker | GPU | Версия | Ориентир хешрейта |
|---|---:|---|---:|
| `2x3070` | 1 | v1.9 | `~4.7 kp/s` |
| `3070ti` | 7 | v1.9 | `~36 kp/s` |
| `Laptop` | 6 | v1.9 | `~25.8 kp/s` |
| `Peladn` | 8 | v1.9 | `~38.8–39.1 kp/s` |
| `redrig` | 8 | v1.9 | `~33 kp/s` |
| **Итого** | **30** | | **~138–140 kp/s** |

Share quality в последнем 24-часовом срезе была около `99.3%`, без invalid shares в свежем окне.

## 6. Пул и доходность

- Payout address: `W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN`
- `1 NOCK = 65,536 nicks`; никогда не делить API nicks на `100,000`.
- Pool fee: `9%`.
- Minimum payout: `2,000 NOCK`.
- Payout interval setting: `21,600 s` (`6 h`), но реальный payout зависит от достижения порога и появления batch.
- Выплата 2026-08-28: `2549.3939 NOCK`, payout transaction cost `6.5784 NOCK`.
- После выплаты фактический темп по начисленному балансу был около `2360 NOCK/day`; мгновенный сетевой калькулятор около `2050 NOCK/day`. Для прогноза использовать полное 24-часовое окно, а не короткую удачу пула.

Правильная формула через payout/reset:

```text
actual NOCK/day = current_pending_NOCK * 24 / hours_since_batch_created
```

Если окно пересекает payout:

```text
earned = Δpending + Δreserved + Δpaid + Δpayout_costs
```

Проверять семантику полей API перед долгосрочным учётом.

## 7. Известные технические наблюдения

- v1.9 без `--low-cpu` на Peladn дала около `39.06 kp/s` против `36.49 kp/s` на v1.8 и снизила Load Average примерно с `4.26` до `0.68` в наблюдавшихся срезах.
- `--low-cpu` в v1.9 является отдельным дополнительным режимом. В тестах несколько ригов завершались с единственной строкой `E`; без флага Peladn продолжил работать. Поэтому флаг не включён по умолчанию.
- PCIe Gen1 x1 показал импульсный RX примерно `20–171 MB/s`, TX `3–37 MB/s`. Это не доказывает свободный линейный резерв: ограничением могут быть latency, маленькие транзакции и синхронизации.
- На v1.8 одна RTX 3070: Gen3 x16 около `4.71 kp/s`; Gen1 x1 при 4 GPU около `4.68 kp/s/GPU`; Gen1 x1 при 8 GPU около `4.56 kp/s/GPU`.
- Закрытый бинарник не позволяет реализовать batching/pinned memory/async CUDA в wrapper. Эти данные предназначены для разработчика GigaHash.

## 8. Git-состояние после переноса

Удаление split и документация переноса публикуются обычным коммитом поверх `main`.
История старых split-коммитов сохраняется и не переписывается. Точный актуальный SHA
следует получать командами `git status`, `git log` и `git rev-parse origin/main`, а не
хранить как постоянное значение в документации.

## 9. Следующие задачи

После выпуска официального v2.0:

1. Не менять runtime-код без конкретной неисправности.
2. Сначала развернуть v2.0 на одном контрольном риге и наблюдать стабильность и полное 24-часовое окно выплат.
3. При выходе новой версии: сохранить старые контрольные данные, проверить binary/version/help/SHA, обновить mirror parts и wrapper constants, пройти release runbook.
4. После каждого материального изменения обновлять этот handoff и дату среза.
