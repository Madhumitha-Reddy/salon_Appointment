#! /bin/bash

set -euo pipefail

PSQL=(psql --username=freecodecamp --dbname=salon --no-psqlrc --tuples-only --no-align --quiet --set=ON_ERROR_STOP=1)

print_services() {
  "${PSQL[@]}" -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id;"
}

print_services
printf '\nWhat would you like today?\n'
read SERVICE_ID_SELECTED

while true; do
  if [[ ! "$SERVICE_ID_SELECTED" =~ ^[0-9]+$ ]]; then
    SERVICE_NAME=
  else
    SERVICE_NAME=$(printf '%s\n' "SELECT name FROM services WHERE service_id = :'service_id';" |
      "${PSQL[@]}" -v service_id="$SERVICE_ID_SELECTED")
    SERVICE_NAME=${SERVICE_NAME//$'\n'/}
  fi

  if [[ -n "$SERVICE_NAME" ]]; then
    break
  fi

  printf '\nI could not find that service. What would you like today?\n'
  print_services
  read SERVICE_ID_SELECTED
done

printf "\nWhat's your phone number?\n"
read CUSTOMER_PHONE

CUSTOMER_ID=$(printf '%s\n' "SELECT customer_id FROM customers WHERE phone = :'customer_phone';" |
  "${PSQL[@]}" -v customer_phone="$CUSTOMER_PHONE")
CUSTOMER_ID=${CUSTOMER_ID//$'\n'/}

if [[ -z "$CUSTOMER_ID" ]]; then
  printf "\nI don't have a record for that phone number, what's your name?\n"
  read CUSTOMER_NAME
  CUSTOMER_ID=$(printf '%s\n' \
    "INSERT INTO customers (phone, name) VALUES (:'customer_phone', :'customer_name') RETURNING customer_id;" |
    "${PSQL[@]}" -v customer_phone="$CUSTOMER_PHONE" -v customer_name="$CUSTOMER_NAME")
  CUSTOMER_ID=${CUSTOMER_ID//$'\n'/}
else
  CUSTOMER_NAME=$(printf '%s\n' "SELECT name FROM customers WHERE customer_id = :'customer_id';" |
    "${PSQL[@]}" -v customer_id="$CUSTOMER_ID")
  CUSTOMER_NAME=${CUSTOMER_NAME//$'\n'/}
fi

printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME

printf '%s\n' \
  "INSERT INTO appointments (customer_id, service_id, time) VALUES (:'customer_id', :'service_id', :'service_time');" |
  "${PSQL[@]}" -v customer_id="$CUSTOMER_ID" -v service_id="$SERVICE_ID_SELECTED" -v service_time="$SERVICE_TIME" >/dev/null

printf 'I have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
