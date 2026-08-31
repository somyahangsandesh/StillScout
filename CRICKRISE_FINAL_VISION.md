# CRICKRISE — THE DEFINITIVE PRODUCT VISION
## "Part of Something Bigger"

---

## THE CORE TRUTH

These players are Nepali. They're far from home.

They play cricket in car parks, small grounds, borrowed fields — because cricket is one of the few things that still makes them feel like themselves. It connects them to Nepal, to home, to who they are before they became a migrant worker.

When that match ends on Saturday, nobody outside that field knows it happened. No record. No story. It disappears into a WhatsApp message and then into nothing.

**CrickRise exists to make those matches mean something permanently.**

Not "league management." Not "scoring app." Not "OVR tracker."

A platform that says: *"We were there. We remember. Your cricket life matters."*

---

## THE THREE LAYERS OF "SOMETHING BIGGER"

```
LAYER 1 — YOUR STORY (personal)
  Your Passport. Your OVR. Your career.
  Every match you've ever played, remembered forever.
  This belongs to you.

LAYER 2 — YOUR COMMUNITY (local)  
  Your club. Your league. Your rivals.
  The championship you're chasing.
  The records you're building together.
  This is your cricket home.

LAYER 3 — THE MOVEMENT (global)
  Every Nepali cricket community on the platform.
  Okinawa. Tokyo. Osaka. Doha. Dubai. Kuala Lumpur.
  You are not alone. You are part of something.
  This is the story of Nepali cricket in the world.
```

---

## ARCHITECTURE: PASSPORT + COMMUNITY + SESSION

### THE CRICKET PASSPORT

Every user's permanent cricket identity. Exists from their first match. Can never be taken away.

```
ROSHAN KC
CR-1247

OVR 86 · FORM ↑

87 sessions recorded
2,418 career runs · 96 wickets · 14 MVPs
3 seasons · 1 championship

Okinawa Warriors (2025-2026)
Nepal Tokyo XI (2024)
```

The Passport is player-owned. Portable. Follows them from city to city, team to team, country to country.

**CR Number:** Every player gets a permanent CrickRise ID (CR-1247). Short, simple. This is their cricket identity number — more permanent than a jersey number, more meaningful than a username.

**Unclaimed profiles:** A captain can add "Roshan KC, #7" to a match without Roshan having the app. His stats accumulate. When Roshan downloads CrickRise, he claims his profile and all his history appears instantly. Nobody loses their past.

### THE COMMUNITY

Where competition lives. Your club, your league, your rivals.

```
OKINAWA NEPALI CRICKET LEAGUE
Season 2026 · Week 8 of 12

Your team: Okinawa Warriors · 2nd place
You are 3 points behind Tokyo Rhinos

6 matches remaining
Your next match: Saturday vs Fukuoka Tigers
```

The community has history. Records. A Season Book. Legends. This is the cricket home that players become emotionally attached to.

### THE SESSION

The atomic unit of play. What actually happens on Saturday.

A Session can be:
- **League Session** (part of an official season) — 1.0× OVR weight
- **Casual Session** (informal, whoever showed up) — 0.5× OVR weight
- **Self-reported** (no live scorer) — 0.2× OVR weight, shown with badge

All three feed the Passport. All three are real cricket.

---

## THE FULL NAVIGATION

Five tabs. Each answers a specific question:

```
HOME      — Who am I? How am I doing? What's next?
LEAGUE    — Where do I stand? What's happening in my season?
PLAY      — Start a session, join a session, score
COMMUNITY — The bigger picture: rankings, records, the movement
ME        — Full passport, career, share card, settings
```

---

## HOME SCREEN — FINAL DESIGN

The home screen should feel like waking up and knowing where you are in the world.

```
Good morning, Roshan.          ← greeting, time-aware
                               
PASSPORT SNAPSHOT
┌─────────────────────────────────────┐
│  OVR  86   ↑ 2 this season         │
│                                     │
│  BAT 89   BOWL 78   FIELD 84       │
│  ───── ─── ────── ─── ─────        │  ← sparkline
│         form: 5-match trend        │
└─────────────────────────────────────┘

HUNTING LIST
  ● #2  Bikash Rai    OVR 88   ↑ 2 ahead
  ▶ #3  YOU           OVR 86
  ○ #4  Sandip        OVR 83   ↓ 3 below

SEASON POSITION
  Okinawa Warriors · 2nd of 6 teams
  3 points behind Tokyo Rhinos

[▶  START SESSION ]  ← the primary CTA, always visible

UPCOMING
  Saturday · vs Fukuoka Tigers · League
  "Win and you go top of the table."

IN THE COMMUNITY
  "3 matches happening right now across Japan"
  "Amit KC (Osaka) just scored his first century"
```

The last section — "In the Community" — is the glimpse into Layer 3. Not a feed. Just 2 lines. A gentle reminder that you're part of something wider.

---

## SESSION FLOW — THE QR JOIN SYSTEM

Starting a session is the most frequent action in the product. It must be fast.

### Opening a Session (Captain/Scorer)

```
STEP 1: What kind of session?
  [LEAGUE MATCH]  ← select a pre-created fixture
  [CASUAL SESSION] ← just playing today

STEP 2: (Casual only) How many overs?
  [5]  [10]  [15]  [20]  [Custom]

STEP 3: QR CODE GENERATED
  Large QR code fills the screen.
  "Show this to your players."
  
  As players scan, names appear:
  "Roshan KC joined ✓"
  "Bikash Rai joined ✓"
  "New player: enter name +"  ← for players without app

STEP 4: ASSIGN TEAMS
  Drag players to Team A or Team B
  (or randomize)

STEP 5: TOSS
  [TEAM A] won the toss
  Decision: [BAT] [FIELD]

STEP 6: OPENING BATTERS
  Select 2 from Team A's players
  (jersey number chips, full names)

STEP 7: OPENING BOWLER
  Select 1 from Team B's players

START SCORING →
```

Total time from opening the app to first ball: under 3 minutes for casual. Under 90 seconds for a pre-set league fixture.

---

## THE SCORER EXPERIENCE

The scorer is the most important person in the product. If scoring is painful, everything fails.

### Screen Layout

```
╔══════════════════════════════════════╗
║  ZONE A (45% of screen)              ║
║  Match state — broadcast clarity     ║
╠══════════════════════════════════════╣
║  ZONE B1 — 4 standard runs           ║
║  [ 0 ]  [ 1 ]  [ 2 ]  [ 3 ]          ║
╠══════════════════════════════════════╣
║  ZONE B2 — 2 hero runs               ║
║  [       4       ] [       6       ] ║  ← full half-width each
╠══════════════════════════════════════╣
║  ZONE C — events                     ║
║  [ W ]  [ WD ]  [ NB ]  [ BY ] [LBY] ║
╠══════════════════════════════════════╣
║  ZONE D — controls                   ║
║  [UNDO]    [BOWL CHG ●]    [···]     ║
╚══════════════════════════════════════╝
```

Zone A shows:
- Team name + match type badge [LEAGUE] or [CASUAL ½×]
- Score at 52sp — truly broadcast-sized
- Current batters with CR numbers (not jersey, for reliability)
- Current bowler with figures
- Recent 6 balls as circular dots (color-coded)
- Target/required if chasing

4 and 6 are on their own row. They are the most emotionally significant balls in cricket. They get the most screen space.

### Permission system

```
SCORER (assigned before match)
  → Can enter all deliveries during the match
  → Cannot edit past deliveries during live play
  → One scorer per match, no exceptions

CAPTAIN
  → Can make corrections after match
  → Approves final result
  → Cannot change live scoring (prevents cheating)

PLAYERS
  → Read only. Cannot touch anything.

THE WITNESS SYSTEM
  → Before final approval, 2 players confirm result
  → Creates accountability without needing official umpires
```

---

## THE COMMUNITY SCREEN

This is where "something bigger" becomes visible.

```
THE COMMUNITY

JAPAN                                    [ALL TIME ▼]

TOP PLAYERS — OVR
1.  Roshan KC         CR-1247   OVR 91  🔥
    Okinawa Warriors
2.  Dipesh Sharma     CR-0441   OVR 88
    Tokyo Rhinos
3.  Bikash Rai        CR-0892   OVR 86
    Okinawa Warriors
...

TOP BATTERS  |  TOP BOWLERS  |  MOST IMPROVED

─────────────────────────────────────────────

JAPAN RECORDS
Most runs (career):   Roshan KC     2,418
Most wickets:         Dipesh Sharma  134
Highest score:        Anil Tamang    147*
Best figures:         Bikash Rai     6/14

─────────────────────────────────────────────

LEAGUES ACTIVE IN JAPAN
  Okinawa Nepali Cricket League     6 teams
  Japan Nepali Premier League      10 teams
  Kanto Cricket League              8 teams

─────────────────────────────────────────────

THE MOVEMENT
  1,847 sessions recorded in Japan
  312 players with active passports
  Last session: 2 hours ago
  Today: 3 matches in progress
```

The "THE MOVEMENT" section at the bottom is the emotional anchor for Layer 3. Simple numbers. But they communicate: *you are not alone. This is real. This is growing.*

---

## THE LEAGUE SCREEN

Three tabs: STANDINGS · FIXTURES · SEASON STORY

### SEASON STORY tab

This is new and important. It's a curated auto-generated narrative of the season so far:

```
OKINAWA LEAGUE 2026 — THE STORY SO FAR

Week 1-3: Warriors and Rhinos dominated early,
  with Roshan KC emerging as the season's standout batter.

Week 4: Fukuoka Tigers upset the standings with
  back-to-back wins. Three teams within 2 points.

Week 7 (last week): Roshan KC broke the league record
  for highest individual score — 127* vs Osaka Kings.
  Warriors are now 3 points clear.

CURRENT FORM
  Warriors  W W W W L  ← hot
  Rhinos    W L W W W  ← strong
  Tigers    L W W L W  ← inconsistent

TITLE RACE
  Warriors need: win 2 of their last 3
  Rhinos need: win all 3 + Warriors drop points

RECORDS THIS SEASON
  Highest score:  Roshan 127*      Week 7
  Best bowling:   Bikash 5/18      Week 4
  Most MVPs:      Roshan (×3)
```

This is the Season Story. Auto-generated from match data. No editor needed. The data tells the story.

---

## THE SEASON BOOK

At the end of every season, CrickRise publishes the **Season Book** — a permanent record of everything that happened.

```
OKINAWA NEPALI CRICKET LEAGUE
SEASON 2026 · SEASON BOOK

CHAMPION: OKINAWA WARRIORS

Final standings:
1. Okinawa Warriors   W8 L2  Pts 16
2. Tokyo Rhinos       W7 L3  Pts 14
...

Season Awards:
  Player of the Season:   Roshan KC
  Best Batter:            Roshan KC   (487 runs, avg 48.7)
  Best Bowler:            Bikash Rai  (21 wkts, econ 5.8)
  Most Improved:          Sandip Thapa (OVR +14)
  Rookie of the Season:   Dev Shrestha

Season Records:
  Highest score:    Roshan 127* vs Osaka Kings
  Best figures:     Bikash 5/18 vs Fukuoka Tigers
  Highest total:    Warriors 218/3

Match of the Season:
  Week 9: Warriors vs Rhinos
  Warriors 174/6, Rhinos 172/9
  Won by 2 runs in the final over.

All 45 matches. Every scorecard. Forever.
```

The Season Book is permanent. In 10 years, players can show their children: "This was the 2026 season. I was the Player of the Season. I was there."

That is "something bigger."

---

## THE LEGENDS WALL

Every community has a Legends Wall — the all-time greatest players by position.

Legends are earned, not bought:
- Minimum 5 completed seasons in the community
- Top 3% of all-time OVR for their role
- At least 1 championship

```
OKINAWA LEGENDS

BATTING                    BOWLING
1. Roshan KC (2024-26)    1. Bikash Rai (2023-26)
   OVR 86, 3 seasons         OVR 79, 4 seasons
   1 championship            2 championships

...
```

Aspiring to be a Legend is a multi-year motivation. It creates the longest possible retention loop.

---

## THE HERITAGE SYSTEM

After 3+ seasons on CrickRise, a player earns a **Heritage Badge** on their profile. After 5+ seasons: **Elder Badge**. After 10: **Legend (community)**.

These are not bought. They are earned by simply continuing to play cricket and having it recorded.

This creates a sense of tenure and belonging. You've been here a long time. You're part of the history.

```
ROSHAN KC · CR-1247

[HERITAGE]    ← 3+ seasons
OVR 86
```

---

## THE PLAYER CARD — FREE VS PRO

The shareable card is the product's marketing engine.

**Free Card:**
- White background
- CR number, name, OVR number
- Last match performance
- crickrise.com link
- Simple. Clean. But obviously basic.

**Pro Card:**
- Dark gradient background (deep green-black)
- Large gold OVR number (72sp)
- BAT / BOWL / FIELD scores visible
- League ranking badge: "#3 Okinawa 2026"
- Heritage/Legend badge if applicable
- Hot streak indicator if active
- Season Capsule button
- Looks like a premium sports trading card

The visual gap between free and Pro is the upsell. It is designed to be seen in a WhatsApp group and make every free user want the Pro card.

---

## MONETIZATION — FINAL MODEL

**Free (permanent, no exceptions):**
- Cricket Passport (your identity)
- All session history (your data)
- Basic OVR number
- Current season stats
- League standings and fixtures
- Live match center
- Basic share card (white)
- QR join system
- Community board (view only)

**Pro (¥1,980/year — the only price, no monthly option):**
- Full OVR breakdown (BAT/BOWL/FIELD detail)
- FORM sparkline and trend
- Career history beyond current season
- The Hunting List (personalized gap display)
- Cross-community rankings
- Advanced stats (batting average, bowling average, economy trend)
- Personal Benchmarks ("you score faster against spin")
- Premium dark share card (the FIFA card)
- Season Capsule (rich annual summary)
- The Verdict (plain-language match summary)
- Ad-free experience

**Tournament Activation (¥6,000 one-time, captain pays):**
- Official tournament status
- Tournament Champion badge on all player cards
- 1.5× OVR weight for all tournament matches
- Season Book entry

**The paywall trigger:**
After match 5, when OVR first unlocks. The OVR number counts up in an animation. BAT/BOWL/FIELD appear blurred. "Your OVR is 74. Go Pro to see what's driving it." This is the single highest-intent monetization moment in the product.

---

## NOTIFICATIONS — MEANINGFUL ONLY

```
IMMEDIATE (send now):
"You were named MVP. Share your moment." → share card ready

MATCHDAY:
"Your match is in 4 hours. Okinawa Warriors vs Tokyo Rhinos."
"You're starting this match 2 points behind Bikash."

POST-MATCH:
"Your OVR went up 2.1 points after today's match."
"Bikash overtook you in bowling rankings. He's 1 point ahead."

MILESTONE APPROACH:
"You are 13 runs from 500 this season."
"One more wicket and you break the league record for wickets in a season."

LEAGUE:
"The league table changed. You're now 2nd."
"Your next match could take you top of the table."

COMMUNITY:
"You're now #38 in the Japan Nepali Cricket rankings."
(Sent only when rank changes — not regularly)
```

No spam. Every notification creates a reason to open the app.

---

## ONBOARDING — FINAL FLOW

```
SCREEN 1: SPLASH
  CRICKRISE logo animation (1.5 seconds)
  → auto-navigate to welcome

SCREEN 2: WELCOME
  "Your cricket life, finally official."
  Three lines:
    "Every match remembered."
    "Your career, yours forever."
    "Part of the cricket community."
  [Continue with Phone]
  [Sign in with Google]

SCREEN 3: PHONE + OTP
  Phone entry → OTP (6-digit Pinput, auto-submit)

SCREEN 4: CREATE YOUR PASSPORT
  "What's your name?"
  "What do you play?" (role chips: Batter/Bowler/All-rounder/Keeper)
  "Optional: your usual jersey number"
  
  → CR Number assigned automatically
  → Passport created

SCREEN 5: JOIN OR BUILD
  "How will you use CrickRise?"
  
  [JOINING A COMMUNITY]
    "I'm a player — someone will invite me to their league"
    → Enter invite code OR
    → "I'll look for a session near me" (browse open sessions)
  
  [BUILDING A COMMUNITY]
    "I organize cricket — I'll set up a league"
    → League creation flow

SCREEN 6: (if joining) ENTER INVITE CODE
  Large code input
  Team name + league preview shown
  [JOIN] button
  
  OR: "Skip — I'll join later" (goes to home with empty state)
```

Total: 4-6 screens. Under 90 seconds. User has a Passport and (optionally) a team before finishing.

---

## TEAM REGISTRATION — FINAL MODEL

**Problem:** Most informal cricket has fluid squads. Same players appear in different combinations every match.

**Solution: The Community Pool**

Every person who has ever played in a CrickRise session exists in a community pool. They don't belong to one team. They can appear in any session.

```
COMMUNITY POOL (example)
  Roshan KC    CR-1247  OVR 86  (usually plays for Warriors)
  Bikash Rai   CR-0892  OVR 79  (usually plays for Warriors)
  Sandip       CR-1823  OVR 71  (plays for multiple teams)
  New player   [add name]       (guest, gets a temp CR number)
```

**For formal leagues:** Captain creates a team with a core squad (pre-registered). These players appear on the team profile. Fixtures are pre-set. Playing XI confirmed day before.

**For casual sessions:** Scorer opens QR. Whoever scans appears. Teams assigned on the day. No pre-registration.

**The dual approach:**
- Pre-registered squad: captain adds 15 players to the club. They're "club members."
- QR join: any day, any player can join a session. Even people not in the club.
- Both work. No choice forced.

---

## DATA MODEL — KEY CONCEPTS

```
PLAYER
  id: CR-XXXX (permanent, unique)
  name, role, jerseyNumber (optional)
  claimed: boolean (true if phone-linked account)
  
SESSION
  id, type (league/casual/reported)
  leagueId (optional — if part of a league)
  teamA, teamB (arrays of player CRs)
  scorer: player CR (single, authoritative)
  status: setup/live/completed/verified
  ovrWeight: 1.0 / 0.5 / 0.2

DELIVERY
  id: UUID (deduplication for offline)
  sessionId, inningsNumber, over, ball
  batsmanId, nonStrikerId, bowlerId
  runsOffBat, extraType, extraRuns
  wicket: { type, dismissedId, fielderId }
  
LEAGUE
  id, name, seasonName
  teams: [teamId]
  format, overs
  
TEAM
  id, name, leagueId
  coreSquad: [playerId] (for registered teams)
  
SEASON_BOOK (generated at season end)
  leagueId, seasonName
  champion, allAwards, allRecords
  matchIndex: [sessionId] (all sessions)
```

Stats are always computed from deliveries. Never stored directly. Any correction to a delivery auto-recomputes everything downstream.

---

## THE FIVE EMOTIONAL MOMENTS TO DESIGN AROUND

These are the moments where users feel most connected to the product:

**1. THE FIRST OVR REVEAL** (after match 5)
The number counts up from 50. Slow. Dramatic. The BAT/BOWL/FIELD bars animate in one by one. Then: "Your OVR is unlocked. You are CR-1247." This is the product saying: "You are official. We see you."

**2. THE MVP NOTIFICATION**
Push notification arrives: "You were named MVP." Tap → full-screen MVP card, gold background, your performance. One tap to share. This is the moment of public recognition.

**3. THE SEASON CAPSULE**
End of season. A generated card: "Your 2026 Season." OVR journey, key stats, if champion — the trophy. The year in cricket, yours forever.

**4. THE RECORD BROKEN**
During a match: "RECORD BROKEN — Roshan KC sets a new league high score: 127*." Notification goes to every player in the league. Not just you. Everyone knows.

**5. THE HERITAGE BADGE**
After completing your 3rd season on CrickRise: "You've been here for 3 seasons. You're part of the history of your community." A Heritage badge appears on your profile. Nobody can take it. You earned it by showing up.

---

## THE ONE THING

If CrickRise can only be remembered for one thing:

**The feeling you get when you open the app after a match and see your career has grown.**

Not a notification. Not a leaderboard. Just the simple fact that what you did on Saturday is now permanently part of your cricket story, alongside everything else you've ever done.

That's not a feature. That's a product. And it's one nobody has built for these communities.

---

*This document is the product. Build from this. Every design decision should ask: "Does this make a Nepali cricketer in Okinawa feel like their cricket life matters?"*

*If yes: build it.*
*If no: remove it.*
