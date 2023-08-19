<p align="right"><a href="README.md">English</a> | Русский</p>

## Клиент WireGuard для роутеров на прошивке Padavan

0. Вам понадобится прошивка с поддержкой WireGuard, например [padavan-ng от Алексея](https://gitlab.com/dm38/padavan-ng), установленная и работающая на роутере
1. Клонируйте этот репозиторий: `git clone -b legacy https://github.com/shvchk/padavan-wireguard-client.git`
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
