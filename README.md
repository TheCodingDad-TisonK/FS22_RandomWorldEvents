# FS22 Random World Events

Adds dynamic random events to Farming Simulator 22 to make gameplay more unpredictable and exciting.

Original mod page: https://www.kingmods.net/en/fs22/mods/73950/random-world-events

---

## 📌 Overview

**FS22 Random World Events** introduces random events that occur during gameplay, such as economic changes, vehicle issues, weather anomalies, field bonuses, and special events. Events can affect money, vehicle wear, time speed, and more.

---

## 🧾 Features

- 🌍 **Random world events** triggered over time
- 🔁 **Event cooldown system** to prevent spamming
- 🔥 **Event intensity & frequency controls**
- 📣 **In-game notifications & warnings**
- 🧠 **Debug mode with logging**
- 🛠️ **Event categories you can enable/disable**
- 🧾 **Event history tracking**
- 🧩 **Mod settings available in pause menu (if supported)**

---

## 🎛️ Default Settings

| Setting | Default | Description |
|--------|---------|-------------|
| enabled | `true` | Enable/disable events |
| frequency | `5` | How often events happen (1–10) |
| intensity | `2` | Event strength (1–5) |
| cooldown | `30` | Minimum minutes between events |
| showNotifications | `true` | Show notifications |
| showWarnings | `true` | Show warnings |
| debugLevel | `1` | Debug verbosity (0–2) |

---

## 🧠 Console Commands

### Basic Commands

| Command | Description |
|--------|-------------|
| `events` | Show help |
| `events status` | Show current settings |
| `events enable` | Enable all events |
| `events disable` | Disable all events |
| `events reload` | Reload settings from XML |

### Event Management

| Command | Example | Description |
|--------|---------|-------------|
| `events trigger <eventId>` | `events trigger market_boom` | Manually trigger an event |
| `events list` | - | Show all enabled events |
| `events enable <category/event>` | `events enable economic` | Enable a category or event |
| `events disable <category/event>` | `events disable vehicle` | Disable a category or event |
| `events frequency <1-10>` | `events frequency 7` | Set frequency |
| `events intensity <1-5>` | `events intensity 4` | Set intensity |
| `events cooldown <minutes>` | `events cooldown 60` | Set cooldown |
| `events skip` | - | Skip the current active event |
| `events history` | - | Show recent event history |
| `events test` | - | Trigger a random event for testing |

---

## ⚖️ License

All rights reserved. Unauthorized redistribution, copying, or claiming this mod as your own is **strictly prohibited**.  
Original author: **TisonK** 

---

## 📬 Support

Report bugs or request help in the comments section of the original mod page.

---

*Enjoy your farming experience!* 🌾
