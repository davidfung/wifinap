# WiFi Nap
Disable WiFi and automatically re-enable it shortly afterwards

## Notes
  - Timer survives app restarts and phone restarts as long as app is restarted.
  - Check WiFi status at 30 seconds interval

## Technical
  - Time-based countdown
  - Test killing app
  - Test phone restart
  - Handle case of WiFi already off on startup
  - Keep WiFi off when timer is active
  - Keep WiFi off when timer is inactive

