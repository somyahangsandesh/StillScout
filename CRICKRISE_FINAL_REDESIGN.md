# CRICKRISE — FINAL REDESIGN
### Ruthless Founder Analysis | August 2026

> *This document attacks the previous strategy document with fresh eyes. It does not preserve ideas out of loyalty. It preserves only what survives the attack. The goal is maximum addictiveness and commercial viability, not strategic completeness.*

---

## 1. THE 5 BIGGEST REMAINING WEAKNESSES

### Weakness 1: The Unit Economics Are Terminally Broken and the Strategy Knows It but Doesn't Fix It

The previous document contains this sentence: *"At 100,000 players, revenue is ~$60,000/year."* Then it says: *"The business does not work at 10,000."* It offers no structural fix — just the instruction to reach 500,000 players.

Do the math that the document avoids:

The global Nepali cricket diaspora is 3.5 million people. Not all of them play cricket. Not all cricket players will join a structured league. Realistically 15–20% are active players — call it 700,000 people. That is the ceiling of the primary market. At 10% Pro conversion and $26/year ARPU, ceiling revenue is **$1.8M/year from a market that takes 5+ years to fully penetrate.** That is a lifestyle business, not a company. The strategy oscillates between "Scenario A: lifestyle business" and "Scenario B: venture-scale" without being honest that the player subscription model cannot reach Scenario B within the defined primary market.

The problem is not the market. The problem is the monetization unit: individual player subscriptions at $26/year are the wrong financial primitive for this community. The strategy identifies this in passing (unit economics section, honest assessment) and then does nothing about it.

### Weakness 2: The Organizer Is the Load-Bearing Wall and There's No Redundancy

Every sentence of data quality in the product depends on one volunteer organizer per league and one volunteer scorer per match. These are people with day jobs who do this out of love. The strategy makes organizers free forever as a feature. What it doesn't address is: what happens when the Okinawa organizer gets a new job, has a baby, or moves to Tokyo?

The entire league's data pipeline stops. There is no succession mechanism, no backup scorer system, no way for a player to self-report their own stats, no organizer incentive to train a replacement. The strategy calls organizer churn a risk in passing (Risk 6 — "founding team burns out") but frames it as a founder problem, not a structural product problem. It is a structural product problem. The volunteer layer will fail at scale. The product has no design response to this failure mode.

### Weakness 3: The Viral Loop Does Not Actually Loop

The strategy describes the viral mechanism as: player shares WhatsApp card → friends see it → friends ask organizer "how do I join?" → new players enter the system.

This is not a loop. It is a broadcast with a broken conversion funnel. Count the steps between "someone sees a WhatsApp card" and "they have an OVR of their own":

1. Tap the link on the card
2. Land on match scorecard / player profile
3. Download the app (if they don't have it)
4. Create an account
5. Find or contact an organizer who plays in their city
6. Get registered to a team by that organizer
7. Play in 5 verified matches
8. Receive their own OVR

Eight steps. Most people will stop at step 3 because there is no league they can join right now. The CTA "Join your next league" on the live match center page doesn't help if there is no league in their city. The card generates vanity engagement — people say "nice!" — not new players.

The strategy states that "in WhatsApp communities of 50-200 Nepali cricket players, one MVP card shared generates 10-30 views" and implies this drives growth. It doesn't quantify how many of those views convert to registered players. The honest number is probably less than 1%. The viral loop has a conversion hole in the middle that the strategy never patches.

### Weakness 4: The OVR Political Problem Is Structurally Unsolvable as Designed

The strategy lists this as Risk 4 and offers "use 'form rating' language instead of 'overall rating'" as the mitigation. This is insufficient to the point of being dismissive.

In Nepali cricket communities — as in most South Asian diaspora communities — cricket seniority carries real social weight. The 42-year-old who has played for the community for 15 years, helped build the league, drives the younger players to matches, and commands respect is not going to accept that a 24-year-old's OVR of 78 exceeds his 61, especially when that number is displayed publicly in the app that the whole community uses. He will not say "this system is sophisticated and acknowledges my form decline with nuance." He will say the app is broken and he will say it loudly, because community reputation matters more to him than any app.

Renaming OVR to "form rating" does not fix this. It just slightly softens the initial reaction before the underlying resentment sets in. The strategy has no structural solution — no career prestige dimension, no opt-out mechanism for public display, no way to honor longevity alongside current form. It mentions the problem and then effectively ignores it.

This is not a minor UX concern. In tight-knit communities of 80-120 people where one influential member's opinion shapes collective adoption, one senior player publicly rejecting the system can collapse an entire community's engagement. This has happened repeatedly to fitness and sports apps that surface comparative data in tribal community contexts.

### Weakness 5: CricHeroes Will Copy OVR the Moment CrickRise Proves It Works, and "Relationship Density" Is Not a Real Defense

The strategy's response to the CricHeroes competitive threat is: *"CricHeroes is India-focused and large. Large companies are slow to serve edge cases. Win on relationship density."*

This is the response of a startup that hasn't thought hard enough about how it loses.

CricHeroes has 49 million users, engineering resources, and the established scorer infrastructure to roll out an OVR-style player rating feature across their entire user base in under 6 months once they decide to prioritize it. They will not do this when CrickRise has 150 users in Okinawa. They will do it the moment CrickRise reaches 5,000 users and gets written up in a cricket media outlet, or the moment a CricHeroes product manager reads about it. At that point they will ship a "Player Rating" feature to 49 million users simultaneously, with their existing data advantage, at zero marginal cost to them.

The strategy's defense — "CricHeroes can't give every organizer a personal phone call" — is real but temporary. It is a 6-18 month window, not a moat. The strategy correctly identifies that data lock-in is the real long-term moat but doesn't design the V1 product to accelerate data lock-in as fast as possible before the window closes.

Relationship density is a launch tactic, not a competitive defense. The strategy confuses the two.

---

## 2. THE FINAL REDESIGNED CONCEPT

### What Survives the Attack

**KEEP:**
- The OVR system. It is the product's only truly differentiated idea. Keep it and harden it.
- Jersey-number-first scorer UX. Correct insight, non-negotiable.
- Offline-first scoring. The product dies without this.
- Player career portability across teams and leagues. This is the moat. Design the data model for it on day one.
- Organizer as distribution, not as customer. Correct. But now design for organizer redundancy.
- Ball-by-ball event log as the immutable source of truth. Non-negotiable for data integrity.

**REMOVE OR REPLACE:**
- Individual player subscription as the primary revenue model → replaced with league subscription
- "Relationship density" as the competitive defense → replaced with data accumulation speed
- The 14-day free trial → replaced with a 7-day trial with hard expiry
- Public OVR without career context → replaced with OVR + career tier displayed together
- WhatsApp card as the viral mechanism → retained but redesigned with a direct "join waitlist" CTA
- "Nepali diaspora" as the full market definition → reframed as the beachhead, not the ceiling

### The Redesigned Concept in One Paragraph

CrickRise is a cricket identity platform. Every player gets a permanent, portable career profile — OVR rating, career stats, milestone archive — that travels across every league they ever play in. The platform is free for organizers. Leagues pay a seasonal subscription that unlocks the full experience for every player in the league. The OVR system is the product's soul: a rolling, weighted rating that reflects genuine current form, displayed in a leaderboard so every player knows exactly who is one position above them and how close the gap is. The design goal is to make closing that gap feel achievable. That feeling is the addiction.

### The Structural Fixes

**Fix 1: B2B Monetization — Leagues Pay, Players Benefit**

Stop trying to convert individual players at $26/year. One organizer decision pays for the entire league. This removes the prisoner's dilemma ("I don't want to pay unless everyone pays") and makes the financial decision a B2B transaction where ROI is obvious. Organizers already spend money on prize money. A platform fee is a natural complement.

**Fix 2: Organizer Redundancy**

Every league must have a Primary Organizer and at least one Co-Organizer. The platform enforces this during setup. Co-Organizer has full admin access. If the Primary Organizer goes inactive for 30+ days during an active season, the Co-Organizer is automatically elevated. Scorer assignments can be changed by any admin-level user, not just the organizer. The data pipeline has no single point of failure.

**Fix 3: Career Tier Alongside OVR**

Every player profile displays two numbers side by side: **OVR** (current form rating, dynamic) and **CAPS** (total verified career matches, permanent and always increasing). OVR belongs to the young high-performer. CAPS belongs to the veteran. Senior players who have played 100+ career matches have visible prestige that no young player can take from them, regardless of their OVR differential. Both numbers are on the public leaderboard — OVR leaderboard for one tab, CAPS leaderboard for another. The veteran who resents his OVR still wants his 127 career caps publicly displayed.

**Fix 4: Viral Conversion Fix — The Waitlist Card**

Every shared card includes two CTAs:
1. "Follow [Player]" — one tap, they follow without registering (guest follow, just a web view)
2. "Cricket in [City]? Join the waitlist" — they enter their city and phone number

The waitlist CTA does not require them to find an organizer. CrickRise collects the leads and routes them to the nearest existing organizer. If no organizer exists in their city, they go into a "founding player" waitlist and receive a message: "We'll notify you when a league starts near you." When a new organizer in that city signs up, they receive the pre-collected player leads immediately. The flywheel closes.

**Fix 5: Accelerate Data Lock-In Before CricHeroes Notices**

The window is 12-18 months. The objective in that window is to accumulate verified career data for as many players as possible, so that switching has a real cost. Concretely: every player who reaches 20+ verified matches on CrickRise has a career record they would have to rebuild from zero on any competing platform. The product must prioritize retention (keeping players engaged between seasons) and league continuity (ensuring the same community runs season 2, 3, 4 on CrickRise) over acquisition. Depth of data per player beats breadth of players.

### Target Users (Unchanged but Clearer)

**Primary player:** Nepali male cricketer, 18–38, living outside Nepal, currently playing in an informal community league with no digital infrastructure. Has a WhatsApp group instead of a fixture schedule. Cares intensely about cricket performance. Wants proof that he is good.

**Primary organizer:** The one person in each community doing the administrative work — scheduling, record-keeping, managing the group chat. Usually doing this for free because they love it. Currently working with Google Sheets or paper. Wants something that makes the league look professional without adding to their workload.

**Not the primary target:** Professional players, cricket academies, national association administrators, casual players who play once a year.

---

## 3. EXACT V1 FEATURE LIST

This is not a feature category list. These are the exact screens, flows, and data interactions a developer needs to start building tomorrow.

---

### MODULE 1: ORGANIZER SETUP (WEB + MOBILE)

**Screen: Create League**
- Fields: League name (text), logo (image upload, optional), format (dropdown: T20 / ODI / Custom — if Custom, enter overs per side), home city (text)
- On submit: league is created, organizer receives a shareable league link

**Screen: Create Season**
- Fields: Season name (e.g., "2026 Season 1"), start date, end date
- One league can have multiple seasons sequentially, not concurrently
- Season is "Draft" until organizer publishes it

**Screen: Add Teams**
- Team name, optional team logo
- Limit: up to 16 teams per season in V1
- Each team has a roster page

**Screen: Register Players to Team**
- Organizer enters player name + jersey number
- If the player has a phone number already in the system (prior account), the system links to their existing global player profile
- If no match: creates a new player record; the player claims it later via link
- Bulk import: CSV upload with columns [Name, Jersey Number, Phone (optional)]
- Result: each player is assigned a jersey number within that team for that season

**Screen: Create Fixture**
- Fields: Date, time, venue (text), home team (dropdown), away team (dropdown)
- Scorer assignment: select from list of registered users who have scorer access; field is optional at creation but required before match can go Live
- Fixtures appear in league calendar immediately

**Screen: Assign Co-Organizer**
- Required before publishing season
- Enter phone number or email; recipient receives an invite link
- Co-Organizer has identical admin permissions to Primary Organizer

**Screen: Publish Season**
- Shows pre-publish checklist: 2+ teams ✓, 1+ fixture ✓, co-organizer assigned ✓, payment status
- If league is Free tier: publish allowed, Pro features locked for all players
- If league is Pro tier (paid): publish unlocks all Pro features for all players in this league
- Payment collection happens here: Stripe Checkout or Apple/Google IAP depending on platform

**Screen: Organizer Dashboard (home)**
- Active season standings (auto-calculated: points, NRR)
- Upcoming fixtures this week
- Matches awaiting result confirmation
- Player correction queue (disputed stats flagged for admin action)

**Screen: Correction Mode**
- Accessible by Primary Organizer and Co-Organizer only
- Shows every match as an expandable list
- Select a match → see innings → see ball-by-ball log
- Tap any delivery row → edit modal: change runs, change extra type, change wicket type/dismissed player/fielder
- Every correction is flagged `is_admin_correction: true`, original entry preserved in `original_delivery_id`
- After saving correction: all stats and OVR for affected players are queued for recomputation
- Audit log: "Over 14.2 — corrected by [Organizer] on [Date]: 4 runs → 6 runs"

---

### MODULE 2: SCORER APP (MOBILE, OFFLINE-FIRST)

**Screen: Scorer Home**
- Shows only matches assigned to this scorer that are scheduled for today or upcoming 3 days
- Each match shown as a card: Teams, Date, Time, Venue
- Status: Upcoming / Ready to Start / Live / Completed

**Screen: Pre-Match — Toss**
```
TOSS

Who won the toss?
[ OKINAWA WARRIORS ▼ ]

Decision?
[ BAT FIRST ]    [ FIELD FIRST ]

[ CONFIRM TOSS ]
```
One screen, three taps.

**Screen: Pre-Match — Playing XI Selection (Batting Team)**
- Shows full registered squad as a scrollable checklist
- Each item: jersey number (large, leftmost), player name
- Default: all players selected (checkmark visible)
- Tap to deselect; 11 must be selected before proceeding
- "SELECT 11" counter displayed as players are tapped
- Touch targets: 80px height per row minimum

**Screen: Pre-Match — Batting Order**
- Shows selected 11 players
- Drag handle on right of each row to reorder
- Instruction at top: "Set top 4 order. Rest can be adjusted as innings progresses."
- Batters 5-11 can remain in default registration order
- [ BEGIN MATCH → ]

**Screen: Active Scoring — Three-Zone Layout**

```
┌────────────────────────────────────────────────┐
│  ZONE A — MATCH STATE                           │
│                                                 │
│  OKI WARRIORS   127/4   14.2 ov               │
│  ─────────────────────────────────────────    │
│  #7  ROSHAN     58*(39)  ●                     │
│  #18 SANDIP     21*(17)                        │
│  ─────────────────────────────────────────    │
│  Bowling: #23 BIKASH   2/24 (5.2 ov)          │
│  Last 6: ● 6 · 1 · 0 · 4 · W · 2             │
├────────────────────────────────────────────────┤
│  ZONE B — PRIMARY ACTIONS                       │
│                                                 │
│  [ 0 ]  [ 1 ]  [ 2 ]  [ 3 ]  [ 4 ]  [ 6 ]    │
│                                                 │
│  [ W ]  [ WD ] [ NB ] [ BYE] [LBY ]           │
│                                                 │
├────────────────────────────────────────────────┤
│  ZONE C — SECONDARY ACTIONS                     │
│                                                 │
│  [ UNDO ]    [ BOWL CHG ]    [ ··· MORE ]      │
└────────────────────────────────────────────────┘
```

Button size: 0/1/2/3/4/6 buttons are 64×64px minimum. W/WD/NB/BYE/LBY are 56×56px minimum. Never smaller.

Color: W button is solid red text on white. WD/NB are orange text. BYE/LBY are yellow text. Run buttons are neutral/dark text on white. UNDO is gray with warning icon.

**Flow: Tap [W] — Wicket Modal**
```
WICKET — #7 ROSHAN

How out?
[ BOWLED ] [ CAUGHT ] [ LBW ] [ RUN OUT ]
[ STUMPED ] [ HIT WKT ] [ RETIRED ] [ OTHER ]

↓ If CAUGHT or STUMPED:
Who fielded?
[ #11 AMIT ] [ #4 SURAJ ] [ #9 DEV ] [ #6 PRADEEP ]
[ #2 KUMAR ] [ #15 HARI ] [ #22 RAJAN ] [ #3 SAGAR ]
← all fielding team players shown by jersey number →

↓ If RUN OUT:
Which batter was run out?
[ #7 ROSHAN (striker) ] [ #18 SANDIP (non-striker) ]

↓ New batter coming in:
Next batter: [ #12 ARJUN → ]
(shows next in batting order, can override by tapping any listed player)

[ CONFIRM WICKET ]
```
Zero typing. All tappable.

**Flow: Tap [BOWL CHG] — Bowling Change**
```
Who is bowling the next over?

[ #4 SURAJ ] [ #9 DEV ] [ #6 PRADEEP ]
[ #2 KUMAR ] [ #8 BIKASH ] [ #15 HARI ]
(excludes: current bowler, current batters)
```
One tap to confirm.

**Flow: Tap [UNDO]**
```
Undo last delivery?

Over 14.2 · 4 runs · #7 ROSHAN batting · #23 BIKASH bowling

[ CANCEL ]   [ UNDO THIS DELIVERY ]
```
Two-tap confirmation. Undo is available for the last delivery only. For deeper edits, organizer uses Correction Mode.

**Flow: Tap [··· MORE]**
- Fix batter: swap which registered batter is at which crease
- Fix bowler: reassign this over's bowling stats to a different player
- Retired hurt: mark current batter as retired (can return); new batter enters
- Powerplay start/end: toggle powerplay indicator
- Super over: creates new super over innings record

**Screen: Innings Transition**
```
INNINGS COMPLETE
Okinawa Warriors: 174/9 (20 overs)

TARGET: 175 off 20 overs

[ BEGIN 2ND INNINGS → ]
```
Tap to proceed to fielding team's Playing XI selection → Batting order → Scoring begins.

**Offline Behavior:**
- All deliveries written to local SQLite immediately on entry
- Network status banner: 🔴 OFFLINE (red), 🟡 SYNCING (yellow after reconnect), ✅ SAVED (green)
- Sync unit: per delivery (not per over) — each delivery has a UUID preventing duplicate writes
- On reconnect: unsynced deliveries upload in chronological order
- If scorer's phone dies: completed overs already synced to server; organizer can resume with a new device for remaining overs; any conflict shown explicitly for admin resolution — never silently overwritten

**Screen: Post-Match Confirmation (Scorer)**
```
MATCH COMPLETE

Okinawa Warriors:   174/9 (20 ov)
Tokyo Rhinos:       156/7 (20 ov)

RESULT: Okinawa Warriors won by 18 runs

Suggested MVP: #7 ROSHAN KC (58*, 3/24)

[ CONFIRM RESULT ]   [ EDIT BEFORE CONFIRMING ]
```
Scorer confirms. Match enters "Pending Organizer Verification" state. Organizer receives push notification. Organizer approves or sends to Correction Mode.

---

### MODULE 3: PLAYER PROFILE (MOBILE)

**Screen: My Profile**

```
┌──────────────────────────────────────────────┐
│  #7  ROSHAN KC                               │
│  Okinawa Warriors · Batting All-rounder      │
│                                              │
│  OVR  86          CAPS  47                   │
│  ─────────────────────────────────────────  │
│  BAT  89   BOWL  78   FIELD  84             │
│                                              │
│  FORM  ↑ ↑ → ↑ ↓  (last 5 matches)         │
│                                              │
│  2026 SEASON                                 │
│  14 matches · 487 runs · 21 wkts            │
│  Avg 38.4 · SR 142 · Econ 6.8 · 3 MVP      │
│                                              │
│  League Rank  #4                             │
│  CAPS Rank    #2  (2nd most career matches) │
│                                              │
│  ── CAREER MILESTONES ──                     │
│  🏏 First Match  |  ★ First MVP             │
│  50+ scored ×11  |  5-wkt haul ×2           │
└──────────────────────────────────────────────┘
```

Display rules:
- OVR shows after 5 matches. Before that: "OVR — Building Profile (3/5 matches)"
- BAT/BOWL/FIELD show as three separate numbers always (these are always visible, free)
- OVR breakdown (what inputs are driving each domain) is Pro-gated
- CAPS (career matches) is always visible and always free
- Form strip: arrows computed from OVR delta per match (up/flat/down), last 5 matches, newest rightmost

**Screen: League Standings Tab**

```
OKINAWA NEPALI CRICKET LEAGUE
2026 Season 1

STANDINGS
─────────────────────────────────────
Team              W  L  D  Pts  NRR
─────────────────────────────────────
1. Okinawa Warriors  6  1  0   12  +1.42
2. Tokyo Rhinos      5  2  0   10  +0.87
3. Osaka Kings       4  3  0    8  +0.22
─────────────────────────────────────

UPCOMING
Jun 15  Okinawa Warriors vs Fukuoka XI  14:00

LEADERBOARD (tabs: OVR | BATTING | BOWLING | CAPS)

OVR LEADERBOARD
────────────────────────────────────
#1  Bikash Rai      (Tokyo Rhinos)    OVR 88
#2  Roshan KC       (Oki Warriors)    OVR 86
#3  Anil Tamang     (Osaka Kings)     OVR 82
...
```

The leaderboard defaults to OVR. Tabs for Batting Rating, Bowling Rating, CAPS. Every player can see where they stand.

**Screen: Other Player's Profile**

Identical layout to My Profile except:
- OVR breakdown is hidden (Pro-gated and private)
- Season stats visible
- Career stats: matches (CAPS) always visible; career batting average and wickets visible free
- "Follow" button (follow sends push notifications when this player scores a 50, takes a wicket haul, or wins MVP)

---

### MODULE 4: LIVE MATCH EXPERIENCE (MOBILE + WEB)

**Screen: Live Match Center (public URL, no login required)**

```
LIVE ●
Okinawa Warriors vs Tokyo Rhinos
Okinawa Warriors batting

OKI WARRIORS    127/4
14.2 overs

──────────────────────────────────────
#7  ROSHAN KC    58*(39)   ● on strike
#18 SANDIP       21*(17)
──────────────────────────────────────
Bowling: #23 BIKASH   2/24   5.2 ov
──────────────────────────────────────
Partnership: 67 runs (8.1 ov)
──────────────────────────────────────
RECENT:  ● · 6 · 1 · 0 · 4 · W · 2
──────────────────────────────────────
Need 175 · Chase starts after this innings
──────────────────────────────────────

[ SCORECARD ]    [ BALL BY BALL ]

──────────────────────────────────────
🏏 Follow this match? Share the link:
[ COPY LINK ]  [ WHATSAPP ]

New to CrickRise? Get your own OVR →
[ Cricket in your city? Join waitlist ]
──────────────────────────────────────
```

The "Join waitlist" CTA captures phone/city from non-registered viewers. These leads are routed to the nearest organizer.

Polling interval: every 5 seconds. WebSockets come in V2. HTTP polling is acceptable for V1 at this scale.

**Scorecard Tab:** Standard cricket scorecard layout. Batting card (batter, how out, fielder, runs, balls, 4s, 6s, SR) + Bowling card (bowler, overs, maidens, runs, wickets, economy). One innings at a time; toggle between innings after both complete.

**Ball by Ball Tab:** Chronological list of deliveries. Wickets shown in red. Fours shown in blue. Sixes shown in bold. Extras shown in orange. Each ball shows: over.ball, bowler jersey, batter jersey, outcome.

---

### MODULE 5: POST-MATCH EXPERIENCE

**Screen: Match Summary (auto-shown after organizer confirms result)**

```
MATCH RESULT

✓ OKINAWA WARRIORS WON by 18 runs

Okinawa Warriors   174/9 (20 ov)
Tokyo Rhinos       156/7 (20 ov)

★ MVP: #7 ROSHAN KC
   58*(39)  ·  3/24

[ VIEW FULL SCORECARD ]
[ YOUR MATCH CARD → ]   (taps to shareable card)
```

**The Shareable Match Card (server-side rendered, 1080×1080px)**

```
┌────────────────────────────────────────┐
│  🏏 CRICKRISE                          │
│                                        │
│  #7  ROSHAN KC         OVR  86        │
│  Okinawa Warriors                      │
│                                        │
│  vs Tokyo Rhinos  ·  WON ✓            │
│  Jun 15, 2026                          │
│                                        │
│  58*(39)   3/24   ★ MVP               │
│                                        │
│  crickrise.com/match/[id]              │
└────────────────────────────────────────┘
```

Generated for every player who participated. Every card links to the public match center page (the conversion entry point). Shareable via native share sheet: WhatsApp, LINE, Instagram, copy link.

---

### MODULE 6: OVR REVEAL FLOW (ONE-TIME EVENT, AFTER 5TH MATCH)

Triggered when OVR becomes available for the first time. Not a push notification. A full-screen event inside the app when the player opens it after match 5 processes.

**Screen 1: The Reveal**
- Full black background
- Jersey number (top, large, muted)
- Player name (below jersey)
- Animated counter: starts at 50, counts up/down to actual OVR over 1.5 seconds
- OVR lands and pulses once
- Below: "BATTING 89  ·  BOWLING 78  ·  FIELDING 84"
- Below: "Ranked #4 in Okinawa Nepali Cricket League"
- Below: "CAPS: 5  (5 verified career matches)"

**Screen 2: Share**
- "Your cricket career has officially started."
- Auto-generated OVR Reveal Card (1080×1080px):
  ```
  OVR  86
  ROSHAN KC  ·  #7
  Okinawa Warriors
  5 matches played
  "My cricket career starts here."
  crickrise.com
  ```
- [ SHARE TO WHATSAPP ] [ SHARE TO LINE ] [ COPY LINK ] [ SKIP ]

**Screen 3: Pro Prompt (immediately after share or skip)**
- "Your BAT score is 89. Your BOWL score is 78."
- "What's driving the gap? Go Pro to see the full breakdown."
- [ START 7-DAY FREE TRIAL ] [ NOT NOW ]

If they tap "Not Now": dismiss. The Pro prompt reappears once per week on app open, maximum 3 times before going quiet. No more harassment after 3 dismissals.

---

### MODULE 7: OVR SYSTEM (COMPUTATION LOGIC)

Runs as a background job after organizer confirms each match result. Does not run in real-time during scoring.

**Data inputs per player per match (all computed from the Delivery table):**
- Runs scored, balls faced, dismissal (yes/no), 4s, 6s
- Wickets taken, overs bowled, runs conceded, maidens
- Catches taken, run-out contributions (direct + assists), stumpings (if WKB)

**Batting Rating (BAT, 1–99):**
```
Batting Average (runs per dismissal):           weight 35%
Strike Rate (relative to format benchmark):     weight 25%
Consistency (% innings with 15+ runs):          weight 20%
Big innings rate (50s + 100s per 10 innings):  weight 15%
Recent form (last 5 match batting average):     weight 5%  [applied as modifier]
```

**Bowling Rating (BOWL, 1–99):**
```
Bowling Average (runs per wicket):              weight 30%
Economy Rate (relative to format benchmark):    weight 25%
Strike Rate (balls per wicket):                 weight 25%
Wicket rate (wickets per match):                weight 15%
Death bowling performance (last 4 overs):       weight 5%  [applied as modifier]
```

**Fielding Rating (FIELD, 1–99):**
```
Catches taken per match:                        weight 40%
Run-out contributions:                          weight 35%
Stumpings (WKB role only, weighted 2×):        weight 25% [WKB only]
```
FIELD is marked "estimated" in UI until the player has 10+ matches. Its influence on OVR is reduced by 30% for players with fewer than 10 matches.

**OVR by Role:**
```
Pure Batter (PB):            BAT×0.75 + FIELD×0.20 + BOWL×0.05
Pure Bowler (PBOW):          BOWL×0.75 + FIELD×0.20 + BAT×0.05
Batting All-rounder (BAR):   BAT×0.55 + BOWL×0.30 + FIELD×0.15
Bowling All-rounder (BOAR):  BOWL×0.55 + BAT×0.30 + FIELD×0.15
Wicketkeeper-Batter (WKB):   BAT×0.50 + FIELD×0.35 + BOWL×0.15
```

**Sample size handling (Bayesian shrinkage toward 50):**
```
0–4 matches:   Display "Building Profile (X/5)" — no OVR shown
5–9 matches:   OVR range capped 42–68. Label: "Developing"
10–19 matches: OVR range capped 36–80. No label.
20+ matches:   Full range 30–95. Number is meaningful.
```

**Recency weighting:**
```
Last 5 matches:         40% of OVR computation
Previous 6–15 matches: 35%
Career beyond that:     25%
```

**Anti-gaming rules (enforced at ingestion, not retroactively):**
1. Batter must face 6+ deliveries in a match for batting stats to count toward OVR
2. Bowler must complete 1 full over for bowling stats to count
3. A player may not serve as the official scorer for a match they are playing in. If they do, their own stats are flagged `self_scored: true` and weighted at 0.7× in OVR calculations
4. Opposition context modifier: ±10% weight based on opposing Team OVR (simple average of opponents' BAT/BOWL scores). Never more than 10% in either direction
5. Friendly matches: organizer marks fixture as "Friendly" at creation. Friendly stats count at 0.5× toward OVR and are visually distinguished in match history
6. Impossible statistics flag: batter score > 200 in T20, bowler wickets > 10 in single match — match held in "Pending Verification" state, excluded from OVR until organizer manually confirms

**CAPS (Career Matches Played):** A simple integer counter. Increments by 1 each time a player is confirmed in the Playing XI of a verified match. CAPS cannot be lost, edited, or gamed. It only ever increases. CAPS is always free, always public, always permanent.

---

### MODULE 8: NOTIFICATIONS (LAUNCHED AT V1 — NOT V1.5)

Notifications are not optional infrastructure. They are a core retention mechanism and must ship in V1.

**Triggered notifications (push, for players who have installed the app):**
- Ranking change: "You've moved to #3 in bowling in Okinawa NPC League. (was #4)"
  - Fires when the player moves up or down in the league leaderboard
  - Fires for changes within ±5 positions only (irrelevant to show "moved from #42 to #43")
- Match result: "Okinawa Warriors won by 18 runs. Your stats have been updated."
  - Fires after organizer confirms result
- MVP: "[Your name], you've been awarded MVP. Your OVR may update."
  - Fires on MVP award confirmation
- Milestone: "You're 23 runs from 500 career runs."
  - Fires when within 30 runs/5 wickets of a major career milestone
- Upcoming match: "Your match vs Tokyo Rhinos begins in 2 hours."
  - Fires 2 hours before scheduled fixture start
- Following player alert: "Bikash Rai just scored a 50. [View live match]"
  - Fires when a player you follow hits 50, takes 3+ wickets in an innings, wins MVP

---

### WHAT IS EXPLICITLY NOT BUILT IN V1

No AI commentary. No live streaming. No merchandise. No fantasy cricket. No coaching plans. No academy management. No umpire management. No player discovery marketplace. No team website builder. No rivalries feature. No Player of the Week. No social feed. No web admin dashboard with analytics. No advanced trend graphs.

These are not "future roadmap." They are distractions from the five things V1 must prove: organizers stay, scorers cope, players return, OVR gets shared, players consider paying.

---

## 4. EXACT MONETIZATION MODEL

### The Model: League Pro Subscription

**Price: ¥14,800 per league per season (~$97 USD)**

Not per player. Per league. The organizer pays once and every player in the league gets Pro features for the duration of that season.

**What League Pro Unlocks (for every player in the league, automatically):**
- OVR attribute breakdown: BAT/BOWL/FIELD with plain-English explanation of the top factor affecting each domain ("Your batting average is solid but your strike rate is pulling BAT down. Bat faster.")
- OVR trend graph: season-to-date OVR movement by match
- Form detail: which matches drove the current form strip
- Cross-league leaderboard (compare against players in other leagues in the same country, where enough data exists)
- Premium shareable card: cleaner design, custom background, OVR prominently featured
- Ad-free experience (if ads are ever introduced; committed to no ads in V1)

**What Is Free Forever (regardless of Pro status):**
- OVR number (single number)
- BAT / BOWL / FIELD (three domain numbers)
- CAPS (career matches)
- Current season stats: matches, runs, wickets, catches, MVPs
- Form strip (5-match directional arrows)
- League ranking (in-league)
- All scorecard data
- Live match feed
- Match scorecard
- Basic shareable match card
- All organizer features, forever

**The Trigger Moment:** When the organizer publishes a new season. Before confirming the fixture schedule, a single modal appears:

```
UNLOCK PRO FOR YOUR ENTIRE LEAGUE

¥14,800 for this season

Every player in your league gets:
• Full OVR breakdown ("what's holding them back")
• OVR trend graph across the season
• Premium shareable match cards
• Cross-league rankings

Your league ran a ¥25,000 prize pool last season.
This is ¥14,800 for the platform that made it possible.

[ ACTIVATE PRO — ¥14,800 ]    [ CONTINUE FREE ]
```

If they tap "Continue Free": league is published free. Pro prompt appears again when the next season is created. No harassment between seasons.

**Why this model over individual player subscriptions:**

1. One decision per league, not 120 individual conversion attempts. A single organizer conviction replaces needing 10% of players to individually decide to pay.

2. Organizers already spend money on their leagues. Prize money, equipment, ground rental — ¥14,800 is a line item next to ¥25,000 in prize money, not a luxury purchase.

3. Eliminates the prisoner's dilemma. Players don't hesitate because "I don't want to pay unless my whole team does." The whole team is already in.

4. Creates social pressure in favor of payment. Players who want their OVR breakdown will ask their organizer to upgrade the league. The organizer gets social credit for doing it.

5. Better unit economics at realistic scale. At 100 active leagues globally (completely achievable within the Nepali diaspora across 5 countries): ¥1,480,000/year ($9,700). At 500 leagues: ¥7,400,000/year ($48,500). At 1,000 leagues: ¥14,800,000/year ($97,000). These numbers are achievable without needing 500,000 individual player subscribers.

**Trial:** None. There is no trial for League Pro. The organizer has seen the product for free for one full season before paying. They know what they're buying. A free trial on a per-season product creates complexity without adding value. The first season on the platform is the trial.

**International pricing:**

| Market | Price per league per season |
|--------|----------------------------|
| Japan | ¥14,800 (~$97) |
| UAE/Qatar | AED 200 (~$54) |
| Malaysia | MYR 200 (~$43) |
| UK | £55 (~$70) |
| USA | $85 |
| Nepal | NPR 8,000 (~$60) |

These are not guesses at purchasing power parity — they are anchored to prize money norms in each market. In every Nepali cricket community surveyed, prize money ranges from $50–$300 for winning a tournament. Platform fee at 30–50% of prize money is defensible.

**Secondary individual Pro option (available but not promoted):**

Players in free leagues can subscribe individually at ¥1,980/year ($13). This is not the primary model and is not advertised prominently. It exists as a safety valve for highly engaged players in communities whose organizer won't pay. The OVR reveal screen triggers a soft mention of individual Pro; no 7-day trial, no hard push.

---

## 5. THE ONE THING THAT MAKES THIS ADDICTIVE

### Not the OVR reveal. The gap.

The OVR reveal is exciting once. You can't be surprised by your own number twice.

What makes people compulsively return to a competitive product is not the initial discovery of their position. It is **the specific, visible gap between where they are and where they want to be, expressed in terms of a real human they know personally.**

The addictive design insight is this: **every player's home screen should show the person one rank above them.**

Not their own profile. Not a generic leaderboard. The person one slot above them, with their OVR, their jersey number, their team. The implicit question hanging in the air every time you open the app:

*Can I catch Bikash?*

Bikash is OVR 88. You're OVR 86. You play in the same league. You've faced him. You think you're better. The number says otherwise. Every time you open the app, Bikash is there. Two points above you. Reachable.

This is how competitive compulsion works. Not through abstract rankings. Through the face of a specific rival you personally know. The dopaminergic loop is: play match → OVR updates → check if you closed the gap → if not, identify what to improve → want to play the next match faster.

FIFA Ultimate Team is addictive because you're constantly aware of your card's relative scarcity. Chess.com is addictive because your ELO gap to the next level is always specific. Strava is addictive because you can see the exact time difference between you and the segment leader.

**CrickRise becomes addictive the moment it makes the gap personal.**

### Build the Product Around This Insight

**The home screen is not "My Profile." The home screen is "My Position."**

```
MY POSITION

OVR  86  ·  Rank #4 in Okinawa NPC League

─────────────────────────────────────────
#3  Bikash Rai  (Tokyo Rhinos)   OVR  88
     ↑  2 points above you
─────────────────────────────────────────
#4  YOU — Roshan KC               OVR  86
─────────────────────────────────────────
#5  Anil Tamang (Osaka Kings)    OVR  83
     ↓  3 points below you
─────────────────────────────────────────

FORM  ↑ ↑ → ↑ ↓
Next match: 4 days
```

Not top-10. Not full leaderboard. Just the three people closest to you, with you in the middle. Bikash above. Anil below. The gap is specific. The competition is real.

**Notifications reinforce the compulsion loop:**

- "Bikash Rai scored 67 in today's match. He's still #3." → You care. You were hoping he'd have a bad day.
- "Anil Tamang is on a good run — 3 matches with 40+. He's closing in on #4." → You feel anxiety. You open the app.
- "You've moved from #4 to #3. You passed Bikash." → The reward. The dopamine hit. The moment worth chasing.

**This is the insight everything else must serve:**

The scorer UX exists to produce accurate OVR data. Accurate OVR data makes the gap real. The gap being real makes the rivalry meaningful. Meaningful rivalry drives return visits, pushes share behavior ("look where I am now"), and makes people beg their organizer to upgrade to League Pro so they can see the full breakdown and understand what to fix.

The product isn't about recording cricket matches. It's about making you care — deeply, personally, almost irrationally — about a two-point OVR gap with someone you play cricket with every weekend.

Build everything in service of that two-point gap. That's the product.

---

*Document produced: August 2026*
*Authors: CrickRise Founding Product Team — Final Redesign Pass*
*Status: Execution-ready. This supersedes all prior strategy documents. No prior version should be referenced for feature decisions.*
