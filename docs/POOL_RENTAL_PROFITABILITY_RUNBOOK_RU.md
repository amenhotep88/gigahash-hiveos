# Пул, доходность и аренда Clore — operational runbook

Дата актуализации: **2026-09-04 UTC**.

## 1. Источники факта

Приоритет данных:

1. Pool account по payout `W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN`: credited workers, balance, payouts.
2. Лог майнера: startup, endpoint, hashrate, Accepted/Stale/Errors.
3. `nvidia-smi`: фактические GPU, PL, draw, clocks, utilization, VRAM и температура.
4. Clore order: цена, оставшийся срок, ID и активность.
5. Clore listing: только предварительная оценка; advertised PL не является подтверждённым current PL.

## 2. Таблица анализа пула

Каждый анализ должен возвращать одну сводную таблицу:

| Worker | Тип | GPU | kp/s | Accepted/Stale/Errors | Статус/свежесть | Аренда $/day | Gross | Net | Margin | Решение |
|---|---|---|---:|---|---|---:|---:|---:|---:|---|

Правила:

- `clore-*` считать арендным, остальные — собственными, если факты не говорят обратное;
- число активных Clore orders сравнить с числом живых `clore-*` workers;
- не считать pending worker доходным до первой credited share;
- один локальный `Accepted` подтверждает связь, но pool dashboard/API остаётся источником начисления;
- stale/invalid оценивать долей за стабильное окно, а не одной случайной шарой;
- одинаковые или старые worker names проверять на дубли и переиспользованные контейнеры.

## 3. Баланс и выплата

- `1 NOCK = 65,536 nicks`.
- Minimum payout: 2,000 NOCK.
- Pool fee: 9%.
- Интервал настройки payout: 21,600 секунд (6 часов), но фактическая выплата зависит от достижения порога и формирования batch.

Темп в окне без выплаты:

```text
actual NOCK/day = (pending_now − pending_start) × 24 / elapsed_hours
```

Если окно пересекло payout:

```text
earned_NOCK = Δpending + Δreserved + Δpaid + Δpayout_costs
actual_NOCK/day = earned_NOCK × 24 / elapsed_hours
```

Прогноз времени до порога:

```text
remaining_NOCK = max(0, 2000 − pending − eligible_reserved)
hours_to_threshold = remaining_NOCK / actual_NOCK_per_day × 24
```

Прогноз «успеем ли к времени X» должен учитывать: текущее UTC/local time, время следующего batch, текущий баланс, фактический темп за достаточное окно и запас на luck/variance. Не обещать выплату только по мгновенному калькулятору.

## 4. Доходность аренды

Перед каждым поиском обновить:

- исполнимую цену NOCK/USDT, а не последний старый скрин;
- фактический pool yield в NOCK на kp/s/day;
- комиссию/ликвидность продажи;
- текущую цену аренды всего выбранного рига.

```text
NOCK/day = expected_kp/s × current_pool_NOCK_per_kp/s/day
Gross_USD/day = NOCK/day × executable_NOCK_USD
Net_USD/day = Gross_USD/day − rent_USD/day
Margin_% = Net_USD/day / rent_USD/day × 100
Break_even_NOCK_USD = rent_USD/day / NOCK/day
```

Показывать base и stress scenario. Для нового конкретного server ID использовать консервативный hashrate и явный риск-дисконт. После запуска полностью заменить прогноз фактом.

## 5. Поиск Clore

1. Получить весь живой рынок, а не только первый экран.
2. Удалить US и stop-list до ранжирования.
3. Проверить, цена указана за GPU или за риг.
4. Для каждой GPU записать model, VRAM, advertised PL, lock/offset и PCIe.
5. Проверить CPU/AVX2, RAM, диск, сеть, country, reliability, rating count и max rental.
6. Посчитать conservative gross/net/margin.
7. Выдать только лучшие доступные ID. Отменённые и stop-list не показывать.
8. Пользователь арендует сам; после SSH немедленно проверить реальный `nvidia-smi` до установки майнера.

Порог сохранения аренды вычислять из фактического hashrate:

```text
required_kp/s = rent_USD/day × (1 + target_margin) / current_USD_per_kp/s/day
```

## 6. Stop-list и известные ошибки

Не показывать в новых результатах: `102592`, `113763`, `78799`, `90887`, `113052`, `114382`, `78139`, `114377`, `106744`, `107945`, `77956`, `105060`.

Ключевые уроки:

- `114377` (RTX 4090, PL450) дал только ~10.1 kp/s: модельная таблица не гарантирует факт конкретного хоста.
- `106744` рекламировал 2×5060 Ti 180 W, фактически было 180+150 W; изменение PL запрещено.
- `107945` рекламировал 2×4070 около 200 W, фактически обе были 130 W; изменение PL запрещено.
- `77956`, 2×3080 Ti PL300, дал ~18.8 kp/s total; не переносить аномальные 15 kp/s одной 3080 Ti с mixed rig на все карты.
- `105060` был активен в Clore, но worker не поднялся на пуле; отменён.
- предупреждение SSH `REMOTE HOST IDENTIFICATION HAS CHANGED` на переиспользованном Clore host: сначала сверить endpoint/order, затем удалить только точную запись `ssh-keygen -R "[host]:port"`.

## 7. Запуск на Clore

Использовать Supervisor, один процесс майнера на контейнер. Worker: `clore-SERVER_ID`. После прогрева проверить:

```bash
supervisorctl status gigahash
nvidia-smi --query-gpu=index,name,pstate,clocks.gr,power.draw,power.limit,utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader
tail -n 40 /root/gigahash/gigahash-supervisor.log | grep -E 'connected|Total|Accepted|Stale|Errors'
```

Если hashrate аномален, сначала проверить реальный PL/clocks, число процессов и instances. Не менять несколько параметров одновременно. Быстро отменённый сервер добавить в stop-list.
