## Клиент WireGuardдля роутеров на прошивке Padavan

Один исполняемый файл, не требующий никакой настройки, только стандартный файл конфигурации WireGuard.

0. Вам понадобится прошивка с поддержкой WireGuard, например [padavan-ng от Алексея](https://gitlab.com/dm38/padavan-ng), установленная и работающая на роутере

0. Создайте папку `wireguard` в `/etc/storage` на роутере:
    ```sh
    mkdir /etc/storage/wireguard
    ```

0. Скопируйте в неё файл `client.sh`:
    ```sh
    wget https://github.com/shvchk/padavan-wireguard-client/raw/dev/client.sh -P /etc/storage/wireguard
    ```

0. Скопируйте в неё конфигурацию клиента WireGuard.

    Имя файла конфигурации будет использовано в качестве имени интерфейса.  
    Например, для конфигурационного файла `wg0.conf` будет создан интерфейс `wg0`.
    
    Имя должно содержать только латинские буквы, цифры и / или символы `_` `=` `+` `.` `-`, быть короче 16 символов и заканчиваться на `.conf`. В случае наличия нескольких файлов конфигурации, будет использован первый по алфавиту.

0. Запустите клиент WireGuard:
    ```sh
    /etc/storage/wireguard/client.sh start
    ```

0. Проверьте, работает ли интернет на ваших устройствах

0. В случае проблем, выключите клиент WireGuard на роутере:
    ```sh
    /etc/storage/wireguard/client.sh stop
    ```

0. После того, как вы убедились, что всё хорошо работает, настройте автозапуск:

    - Клиент Wireguard:
      ```sh
      echo -e "\n/etc/storage/wireguard/client.sh start" >> /etc/storage/started_script.sh
      ```

    - Правила маршрутизации и файерволла:
      ```sh
      echo -e "\n/etc/storage/wireguard/client.sh traffic-rules enable" >> /etc/storage/post_iptables_script.sh
      ```

0. Сохраните изменения:
    ```sh
    mtd_storage.sh save
    ```

0. Перезагрузите роутер
