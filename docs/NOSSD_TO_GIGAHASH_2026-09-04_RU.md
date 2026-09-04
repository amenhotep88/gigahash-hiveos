# Локальные серверы: NoSSD → GigaHash и обратный возврат

Дата выполнения: **2026-09-04 UTC**.

## 1. Что было обнаружено

NoSSD запускается не одним механизмом:

| Механизм | Назначение / риск |
|---|---|
| `/etc/systemd/system/miner.service` | основной NoSSD miner |
| root cron `*/5 * * * * /usr/local/bin/monitor.sh` | запускает `miner.service`, если тот не active |
| `nossd-disks.timer` | раз в минуту вызывает `nossd-disks.service` |
| `/usr/local/sbin/nossd-disk-manager.sh` | при изменении дисков останавливает и затем запускает/restart `miner.service` |
| `nossd-vpn-subscription-update.timer` | обновление VPN; GPU miner не запускает, оставлен enabled |

Простого `systemctl disable --now miner.service` недостаточно. На `rz2` в 17:44:46 запустился `nossd-disks.service`, в 17:45:02 был запущен `miner.service`, а из-за `Conflicts=miner.service` systemd отправил GigaHash `SIGTERM`. Это была автоматизация NoSSD, не падение GigaHash и не ручная остановка пользователя.

## 2. Сохранённое состояние NoSSD

- Unit file не удалялся: `/etc/systemd/system/miner.service`.
- Исходный root crontab сохранён: `/root/root.crontab.before-gigahash`.
- Строка monitor заменена на:

```text
# disabled-for-gigahash: */5 * * * * /usr/local/bin/monitor.sh
```

- `miner.service`: disabled/inactive.
- `nossd-disks.timer`: disabled/inactive.
- `nossd-vpn-subscription-update.timer`: enabled/active.

## 3. Безопасное переключение на GigaHash

Перед первым изменением сохранить cron, не перезаписывая имеющуюся резервную копию:

```bash
if ! sudo test -f /root/root.crontab.before-gigahash; then
  sudo crontab -l | sudo tee /root/root.crontab.before-gigahash >/dev/null
fi

sudo crontab -l | \
sed '\|^[^#].*/usr/local/bin/monitor.sh|s|^|# disabled-for-gigahash: |' | \
sudo crontab -

sudo systemctl disable --now miner.service
sudo systemctl disable --now nossd-disks.timer
sudo systemctl stop nossd-disks.service 2>/dev/null || true
sudo systemctl reset-failed miner.service 2>/dev/null || true
```

Проверить до запуска GigaHash:

```bash
systemctl is-active miner.service
systemctl is-enabled miner.service
systemctl is-enabled nossd-disks.timer
sudo crontab -l | grep monitor.sh
nvidia-smi --query-compute-apps=pid,process_name,used_gpu_memory --format=csv,noheader
```

## 4. Systemd unit GigaHash

Паттерн unit:

```ini
[Unit]
Description=GigaHash NOCK ZK Miner
After=network-online.target
Wants=network-online.target
Conflicts=miner.service

[Service]
Type=simple
WorkingDirectory=/home/USER/gigahash
ExecStartPre=/usr/bin/nvidia-smi -i 0 -lgc CORE,CORE
ExecStart=/home/USER/gigahash/gigahash-zk-12.9 --server backup.gigahash.cloud:9100 --payout-address W1ijDJZsLuKiLpKWzr5LYeVMnJKF8Khx9stXEBoXQfxwjEotbxppbN --worker-name WORKER --instances N
ExecStopPost=-/usr/bin/nvidia-smi -i 0 -rgc
Restart=always
RestartSec=10
TimeoutStopSec=30
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
```

Значения 2026-09-04:

| Host/User | Worker | Core | PL (не менять) | N |
|---|---|---:|---:|---:|
| `rz2` / `rz2` | `rz2-3080` | 1500 | 210 | 2 |
| `rzserv` / `rz` | `rzserv-3080` | 1500 | 260 | 2 |
| `x99` / `x99` | `x99-3070` | 1400 | 170 | 1 |

`nvidia-smi` может показывать ближайший фактический clock bin (например 1410 при lock1400) или более низкую effective clock под нагрузкой. Решение принимать по стабильному hashrate/power/errors, не по одному clock sample.

## 5. Проверка после запуска и после reboot

```bash
systemctl is-enabled gigahash.service
systemctl is-active gigahash.service
systemctl is-active miner.service
systemctl is-enabled nossd-disks.timer
sudo crontab -l | grep monitor.sh
nvidia-smi --query-gpu=clocks.current.graphics,power.draw,power.limit,utilization.gpu,temperature.gpu,memory.used,memory.total --format=csv,noheader
journalctl -u gigahash.service --since '5 minutes ago' --no-pager | grep -E 'starting|connected|Total|Accepted|Stale|Errors' | tail -n 20
```

Нельзя считать миграцию устойчивой, пока не проверены все три блокиратора NoSSD и pool-side worker.

## 6. Полный rollback GigaHash → NoSSD

Выполнять на одном сервере за раз:

```bash
# 1. Остановить GigaHash; ExecStopPost снимет core lock
sudo systemctl disable --now gigahash.service
sudo nvidia-smi -i 0 -rgc

# 2. Восстановить исходный root cron
sudo test -f /root/root.crontab.before-gigahash
sudo crontab /root/root.crontab.before-gigahash

# 3. Вернуть disk watchdog и основной miner
sudo systemctl daemon-reload
sudo systemctl enable --now nossd-disks.timer
sudo systemctl enable --now miner.service

# VPN timer не изменялся
systemctl is-enabled nossd-vpn-subscription-update.timer
systemctl is-active nossd-vpn-subscription-update.timer
```

После возврата:

```bash
systemctl is-active miner.service
systemctl is-enabled miner.service
systemctl is-enabled nossd-disks.timer
sudo crontab -l | grep monitor.sh
nvidia-smi
journalctl -u miner.service -n 30 --no-pager
```

Ожидается active/enabled, незакомментированная строка monitor, активный NoSSD GPU process и исходные каталоги дисков. Если `miner.service` падает, не включать GigaHash параллельно: сначала читать полный NoSSD log и проверять mount/directory arguments.

## 7. Драйвер RTX 3070 x99

Исходно: driver 535.309.01, CUDA 12.2. GigaHash binary CUDA 12.9 потребовал обновления. APT не мог заменить ветку, потому что все NVIDIA 535 packages были held.

Были сняты hold только с пакетов `nvidia-*`, `libnvidia-*`, `xserver-xorg-video-nvidia-*`; holds `linux-generic`, `linux-headers-generic`, `linux-image-generic` сохранены. Установлен `nvidia-driver-580`; после reboot факт: driver 580.173.02, CUDA 13.0. Полный CUDA Toolkit (`nvcc`, `libcudart` packages) не устанавливался.
