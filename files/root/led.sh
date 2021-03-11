#!/bin/sh

eval hash_LED_signal1=none
eval hash_LED_signal2=none
eval hash_LED_signal3=none
eval hash_LED_signal4=none
eval hash_LED_4g=none

change_led() {

#    echo debug: change_led "$1" "$2"

    echo "$2" > /sys/class/leds/mr200\:white\:$1/trigger
}

led_on() {

  export key=LED_$1

  if [ $(eval "echo \$hash_$key") != "default-on" ]; then

    change_led $1 "default-on"
    eval hash_$key="default-on"

  fi
}

led_off() {

  export key=LED_$1                                     

  if [ $(eval "echo \$hash_$key") != "none" ]; then

    change_led $1 "none"
    eval hash_$key="none"

  fi                                                     

}

update_led_status() {
    $(curl -s -d '{"module":"status", "action":"0"}' -H "Content-Type: application/json" -X POST http://192.168.225.1/cgi-bin/qcmap_web_cgi \
| jsonfilter -e 'SIGNALSTRENGTH=@.wan.signalStrength' -e 'NETWORKTYPE=@.wan.networkType')

    case $SIGNALSTRENGTH in
        "0;")
            led_off signal1
            led_off signal2
            led_off signal3
            led_off signal4
            ;;
        "1;")
            led_on signal1
            led_off signal2
            led_off signal3
            led_off signal4
            ;;
        "2;")
            led_on signal1
            led_on signal2
            led_off signal3
            led_off signal4
            ;;
        "3;")
            led_on signal1
            led_on signal2
            led_on signal3
            led_off signal4
            ;;
        "4;")
            led_on signal1
            led_on signal2
            led_on signal3
            led_on signal4
            ;;
    esac

    case $NETWORKTYPE in
        "3;")
            led_on 4g
            ;;
        *)
            led_off 4g
            ;;
    esac
}

led_status_loop() {
    while sleep 10; do
        update_led_status
    done
}

led_status_loop &
