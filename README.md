## WireGuard client for routers with Padavan based firmware

### EN

0. You will need a firmware with WireGuard support, like [padavan-ng from Alexey](https://gitlab.com/dm38/padavan-ng), on your router up and running
1. Clone this repo: `git clone https://github.com/shvchk/padavan-wireguard-client.git`
2. Edit `wireguard/conf.sh` to match your desired configuration
3. Upload `wireguard` directory to `/etc/storage` on your router: `scp -r wireguard admin@192.168.1.1:/etc/storage`
4. Test:
    - SSH into your router and start WireGuard client: `/etc/storage/wireguard/client.sh start`
    - Check if internet is working fine from your devices
    - In case of problems, stop WireGuard client on your router with `/etc/storage/wireguard/client.sh stop`
    - To debug, uncomment debug sections in `/etc/storage/wireguard/client.sh` and start client again.
    - If you connect to your provider via some tunnel, like L2TP, you will need additional traffic rules.
5. After you made sure everything is working fine, configure WireGuard to start automatically:
    - Add WireGuard starting script `/etc/storage/wireguard/client.sh start`:
      - either in your router UI to `Customization` → `Scripts` → `Run After Router Started`
      - or via SSH to `/etc/storage/started_script.sh`: `echo -e "\n/etc/storage/wireguard/client.sh start" >> /etc/storage/started_script.sh`
    - Add WireGuard traffic rules script `/etc/storage/wireguard/traffic_rules.sh enable`:
      - either in your router UI to `Customization` → `Scripts` → `Run After Firewall Rules Restarted`
      - or via SSH to `/etc/storage/post_iptables_script.sh`: `echo -e "\n/etc/storage/wireguard/traffic_rules.sh enable" >> /etc/storage/post_iptables_script.sh`
6. Save changes: `mtd_storage.sh save`
7. Restart router

### RU

0. Вам понадобится прошивка с поддержкой WireGuard, например [padavan-ng от Алексея](https://gitlab.com/dm38/padavan-ng), установленная и работающая на роутере
1. Клонируйте этот репозиторий: `git clone https://github.com/shvchk/padavan-wireguard-client.git`
2. Измените `wireguard/conf.sh` в соответствии с желаемой конфигурацией
3. Загрузите папку `wireguard` в `/etc/storage` на роутере: `scp -r wireguard admin@192.168.1.1:/etc/storage`
4. Тестирование:
    - Зайдите на роутер по SSH и запустите клиент WireGuard: `/etc/storage/wireguard/client.sh start`
    - Проверьте, работает ли интернет на ваших устройствах
    - В случае проблем, выключите клиент WireGuard на роутере: `/etc/storage/wireguard/client.sh stop`
    - Для отладки раскомментируйте отладочные секции в `/etc/storage/wireguard/client.sh` и запустите клиент снова
    - Если вы подключаетесь к провайдеру через туннель, например L2TP и т.п., вам понадобятся дополнительные правила маршрутизации
5. После того, как вы убедились, что всё хорошо работает, настройте автозапуск WireGuard:
    - Добавьте скрипт автозапуска WireGuard `/etc/storage/wireguard/client.sh start`:
      - либо в интерфейсе настройки роутера в `Персонализация` → `Скрипты` → `Выполнить после полного запуска маршрутизатора`
      - либо через SSH в `/etc/storage/started_script.sh`: `echo -e "\n/etc/storage/wireguard/client.sh start" >> /etc/storage/started_script.sh`
    - Добавьте скрипт настройки правил маршрутизации и файерволла `/etc/storage/wireguard/traffic_rules.sh enable`:
      - либо в интерфейсе настройки роутера в `Персонализация` → `Скрипты` → `Выполнить после перезапуска правил брандмауэра`
      - либо через SSH в `/etc/storage/post_iptables_script.sh`: `echo -e "\n/etc/storage/wireguard/traffic_rules.sh enable" >> /etc/storage/post_iptables_script.sh`
6. Сохраните изменения: `mtd_storage.sh save`
7. Перезагрузите роутер
