# GigaHash / NOCK ZK — authoritative handoff

Дата среза: **2026-09-04 UTC**.

Этот файл — главная точка продолжения проекта. Не начинать исследование заново. Подробные процедуры:

- [`HIVEOS_MINER_DEVELOPMENT.md`](HIVEOS_MINER_DEVELOPMENT.md) — сборка HiveOS wrapper;
- [`GITHUB_RELEASE_RUNBOOK.md`](GITHUB_RELEASE_RUNBOOK.md) — публикация релизов;
- [`POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md`](POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md) — пул, экономика и Clore;
- [`NOSSD_TO_GIGAHASH_2026-09-04_RU.md`](NOSSD_TO_GIGAHASH_2026-09-04_RU.md) — локальные серверы и точный rollback.

## 1. Граница проекта

Репозиторий `amenhotep88/gigahash-hiveos` содержит обвязки официальных закрытых GigaHash ZK binaries, а не исходники CUDA/ROCm proof-generator. Поддерживаются упаковка для HiveOS, конфиг, запуск, статистика, проверка SHA-256, CDN mirror parts, тесты и GitHub Release.

Текущий NVIDIA-пакет: **GigaHash ZK v2.2 / CUDA 12.9 / `gigahash-2.2.0.tar.gz`**.

Текущий AMD-пакет: **GigaHash ZK v2.2 / ROCm 10.0 / `gigahash-amd-2.2.0.tar.gz` / package version `2.2.0-amd2`**. Он использует отдельные `h-*-amd` scripts, HiveOS directory `/hive/miners/custom/gigahash-amd`, binary `gigahash-zk-rocm10.0`, test `tests/test_release_2_2_amd.sh` и workflow `.github/workflows/publish-v2.2-amd.yml`.

Split NOCK+PRL прекращён и не должен восстанавливаться автоматически.

## 2. Постоянные параметры

| Поле | Значение |
|---|---|
| Payout address | `W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN` |
| Основной operational endpoint | `backup.gigahash.cloud:9100` |
| Резервный/исторический endpoint | `ru1.gigahash.cloud:9100` |
| Pool fee | 9% |
| Minimum payout | 2,000 NOCK |
| API conversion | `1 NOCK = 65,536 nicks`, не 100,000 |
| Clore runtime | Supervisor |
| Обычный Ubuntu runtime | systemd |
| AMD binary SHA-256 | `a9bcf774b394956ef2eb0af15d9886e976abd5ab04c27d0eb5b990e9b7427019` |
| AMD package SHA-256 | `d18b421071fb2df6abdaa9fcf0eab5da24b04aa1015d21443c497cbaf66ed1db` |

Никогда не смешивать payout и worker suffix. Адрес передаётся чистым через `--payout-address`, имя — отдельно через `--worker-name`.

## 3. Фактические ориентиры производительности

Факт конкретного рига важнее модельной таблицы продавца.

| GPU / конфигурация | Фактический результат | Статус |
|---|---:|---|
| RTX 5090, PL600, instances4 | 31.6–33.0 kp/s | рабочий эталон |
| RTX 5090, PL450 | ~11.2 kp/s | недостаточный PL, исключать |
| RTX 5070 Ti, PL300, instances2 | 15.05–15.16 kp/s | повторно подтверждено |
| RTX 5060 Ti, PL180, instances2 | 7.57–7.69 kp/s | подтверждено |
| 2×RTX 5070, PL250 на карту | ~21.3 kp/s суммарно | подтверждено |
| RTX 4090, PL450, server 114377 | ~10.1 kp/s | конкретный провальный риг |
| 2×RTX 3080 Ti, PL300 на карту | 18.72–18.81 kp/s суммарно | надёжный baseline для пары |
| Mixed 5070 Ti + 3080 Ti, server 77653 | 7.13 + 15.02 = 22.15 kp/s | аномальный, но подтверждённый факт |
| Локальная RTX 3080 `rz2`, PL210, lock1500 | 7.20–7.24 kp/s, ~190–193 W | systemd |
| Локальная RTX 3080 `rzserv`, PL260, lock1500 | 7.37–7.47 kp/s, ~223–227 W | systemd |
| Локальная RTX 3070 `x99`, PL170, lock1400 | 4.58–4.65 kp/s, ~113–122 W | instances1, 8 GB |

RTX 3070 8 GB использует один instance (~4.1 GB VRAM). Два instance требуют примерно 8.2 GB и не должны назначаться без отдельного успешного теста.

## 4. Правила аренды

- География: US исключать.
- Минимальный срок: 24 часа; предпочтительнее несколько дней.
- Цель: максимальная реальная маржа и надёжность; требование пользователя — обычно не менее 40% маржи, желательно 60%+, без обязательного порога `$4/day`, если пользователь явно его снял.
- Не предлагать риги из stop-list и отменённые ID в кандидатах.
- Проверять цену всего рига против режима `per GPU`, PL каждой карты, фактический current PL после аренды, core lock, PCIe, CPU/RAM, сеть, reliability/rating, срок и SSH.
- На Clore права на `nvidia-smi -pl` часто отсутствуют. Рекламный PL не считать фактом до проверки `nvidia-smi` внутри контейнера.
- Новый неизвестный GPU/сервер оценивать со скидкой за риск. Не переносить табличный хешрейт на конкретный ID как обещанный результат.
- После запуска решение принимается по факту: прогрев, `Accepted`, `Stale`, `Errors`, хешрейт, power, clocks и стабильность.

Известный stop-list на 2026-09-04: `102592`, `113763`, `78799`, `90887`, `113052`, `114382`, `78139`, `114377`, `106744`, `107945`, `77956`, `105060`. Не показывать эти ID в новых подборках, если пользователь отдельно не просит аудит истории.

## 5. Анализ пула и доходности

Пул анализируется по разрешённому пользователем payout-адресу выше. Обязательный срез:

1. Все workers: имя, версия, GPU online/total, current hashrate, uptime/status и свежесть данных.
2. Разделение `clore-*` (аренда) и собственных workers.
3. Сверка каждого `clore-<ID>` с активными заказами Clore: активная аренда без worker — инцидент; worker без активной аренды — проверить stale dashboard/имя.
4. Pool-side shares/balance/payouts считаются authoritative; локальный `Accepted` подтверждает жизнеспособность, но не заменяет pool accounting.
5. Для доходности брать свежие NOCK/day или фактическое изменение баланса за достаточно длинное окно и свежую исполнимую цену NOCK/USDT.

Формулы и процедура прогноза выплаты находятся в `POOL_RENTAL_PROFITABILITY_RUNBOOK_RU.md`.

## 6. Локальная миграция NoSSD → GigaHash 2026-09-04

Переведены три сервера:

| Host | GPU | Worker | Core lock | PL | Instances | Ожидаемый факт |
|---|---|---|---:|---:|---:|---:|
| `rz2` | RTX 3080 10 GB | `rz2-3080` | 1500 MHz | 210 W | 2 | ~7.2 kp/s |
| `rzserv` | RTX 3080 10 GB | `rzserv-3080` | 1500 MHz | 260 W | 2 | ~7.4 kp/s |
| `x99` | RTX 3070 8 GB | `x99-3070` | 1400 MHz | 170 W | 1 | ~4.6 kp/s |

Суммарный ориентир локальных серверов: **~19.2 kp/s**.

NoSSD имел три независимых механизма:

- `miner.service`;
- root cron `*/5 * * * * /usr/local/bin/monitor.sh`, где monitor запускает `miner.service`;
- `nossd-disks.timer` → `nossd-disks.service` → `/usr/local/sbin/nossd-disk-manager.sh`, который может запускать/перезапускать `miner.service`.

Отключение только `miner.service` недостаточно. На `rz2` watchdog запустил NoSSD, а `Conflicts=miner.service` штатно остановил GigaHash. После расследования root cron закомментирован, `nossd-disks.timer` отключён, исходный cron сохранён в `/root/root.crontab.before-gigahash`. `nossd-vpn-subscription-update.timer` намеренно оставлен включённым: GPU-майнер он не запускает.

На `x99` драйвер обновлён с 535.309.01 (CUDA 12.2) до 580.173.02 (CUDA 13.0). Причина первого конфликта APT — NVIDIA 535 packages были `apt-mark hold`; сняты hold только с NVIDIA packages, kernel meta packages оставлены held. CUDA Toolkit не устанавливался и для packaged GigaHash binary не требуется.

Полная процедура остановки, проверки и безопасного rollback находится в отдельном runbook. Ничего из NoSSD не удалено.

## 7. Следующее продолжение

1. Проверить pool-side статус и `Accepted` всех трёх локальных workers.
2. При анализе аккаунта строить одну таблицу собственных и арендных workers и явно отмечать расхождения с Clore orders.
3. При следующем поиске обновить live Clore market, pool yield и NOCK price; исключить stop-list до ранжирования.
4. При возврате к NoSSD использовать только документированный rollback, сначала остановив GigaHash.
5. NVIDIA и AMD выпускать отдельными пакетами и workflow; перед публикацией выполнять оба release test, но не смешивать их runtime-файлы.
