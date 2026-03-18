# FiveM-FiniAC-multicharacter-bucket-routing-bug-fix
For when server owners are using Fini Anti-Cheat and having server players put in temporary routing buckets due to a multicharacter script conflict. A lightweight and reliable routing bucket enforcement system for FiveM servers using Qbox (qbx_core) and Fini Anti-Cheat.  This script ensures all players are placed into a single routing bucket.


**🧠 Bucket Enforcer (Qbox + FiniAC)**

A lightweight and reliable routing bucket enforcement system for FiveM servers using Qbox (qbx_core) and Fini Anti-Cheat.

This script ensures all players are placed into a single routing bucket (bucket 0) after joining, preventing players from being isolated in separate worlds.


**🚨 Problem This Solves**

Some servers experience an issue where:

Players join into different routing buckets

Players cannot see each other

/fixbuckets temporarily resolves it

Issue is inconsistent and difficult to trace

This is commonly caused by:

FiniAC isolating players during loading

Improper handling of routing bucket restoration

Incorrect event timing (e.g. wrong framework events)


**✅ Features**

🔒 Forces all players into bucket 0

🔁 Works with FiniAC deferral system

⚙️ Fully compatible with Qbox (qbx_core)

🧠 Smart timing (post-load enforcement)

🚫 Prevents repeated client refresh flickering

📊 Debug logging for bucket tracking

🧪 Manual commands for testing and fixing


**📦 Requirements**

ox_lib

Qbox (qbx_core)

Fini Anti-Cheat (FiniAC)


**📁 Installation**

Create a folder:

resources/[local]/bucket_enforcer

Add the files:

fxmanifest.lua

server.lua

client.lua


Add to your server.cfg:

ensure ox_lib
ensure finiac
ensure qbx_core
ensure bucket_enforcer


**⚠️ Important:**
Make sure this resource loads after FiniAC and qbx_core

**⚙️ How It Works**

🧩 FiniAC Integration

FiniAC places players into temporary routing buckets during connection.

This script:

Hooks into:

FiniAC:DeferStarted

FiniAC:DeferFinished

Sets the original routing bucket to 0

Ensures FiniAC returns players to the correct world


**🧩 Qbox Integration**

Uses the correct Qbox event:

QBCore:Server:OnPlayerLoaded

This ensures bucket enforcement happens after the player fully loads into the world.


**🔁 Smart Rechecks**

The script runs delayed checks at:

2s

5s

10s

15s

25s

These re-enforce bucket 0 silently without triggering visual flicker.


**👁️ Visibility Fix (Client)**

Includes optional client-side:

Visibility reset

Streaming refresh

Conceal cleanup

Only triggered when needed to avoid flickering.


**🎮 Commands**

/bucket

Shows your current routing bucket.

-> "You are in bucket 0"

/fixmybucket

Forces you into bucket 0 and refreshes visibility.

/fixmyworld

Client-side visibility/streaming refresh only.

fixbuckets (Server Console)

Forces all players into bucket 0.

/bucketdebug

Outputs detailed debug info to server console.


**🧪 Debug Logging**

The script logs:

Bucket before/after changes

FiniAC deferral stages

Qbox load events

Recheck enforcement

Example:

Moved 6 (PlayerName) from bucket 1 to 0 | reason=QBCore:Server:OnPlayerLoaded


**⚠️ Notes**

This script enforces a single global bucket (0)
→ Not suitable if you rely on instancing/interiors

If players still get separated:

Check for scripts using:

SetPlayerRoutingBucket

NetworkConcealPlayer

apartments / shells / housing


**🧠 Why This Works**

Uses correct Qbox load timing

Respects FiniAC lifecycle

Avoids invalid player IDs during deferral

Prevents client flickering from repeated refreshes
