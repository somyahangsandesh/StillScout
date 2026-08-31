# CRICKRISE — DEFINITIVE PRODUCT CONCEPT
### Final Synthesis | August 2026

> *This is the final version. Decisions are made. Nothing is hedged. A developer can start building the V1 scorer and player profile after reading this document.*

---

## 1. THE PRODUCT IN ONE PARAGRAPH

CrickRise is the cricket identity platform for South Asian migrant communities — the Nepali, Bangladeshi, and Pakistani cricketers playing informal weekend matches in Japan, Qatar, Malaysia, and beyond, with no digital infrastructure beyond a WhatsApp group. It gives every player three live numbers — OVR, Rank gap, and Hot Streak — that update after every match, whether it is a formal league fixture or an impromptu Sunday friendly, because most cricket in these communities is informal and a platform that requires a season to exist before it delivers value will never reach them. Any two players can open the scorer app, record a friendly, and walk away with an updated career profile. When that profile gets shared on WhatsApp — and it gets shared because the Pro card looks unmistakably different from the free card — the people who see it want one of their own, and that desire is the engine that grows the platform. The Pro card costs ¥1,980 per year, less than the entry fee for a single cricket match in most of these communities, priced so that a migrant worker earning a modest wage does not need to think twice.

---

## 2. THE CORE ADDICTIVENESS MECHANISM

### The Three Numbers

Every player has exactly three numbers displayed on their home screen after every match. These three numbers create three separate reasons to open the app and three separate moments worth sharing.

**NUMBER 1 — OVR (Overall Rating, 1–99)**

OVR is the player's absolute performance rating, computed from weighted batting, bowling, and fielding domain scores based on their role. It is the single number a player can point to and say "that is how good I am at cricket." OVR updates within 60 minutes of match result confirmation. For friendly matches it updates at 0.5× weight; for league and tournament matches at 1.0× weight. The number changes after every scoreable match. This is the number a player is proud to share.

**NUMBER 2 — RANK GAP (Position vs. Named Rival)**

Rank is never expressed as an abstract position like "#38 in Japan." It is expressed as a gap to a specific named human: "Bikash is 2 OVR points ahead of you." The home screen shows three rows only — the player one rank above, the player themselves, the player one rank below — with the exact OVR gap displayed. This is the number that creates compulsion. A 2-point gap is psychologically reachable. An abstract rank of #38 is not.

Rankings are computed within the player's most active league first. If the player has no active league (plays only friendlies), ranking is computed among all players in their city who have played 5+ scored matches.

**NUMBER 3 — HOT STREAK (Consecutive Matches Above Career Average)**

Hot Streak counts the number of consecutive matches in which a player performed above their own career average. The definition varies by primary role:

- **Batters and Batting All-rounders:** Runs scored ≥ career batting average in that match. Requires facing 6+ deliveries.
- **Bowlers and Bowling All-rounders:** Economy rate ≤ career economy rate AND wickets ≥ 1, or economy below career economy by more than 1.5 runs/over. Requires bowling 1+ complete overs.
- **Wicketkeeper-Batters:** Either batting criterion met, or 2+ dismissals (catches + stumpings) behind the wicket.

Hot Streak resets to 0 after any match where the player fails to meet their criterion. A streak of 0 after a bad match is visible — there is no hiding it. A streak of 5 or more shows a 🔥 flame icon on the player profile and on their shareable card. Streaks of 3–4 show a 🔥 without the counter. Streaks of 1–2 are displayed as a number only, no flame.

Hot Streak serves a different emotional function than OVR. OVR rewards long-term quality. Hot Streak rewards current momentum. A player can have a mediocre OVR of 64 and still be on a 🔥 streak of 7, which is worth sharing. This gives lower-ranked players a reason to engage.

### How the Three Numbers Interact

After every match:

1. OVR recomputes and either rises or falls
2. Rank gap recomputes: player either closed the gap, held position, or was overtaken
3. Hot Streak either extends or resets

Each of these produces a distinct notification. Each creates a distinct sharing moment. Each creates a distinct emotional experience:

- OVR rising = pride
- Closing the gap on a rival = competitive satisfaction
- Hot Streak extending = momentum and bragging rights
- Hot Streak breaking = sting that creates motivation to play again fast

### The Home Screen

```
┌──────────────────────────────────────────────┐
│  MY POSITION                                 │
│                                              │
│  ── ABOVE YOU ──────────────────────────    │
│  #3  Bikash Rai · Tokyo Rhinos   OVR 88     │
│       ↑ 2 points ahead of you               │
│  ─────────────────────────────────────────  │
│  #4  YOU — Roshan KC              OVR 86    │
│       🔥 Hot Streak 5                        │
│  ─────────────────────────────────────────  │
│  #5  Anil Tamang · Osaka Kings   OVR 83     │
│       ↓ 3 points below you                  │
│                                              │
│  BAT 89 · BOWL 78 · FIELD 84               │
│  FORM  ↑ ↑ → ↑ ↓                           │
│                                              │
│  Next match: 4 days                         │
│  [ SCORE A FRIENDLY ]                        │
└──────────────────────────────────────────────┘
```

The home screen is not "My Profile." It is "My Position." Bikash is always there. Two points above. Reachable.

### Notifications That Fire After Each Match

All notifications fire within 5 minutes of organizer match confirmation.

| Trigger | Notification Text |
|---------|-------------------|
| OVR rises | "Your OVR is now 87. You moved up." |
| OVR falls | "Your OVR dropped to 84 after today's match." |
| Player overtakes rival | "You passed Bikash Rai. You're now #3." |
| Player is overtaken | "Anil Tamang is now #4. You've dropped to #5." |
| Gap narrows by 2+ | "You closed 2 points on Bikash Rai. Gap: 2 OVR." |
| Hot Streak extends to 3+ | "🔥 Hot Streak: 3 matches above your average." |
| Hot Streak hits 5 | "🔥🔥 Hot Streak 5 — your profile badge is live." |
| Hot Streak breaks | "Your streak ended at 5. Start a new one." |
| MVP awarded | "You've been awarded MVP. Your OVR may update." |
| Career milestone approaching | "47 runs from 500 career runs." |

---

## 3. THE EXACT MATCH TYPES

### Match Type 1: Friendly

**Definition:** An unstructured match between any group of players. No organizer required. No formal roster required. Any registered player with the CrickRise app can open the scorer and start a friendly.

**OVR weight:** 0.5× — all stats count, all milestones count, but the influence on OVR is halved.

**Who can score it:** Any registered CrickRise user. The scorer selects the match type "Friendly" on first screen.

**Data collected:** Full ball-by-ball data. Every run, every wicket, every extra, every fielder. Identical data collection to a league match.

**Roster handling:** Players can be searched by name/phone (linked to existing CrickRise profiles) or added as ad-hoc entries with name + jersey number. Ad-hoc players get a "guest profile" that can be claimed later via a link. If the same guest profile name appears in future matches, the scorer can link them to an existing account.

**Team composition:** Any number of players per side (minimum 2v2 for stats to count). No Playing XI restriction — the scorer records whoever is actually batting or bowling.

**OVR calculation eligibility:** Batter must face 6+ deliveries. Bowler must bowl 1+ complete over. Same as league matches, at 0.5× weight.

**What the scorer sees:**

```
NEW FRIENDLY MATCH

Your Team Name (optional): [____________]
vs. Team Name (optional):  [____________]

Format:
[ T20 — 20 overs ]  [ 10 overs ]  [ 5 overs ]
[ Custom: __ overs ]

[ START SCORING → ]
```

After confirming: same active scoring screen as league match (Zone A/B/C layout). Players added on the fly using the [+ ADD PLAYER] button in Zone A player row, which opens a name + jersey number entry modal.

**Shareable output:** Post-match card generated for every player with 6+ deliveries faced or 1+ overs bowled. Card shows OVR, performance stats, and is tagged "FRIENDLY" in a small badge. Match appears in player's career history tagged as Friendly.

**What distinguishes it in history:** Friendly matches show a "½×" badge in the player's match history list. OVR contribution is shown as half-weight. CAPS counter increments by 1 (same as any verified match — you showed up and played).

---

### Match Type 2: League Match

**Definition:** A formal fixture between two registered teams in an active league season. Organizer required. Players must be on registered rosters.

**OVR weight:** 1.0×

**Who can score it:** A user assigned as scorer by the organizer. Only one designated scorer per match.

**Data collected:** Full ball-by-ball data. Pre-match toss and Playing XI selection required before scoring begins.

**Standings impact:** Win/loss/NRR affects league standings. Points table updates automatically on match confirmation.

**What the scorer sees:** Identical Zone A/B/C layout. The only difference from a friendly is that players are pre-loaded from the team roster — no ad-hoc entry needed (or allowed, without organizer override).

**How it affects OVR:** Full 1.0× weight. Opposition quality modifier applies (±10% based on opposing team's average OVR). Match importance modifier: League final = 1.1× multiplier on OVR impact.

---

### Match Type 3: Tournament Match

**Definition:** A formal match within a paid tournament activation. Organizer pays ¥6,000 one-time to activate a tournament. Tournament matches are the only match type with a 2× OVR boost for the winning team's players.

**OVR weight:** 1.0× base, with winning team receiving 2× multiplier on OVR impact for that match. Losing team receives 1.0× (not penalized). Draw or no result: both teams 1.0×.

**Who can score it:** Organizer-assigned scorer. Same as league match.

**What tournament activation unlocks:**
- Official verified results badge (green checkmark ✓ on scorecard)
- "Tournament Champion" badge on winning players' cards and profiles (permanent)
- 2× OVR impact multiplier for match wins
- Branded PDF scorecard (auto-generated, downloadable)
- Tournament page with bracket/results view

**What the scorer sees:** Identical to league match. One additional pre-match field: "Match type" dropdown showing ["Group Stage", "Quarter-Final", "Semi-Final", "Final"] — this drives the match importance multiplier and the correct bracket position.

**Final match specifics:** Tournament Final has 1.3× OVR multiplier for the winner (not 2× — the 2× applies to all tournament wins, and the Final adds a further 1.3× on top of the base 1.0×, not on top of the 2×). Net effect: Final win = 1.3× OVR impact. Final loss = 1.0×. Regular tournament win = 2.0×.

**What "Tournament Champion" badge looks like:** A small gold trophy icon (🏆) displayed on the player's profile under career milestones, with text "Champion — [Tournament Name] [Year]". Multiple tournament wins accumulate multiple badges. Visible on both free and Pro profiles. This badge also appears on the player's shareable card — free and Pro both show it, because it is a factual record, not a vanity feature.

---

## 4. THE ORGANIZER ROLE (REDEFINED)

### The New Reality

Most cricket in Nepali diaspora communities is informal. Players organize on WhatsApp, show up on weekends, play friendlies, and occasionally coordinate a 1-2 day tournament. A platform that requires a formal organizer before a single match can be scored will never reach these players. The organizer role is now narrowly defined: organizers exist to create formal structure when the community wants formal structure. They are not gatekeepers.

### What Requires an Organizer

1. **A formal league season** — defined by a fixture schedule, standings, points table, promotion/relegation
2. **A tournament with a verified bracket** — requires tournament activation (¥6,000)
3. **Official league standing** — OVR at 1.0× weight

What does NOT require an organizer: any friendly match. Any player can score any friendly at any time.

### What an Organizer Does

**Creates formal structure:**
- Creates a league with name, logo, format
- Creates a season with start/end dates
- Registers teams and players to rosters
- Creates fixtures with date, time, venue
- Assigns scorers to matches (optional — any player in the league can score, but assigning avoids confusion)
- Confirms match results and sends disputed stats to Correction Mode

**Does not:**
- Need to be present at every match
- Score matches themselves (should avoid — see anti-gaming rules)
- Approve individual friendly matches (friendlies require zero organizer involvement)

### The Lightest Possible Organizer Experience

A 6-team 8-match league can be set up in under 10 minutes:

1. **Create League** (60 seconds): Name, format (T20), home city. Done.
2. **Create Season** (30 seconds): Season name, approximate dates.
3. **Add Teams** (2 minutes): 6 team names. Optionally add logos later.
4. **Register Players** (5 minutes): CSV upload with Name, Jersey Number, Phone (optional). Or manual entry 6 players at a time.
5. **Create Fixtures** (2 minutes): Select home/away teams, date, time, venue.
6. **Assign Co-Organizer** (30 seconds): Required before publishing. One other person who can manage the league if the organizer is unavailable.
7. **Publish** (10 seconds): Confirm checklist. League goes live.

Total: Under 10 minutes for a functioning league.

### Co-Organizer Requirement

Every league must designate at least one Co-Organizer before publishing. This is enforced: you cannot publish a season without a Co-Organizer. The Co-Organizer has identical admin access. If the Primary Organizer has not logged in for 30 consecutive days during an active season, the Co-Organizer receives an email/SMS: "You are now the primary admin for [League Name]." No player data is ever at risk due to organizer dropout.

### Creating a League When Most Play Is Informal

The organizer does not need to capture all friendly matches. The system is designed so that friendly matches played before a formal season exist happen automatically — players have already been building OVR from friendlies. When the organizer creates a formal league, they simply register the same players who have been playing informally. Those players' OVR histories (at 0.5× friendly weight) already exist. The league adds formal 1.0× matches on top.

The organizer's pitch to their community is simple: "Register in CrickRise so your friendly matches count. When we organize a proper tournament, your profile will already be live."

---

## 5. THE PLAYER PROFILE (FINAL DESIGN)

### Layout (All Players, Free)

```
┌──────────────────────────────────────────────┐
│  #7  ROSHAN KC                               │
│  Okinawa Warriors · Batting All-rounder      │
│                                              │
│  OVR  86    CAPS  47    🔥 Hot Streak 5     │
│  ─────────────────────────────────────────  │
│  BAT  89   BOWL  78   FIELD  84             │
│  ─────────────────────────────────────────  │
│  FORM  ↑ ↑ → ↑ ↓   (last 5 matches)        │
│                                              │
│  2026 SEASON                                 │
│  14 matches · 487 runs · 21 wkts            │
│  Avg 38.4 · SR 142 · Econ 6.8 · 3 MVP      │
│                                              │
│  League Rank  #4  (2 pts behind #3 Bikash)  │
│  ─────────────────────────────────────────  │
│  CAREER MILESTONES                           │
│  First Match ✓ · First MVP ✓ · 50+ ×11      │
│  5-wkt haul ×2 · Century ×1                  │
│  🏆 Champion — Okinawa Open 2025            │
└──────────────────────────────────────────────┘
```

**Every field defined:**

| Field | Definition | Free/Pro |
|-------|-----------|----------|
| Jersey Number | Set at team registration; follows player per team | Free |
| Name | Player-set | Free |
| Current Team | Most recent team registration | Free |
| Role | Batting All-rounder / Pure Batter / Pure Bowler / Bowling All-rounder / Wicketkeeper-Batter | Free |
| OVR | Weighted domain composite, role-based formula | Free |
| CAPS | Total verified matches (friendly + league + tournament) | Free |
| Hot Streak | Consecutive matches above career average | Free |
| BAT / BOWL / FIELD | Three domain scores | Free |
| Form strip | 5-match directional arrows (↑ = OVR rose, → = unchanged, ↓ = OVR fell) | Free |
| Season stats | Matches, runs, wickets, catches, MVPs, avg, SR, economy | Free |
| League Rank | Position in current league with named rival | Free |
| Career Milestones | Factual achievements (century, 5-for, MVP, champion) | Free |
| Tournament badges | All champion badges | Free |
| OVR breakdown | Which inputs are driving BAT/BOWL/FIELD up or down | **Pro** |
| OVR trend graph | Match-by-match OVR over career | **Pro** |
| Form detail | Which specific matches drove the current form strip | **Pro** |
| Career history | Season-by-season stats beyond current season | **Pro** |
| Cross-league ranking | Rank among all CrickRise players in the same country | **Pro** |

### The Shareable Card — Free Version

Generated automatically after every match for every player with 6+ deliveries faced or 1+ overs bowled. Server-side rendered at 1080×1080px. Shareable via native share sheet (WhatsApp, LINE, Instagram, copy link).

```
┌────────────────────────────────────────┐
│  🏏 CRICKRISE                          │
│                                        │
│  #7  ROSHAN KC                         │
│  Okinawa Warriors                      │
│                                        │
│  OVR  86                              │
│                                        │
│  vs Tokyo Rhinos · WON ✓              │
│  58*(39)  ·  3/24  ·  ★ MVP          │
│                                        │
│  crickrise.com/match/[id]              │
└────────────────────────────────────────┘
```

Design: white background, black text, CrickRise teal accent on the header line. The OVR number is 64pt font. Adequate. Shareable. But sparse.

### The Shareable Card — Pro Version

Same dimensions. Completely different visual weight.

```
┌────────────────────────────────────────┐
│  ██████████████████████████████████   │
│  🏏 CRICKRISE PRO                      │
│  ██████████████████████████████████   │
│                                        │
│  #7  ROSHAN KC                         │
│  Okinawa Warriors                      │
│                                        │
│  OVR 86 · BAT 89 · BOWL 78 · FIELD 84 │
│  #3 Okinawa  🔥 Hot Streak 5          │
│                                        │
│  vs Tokyo Rhinos · WON ✓              │
│  58*(39)  ·  3/24  ·  ★ MVP          │
│                                        │
│  crickrise.com/match/[id]              │
└────────────────────────────────────────┘
```

Design: dark gradient background (deep navy to black), gold/teal accent text, "PRO" badge on the header. The OVR is 64pt in a gold accent color. BAT/BOWL/FIELD sit below it at 24pt in teal. Rank and Hot Streak are on a dedicated line. The visual weight difference from the free card is immediately legible in a WhatsApp message thumbnail.

**The gap between free and Pro cards is the product.** Someone who sees a Pro card in a WhatsApp group and then sees a free card immediately knows the difference. The Pro card looks like something a serious cricketer would have. The free card looks like a receipt. This visual difference is designed before any other Pro feature is designed.

### What Changes After Every Match

Immediately on match confirmation:
- OVR recalculates and displays updated number (with animation on next app open)
- Hot Streak counter updates
- Form strip updates (new arrow prepended, oldest dropped)
- League rank recomputes against all updated OVRs
- Season stats update (runs, wickets, catches, MVPs, avg, SR, economy)
- CAPS increments by 1
- Shareable card regenerates with new stats
- Any career milestones triggered are marked

---

## 6. THE SCORER INTERFACE (FINAL DESIGN)

### Design Principles

1. **One hand, outdoor, in direct sunlight.** Every primary action must be reachable with a right thumb on a standard 6-inch phone screen. No two-handed gestures required for any scoring action.
2. **Zero typing during active scoring.** All player selection is tap-based using jersey numbers as identifiers. Names are secondary.
3. **Offline is the default assumption.** The app functions identically with no internet. Connectivity is a bonus, not a requirement.
4. **The undo is one tap away, always.** Scorer mistakes are inevitable. Recovery must be trivial.
5. **Every screen has a maximum of two questions.** No scorer should ever face a screen that requires reading.

### Friendly Match Flow

**Screen F-1: Match Type Selection**
```
START SCORING

[ FRIENDLY MATCH ]
  Any players · No organizer needed

[ LEAGUE MATCH ]
  Requires organizer assignment
```
One tap to proceed.

**Screen F-2: Format**
```
FORMAT

[ T20 — 20 overs ]
[ 10 overs ]
[ 5 overs ]
[ Custom: [ __ ] overs per side ]

[ NEXT → ]
```

**Screen F-3: Teams**
```
TEAM NAMES (optional)

Team A: [ __________________ ]
Team B: [ __________________ ]

Skip team names? Names can be added later.

[ START → ]
```

**Screen F-4: Active Scoring (same as league)**

Players are added on the fly. When the scorer needs to enter a batter or bowler, an inline player picker appears:

```
WHO IS BATTING?

Search name or jersey #: [ __________ ]

Recent players in this match:
[ #7 ROSHAN ] [ #18 SANDIP ] [ #4 SURAJ ]

+ Add new player
  Name: [_______]  Jersey #: [__]
```

If a searched name matches an existing CrickRise account, the system links automatically. If not, a guest profile is created.

---

### League Match Flow (Differences from Friendly)

**Screen L-1: Match appears pre-loaded in Scorer Home**

Scorer sees only their assigned matches:

```
YOUR MATCHES

Today:
  Okinawa Warriors vs Tokyo Rhinos
  14:00 · Okinawa Sports Park
  [ START SCORING ]

Upcoming:
  Jun 22 · Okinawa Warriors vs Osaka Kings
```

No searching. No league navigation. The scorer taps their match.

**Screen L-2: Pre-Match — Toss**
```
TOSS

Who won?
[ OKINAWA WARRIORS ]   [ TOKYO RHINOS ]

Decision?
[ BAT FIRST ]   [ FIELD FIRST ]

[ CONFIRM ]
```
Three taps maximum.

**Screen L-3: Pre-Match — Playing XI (Batting Team)**

Shows full registered squad as a checklist. Jersey number (large, leftmost) + player name. Default: all selected. Tap to deselect. Counter shows "11 / 11 selected." Touch target: 80px height per row minimum. Proceed only when exactly 11 are selected.

**Screen L-4: Pre-Match — Batting Order**

Shows selected 11. Drag handle on right of each row. Instruction: "Set top 4 order. Rest can be adjusted as wickets fall." Batters 5–11 remain in registration order unless dragged.

---

### Active Scoring Screen (Both Match Types)

```
┌────────────────────────────────────────────────┐
│  ZONE A — MATCH STATE (top 30% of screen)      │
│                                                │
│  OKI WARRIORS   127/4   14.2 ov              │
│  ──────────────────────────────────────────  │
│  #7  ROSHAN    58*(39)  ● on strike           │
│  #18 SANDIP    21*(17)                        │
│  ──────────────────────────────────────────  │
│  Bowling: #23 BIKASH   2/24  (5.2 ov)        │
│  Last 6: ● · 6 · 1 · 0 · 4 · W · 2          │
├────────────────────────────────────────────────┤
│  ZONE B — PRIMARY ACTIONS (middle 45%)         │
│                                                │
│  [ 0 ]  [ 1 ]  [ 2 ]  [ 3 ]  [ 4 ]  [ 6 ]   │
│                                                │
│  [ W ]  [ WD ] [ NB ] [BYE ] [LBY ]          │
│                                                │
├────────────────────────────────────────────────┤
│  ZONE C — SECONDARY (bottom 25%)               │
│                                                │
│  [ UNDO ]   [ BOWL CHG ]   [ ··· MORE ]       │
└────────────────────────────────────────────────┘
```

**Button dimensions:**
- Zone B run buttons (0/1/2/3/4/6): 64×64px minimum
- Zone B event buttons (W/WD/NB/BYE/LBY): 56×56px minimum
- Zone C buttons: 50×50px minimum
- All buttons: 16px border radius, high-contrast text

**Color coding:**
- Run buttons: white background, dark text
- W: white background, red text, red border
- WD/NB: white background, orange text, orange border
- BYE/LBY: white background, amber text, amber border
- UNDO: light gray background, dark gray text, warning icon (⚠️)

---

### Wicket Flow

Tap [W]:

```
WICKET — #7 ROSHAN

How out?
[ BOWLED ]  [ CAUGHT ]  [ LBW ]   [ RUN OUT ]
[ STUMPED ] [ HIT WKT ] [ RETIRED ] [ OTHER ]
```

If CAUGHT or STUMPED:
```
Who fielded?
(all fielding team players shown by jersey number in grid)
[ #11 AMIT ] [ #4 SURAJ ] [ #9 DEV ] [ #6 PRADEEP ]
[ #2 KUMAR ] [ #15 HARI ] [ #22 RAJAN ] [ #3 SAGAR ]
```

If RUN OUT:
```
Which batter was run out?
[ #7 ROSHAN (striker) ]  [ #18 SANDIP (non-striker) ]

Who effected the run out?
(fielding team shown)
```

Always:
```
Next batter coming in:
[ #12 ARJUN ]  ← next in batting order, tappable to override

[ CONFIRM WICKET ]
```

Zero typing. Every step is a tap.

---

### Bowling Change Flow

Tap [BOWL CHG]:
```
Who is bowling next?

[ #4 SURAJ ] [ #9 DEV ] [ #6 PRADEEP ]
[ #2 KUMAR ] [ #8 BIKASH ] [ #15 HARI ]
(excludes: current bowler, current batters)
```
One tap. No confirmation needed.

---

### Undo Flow

Tap [UNDO]:
```
Undo last delivery?

Over 14.2 · 4 runs · #7 ROSHAN batting · #23 BIKASH bowling

[ CANCEL ]   [ UNDO ]
```
Two-tap confirmation. One-level undo only. For deeper corrections: Correction Mode (organizer access).

---

### [··· MORE] Menu

```
Fix batter — swap which registered batter is at which crease
Fix this over's bowler — reassign bowling stats to correct player
Retired hurt — mark batter retired (can return later)
Powerplay — start / end powerplay indicator
Super over — creates new super over innings
Note — add a text note to the match (for disputed calls)
```

---

### Innings Transition

```
INNINGS COMPLETE

Okinawa Warriors:  174/9  (20 overs)

TARGET: 175 runs off 20 overs

[ BEGIN 2ND INNINGS → ]
```

Tap proceeds to Playing XI selection for the fielding team (now batting), same flow as pre-match.

---

### Post-Match Screen (Scorer View)

```
MATCH COMPLETE

✓ OKINAWA WARRIORS WON by 18 runs
Okinawa Warriors:   174/9 (20 ov)
Tokyo Rhinos:       156/7 (20 ov)

Suggested MVP: #7 ROSHAN KC
  58*(39)  ·  3/24

[ EDIT BEFORE CONFIRMING ]   [ CONFIRM RESULT ]
```

On confirm: match enters "Pending Organizer Verification" state. Organizer receives push notification. Organizer approves or opens Correction Mode.

For friendly matches: auto-confirmed after scorer taps [CONFIRM RESULT] — no organizer step needed.

---

### Offline Behavior

**When connection drops:** Red banner at top of screen: "🔴 OFFLINE — All scoring saved locally." Scoring continues without interruption. Every delivery is written to local SQLite immediately on tap.

**On reconnect:** Banner changes to "🟡 SYNCING..." then "✅ ALL DATA SAVED." Deliveries upload in chronological order, deduplicated by UUID (preventing double-writes).

**If scorer's phone dies mid-match:** All completed overs that synced before the phone died are preserved on the server. A different device can resume from the last synced over. Organizer views the gap and can either confirm partial data or open Correction Mode. No data is silently overwritten — conflicts are flagged explicitly.

**Sync unit:** Per delivery, not per over. Each delivery has a UUID. Even mid-over data survives a crash.

---

## 7. MONETIZATION (FINAL, NO RANGES)

### Individual Pro

**Price: ¥1,980 per year**

No monthly option. One price. Annual only. ¥1,980 is ¥165/month, less than a can of beer, less than most cricket match entry fees in Japan. The price does not require deliberation.

**Trial: 7 days.** Triggered at one specific moment: immediately after the OVR reveal screen (first OVR unlock at 5 matches). Not triggered at any other moment. The trial is hard-edged — day 8 the Pro card reverts to the free card. There is no grace period and no re-triggering of the trial.

**What Pro unlocks — the complete list:**

1. **The Pro shareable card** (dark background, OVR + BAT + BOWL + FIELD + Rank + Hot Streak all displayed — see Section 5 for exact design)
2. **OVR breakdown in-app** (plain-English explanation of what is driving BAT, BOWL, and FIELD up or down — e.g., "Your batting average is strong but your strike rate is pulling BAT down. Bat at 130+ to improve.")
3. **OVR trend graph** (match-by-match OVR movement across full career, displayed as a line chart)
4. **Form detail** (which specific matches drove the current form strip — tappable form arrows that expand to show match summary)
5. **Career history beyond current season** (season-by-season stats: year, team, matches, runs, wickets, avg, SR, economy, MVPs)
6. **Cross-league rank** (position among all CrickRise players in the same country who have 10+ matches)

**The paywall trigger:** The only moment the Pro paywall is shown is on the OVR reveal screen. After the reveal, if the player taps "Share to WhatsApp" or "Share to LINE," their free card generates and shares. Below it: "Your card would look like this with Pro →" showing a mockup of the Pro card. One tap: "Get Pro — ¥1,980/year" or "Start 7-day free trial."

The paywall appears in one other context: when a player tries to view the OVR trend graph tab (which is visible on the profile but blurred for free users). A tap on the blurred graph shows: "See your full OVR history. Go Pro — ¥1,980/year." This is the only in-app upsell after the initial reveal. No modal interruptions. No weekly popups. No banner ads.

**What is free, forever, no exceptions:**
- OVR number (single number)
- BAT / BOWL / FIELD (three domain scores)
- CAPS (career match count)
- Hot Streak counter
- All current season stats (matches, runs, wickets, catches, MVPs, average, strike rate, economy)
- Form strip (5-match directional arrows)
- League rank within current league
- Live match feed (public, no login required)
- All scorecard data
- All organizer features (creating leagues, managing seasons, fixtures, rosters)
- Basic shareable match card (free design)
- Tournament champion badges
- All career milestone badges
- Friendly match scoring (no organizer, no payment)

**The free card is the floor; the Pro card is the ceiling. The gap between them is the product.**

---

### Tournament Activation

**Price: ¥6,000 per tournament, one-time**

Paid by the organizer. Not a subscription. Not recurring. The organizer pays once when they create a tournament. If the tournament is rained out or cancelled, ¥6,000 is refunded if fewer than 2 matches were played; otherwise no refund (same as prize money — it was committed).

**What ¥6,000 unlocks, exactly:**
1. **Official verified results** — green checkmark ✓ badge on every match in the tournament. Signals to viewers that the result is confirmed and uncontested.
2. **"Tournament Champion" badge** — permanent gold trophy icon (🏆) on the winning team's player profiles and shareable cards. Displayed for life, regardless of future Pro status. Free users keep tournament badges permanently.
3. **2× OVR multiplier for match wins** — every winning player in every tournament match receives 2× the OVR impact they would otherwise receive. Losing players receive 1.0×.
4. **Branded PDF scorecard** — auto-generated full tournament scorecard, downloadable as PDF with CrickRise and tournament name branding. Organizers use this in community WhatsApp groups and to award prizes.
5. **Tournament bracket page** — live bracket view (public URL) showing match results, upcoming matches, and winner progression. Shareable link auto-generated at tournament creation.

**Who pays, when:** The organizer pays when they create the tournament. Payment via Stripe (web) or Apple/Google IAP (mobile). The activation is instant — tournament features are live immediately on payment. No approval process, no verification step.

**The pitch to organizers:** "You're running a tournament with ¥25,000 in prize money. ¥6,000 gives your players permanent champion badges, official verified results, and a 2× OVR boost for every win. It costs less than the third-place prize."

**Positioning:** This is the organizer's only monetization touchpoint. Everything else in the organizer experience is permanently free. The ¥6,000 is a voluntary upgrade for moments when the organizer wants to run something that feels official.

---

### Revenue Model Summary

| Stream | Price | Who Pays | When |
|--------|-------|----------|------|
| Individual Pro | ¥1,980/year | Player | After OVR reveal |
| Tournament Activation | ¥6,000 one-time | Organizer | At tournament creation |

No ads. No league subscriptions. No monthly options. No tiers. Two purchase decisions in the entire product.

**Unit economics at scale:**

At 5,000 engaged players (10+ matches), 15% Pro conversion:
- 750 Pro subscribers × ¥1,980 = ¥1,485,000/year (~$9,700)
- 50 tournaments/year × ¥6,000 = ¥300,000/year (~$2,000)
- Total: ~$11,700/year

At 50,000 engaged players globally (localized pricing, blended ¥1,500 ARPU):
- 7,500 Pro × ¥1,500 = ¥11,250,000/year (~$73,500)
- 500 tournaments × ¥6,000 = ¥3,000,000/year (~$19,600)
- Total: ~$93,000/year

At 200,000 engaged players:
- 30,000 Pro × ¥1,500 blended = ¥45,000,000/year (~$295,000)
- 2,000 tournaments × ¥6,000 = ¥12,000,000/year (~$78,500)
- Total: ~$373,500/year — first real hire is justified at this stage.

The price point is not optimized for maximum revenue per user. It is optimized for maximum adoption, which drives the viral loop (more Pro cards shared = more new users = more future Pro subscribers).

---

## 8. THE VIRAL LOOP (STEP BY STEP)

### The Primary Loop

**Step 1: Player scores a friendly match.**
Any two players with the app open the scorer, record a 10-over friendly, confirm the result. Five minutes of setup. One player nominated as scorer before play begins.

**Step 2: Stats compute within 60 minutes.**
OVR updates. Hot Streak updates. Form strip updates. CAPS increments. All players with 6+ deliveries faced or 1+ overs bowled receive updated profiles.

**Step 3: Shareable card is auto-generated.**
Every eligible player receives a push notification: "Your match card is ready. Share it." The card generates on the server, not the device. One tap to share.

**Step 4: Player shares their card to a WhatsApp cricket group.**
This is natural behavior. Nepali cricket communities share match results, photos, and scorecards in their WhatsApp groups routinely. A CrickRise card is more polished than a screenshot and requires less effort to share.

**Step 5: Group members see the card.**
In a group of 50-200 Nepali cricketers, 15-40 people will see the message. Some will open the link. The link goes to the public match scorecard — no login required.

**Step 6: Viewer sees the match scorecard and the player's profile.**
The public match page shows: full scorecard, player profiles with OVR, a live match link if the match is ongoing. At the bottom: "New to CrickRise? Get your own OVR →" and a city-based waitlist input: "Cricket in [City]? Join the waitlist."

**Step 7: The break point — and how to fix it.**
Most viewers stop here because there is no league to join right now in their city. The fix: the waitlist. They enter their phone number and city. They are not asked to download the app, create an account, or find an organizer. They just leave a number.

**Step 8: The waitlist converts.**
If an organizer exists in their city, they receive the lead: "3 players in Osaka are looking for a league." The organizer can invite them directly with one tap. If no organizer exists, the waitlist player receives a message when the first league in their city is created: "A CrickRise league is starting near you. [Join]."

**Step 9: Waitlisted player joins a league.**
Organizer registers them. They play 5 matches. OVR reveals. They get their Pro card. They share it. Loop restarts.

**Step 10: Pro card accelerates the loop.**
A Pro card in a WhatsApp group is visually distinct. Free users who see it ask "how do I get that dark card?" The answer — ¥1,980/year — is accessible enough that the question converts. Each Pro player who shares their card is running a CrickRise advertisement in exactly the communities where the next player will come from.

---

### Where the Loop Breaks and the Fix

| Break point | Why it breaks | Fix |
|-------------|--------------|-----|
| Step 3: Player doesn't share | Forgot, lazy, card not impressive enough | Push notification with pre-populated share button. Card must be visually share-worthy. |
| Step 6: Viewer doesn't click | WhatsApp link preview doesn't look compelling | OG meta tags on match URL must show player OVR and match result — visible in the link preview without clicking. |
| Step 7: No league to join | The classic cold-start problem | Waitlist with city field. Works before any league exists in a city. |
| Step 8: Organizer doesn't follow up on leads | Organizer is busy, forgets | Automated notification to organizer: "3 players in your city are looking for a league." Leads expire after 14 days — creates urgency. |
| Step 9: Player registers but never plays 5 matches | Drops off before OVR unlock | Reminder at 3 matches: "2 more matches until your OVR unlocks." Reminder at 4 matches: "1 more match." |
| Step 10: Free user doesn't upgrade after seeing Pro card | ¥1,980 feels like a decision | Make the 7-day free trial the default path. "Try Pro free for 7 days" is easier than "pay ¥1,980." Trial converts when the player sees their Pro card and shares it during the trial. |

---

### The OVR Reveal as a Separate Viral Event

The OVR reveal is a one-time event that triggers its own viral moment:

1. Player opens app after their 5th match
2. Full-screen animated reveal: black background, jersey number fades in, player name appears, OVR counter animates from 50 to actual number (1.5 seconds), number pulses, BAT/BOWL/FIELD appear below
3. Screen 2: "Your cricket career has officially started." + pre-generated OVR Reveal Card (different from the match card — features the OVR large, CAPS count, "Match 5 of ∞")
4. One-tap share to WhatsApp/LINE
5. Immediate Pro upsell: "Your card with Pro" — side-by-side comparison of free card vs Pro card

The OVR reveal card reads, when shared: "OVR 74 — Roshan KC, Okinawa Warriors. My cricket career starts here. crickrise.com"

This message, in a Nepali cricket WhatsApp group, generates 20-40 views and 5-15 responses. It is the most organic advertisement the product will ever produce.

---

## 9. EXACT V1 BUILD LIST

### V1.0 — Ships First (Developer-Ready)

**Data Models (PostgreSQL schema)**

```sql
-- Core entities
Player (id UUID PK, name TEXT, phone TEXT UNIQUE, city TEXT, created_at TIMESTAMP)
League (id UUID PK, name TEXT, logo_url TEXT, format ENUM(T20,ODI,CUSTOM), overs INT, city TEXT, organizer_id → Player)
Season (id UUID PK, league_id → League, name TEXT, start_date DATE, end_date DATE, status ENUM(DRAFT,ACTIVE,COMPLETED))
Team (id UUID PK, season_id → Season, name TEXT, logo_url TEXT)
TeamMembership (id UUID PK, player_id → Player, team_id → Team, jersey_number INT, role ENUM(PB,PBOW,BAR,BOAR,WKB), active_from DATE, active_until DATE)
Match (id UUID PK, season_id → Season, match_type ENUM(FRIENDLY,LEAGUE,TOURNAMENT), team_a_id → Team, team_b_id → Team, scheduled_at TIMESTAMP, venue TEXT, scorer_id → Player, status ENUM(UPCOMING,LIVE,PENDING_CONFIRMATION,CONFIRMED), toss_winner_id → Team, toss_decision ENUM(BAT,FIELD), tournament_round ENUM(GROUP,QF,SF,FINAL) NULLABLE)
Tournament (id UUID PK, league_id → League, name TEXT, activated BOOLEAN DEFAULT FALSE, activation_paid_at TIMESTAMP)
Innings (id UUID PK, match_id → Match, innings_number INT, batting_team_id → Team)
Delivery (id UUID PK, innings_id → Innings, over_number INT, ball_number INT, batsman_id → Player, non_striker_id → Player, bowler_id → Player, runs_off_bat INT, extra_type ENUM(NONE,WIDE,NO_BALL,BYE,LEG_BYE), extra_runs INT DEFAULT 0, wicket_type ENUM(NONE,BOWLED,CAUGHT,LBW,RUN_OUT,STUMPED,HIT_WICKET,RETIRED,OTHER), dismissed_player_id → Player NULLABLE, fielder_id → Player NULLABLE, is_admin_correction BOOLEAN DEFAULT FALSE, original_delivery_id → Delivery NULLABLE, self_scored BOOLEAN DEFAULT FALSE, synced_at TIMESTAMP, device_created_at TIMESTAMP)
PlayerRating (id UUID PK, player_id → Player, computed_after_match_id → Match, ovr DECIMAL(4,1), bat DECIMAL(4,1), bowl DECIMAL(4,1), field DECIMAL(4,1), hot_streak INT, caps INT, match_weight DECIMAL(3,2), computed_at TIMESTAMP)
MatchAward (id UUID PK, match_id → Match, player_id → Player, award_type ENUM(MVP))
Waitlist (id UUID PK, phone TEXT, city TEXT, created_at TIMESTAMP, referred_by_match_id → Match NULLABLE)
```

**Screens to Build — Scorer App (React Native)**

1. **Scorer Home** — list of assigned matches (league) or "Start Friendly" button
2. **Match Type Selection** — Friendly vs League (league is only shown if scorer has an assigned match)
3. **Friendly Setup: Format** — T20 / 10-over / 5-over / Custom
4. **Friendly Setup: Team Names** (optional, skippable)
5. **Pre-Match: Toss** — two buttons (team names), two buttons (bat/field), confirm
6. **Pre-Match: Playing XI** — checklist with jersey number rows, 80px touch targets
7. **Pre-Match: Batting Order** — drag-to-reorder for top 4
8. **Active Scoring Screen** — Zone A (match state) / Zone B (primary actions) / Zone C (secondary)
9. **Wicket Modal** — dismissal type, fielder picker, next batter auto-suggested
10. **Bowling Change Modal** — fielding team shown by jersey number
11. **Undo Confirmation** — shows exactly what will be undone
12. **[··· MORE] Menu** — fix batter, fix bowler, retired hurt, powerplay, super over, note
13. **Innings Transition** — result summary, target, proceed button
14. **Post-Match Confirmation** — result + suggested MVP, confirm or edit
15. **Offline Banner** — persistent status bar indicator (🔴/🟡/✅)

**Screens to Build — Player App (React Native)**

1. **Onboarding** — phone number entry → OTP → name → city → done (4 screens)
2. **Home Screen / My Position** — three-row position view (rival above, self, rival below), form strip, next match countdown, [SCORE A FRIENDLY] button
3. **My Profile** — full profile layout (see Section 5)
4. **OVR Reveal** — full-screen animated reveal (triggered once, on first OVR unlock after 5th match)
5. **Share Card Preview** — free card shown, Pro card shown as mockup, share buttons
6. **Pro Upsell** — shown after OVR reveal and when tapping blurred OVR trend graph
7. **League/Season View** — standings table, fixture list, leaderboard (tabs: OVR / BAT / BOWL / CAPS)
8. **Match Detail** — scorecard, ball-by-ball log (public, no login required)
9. **Other Player Profile** — same layout as My Profile, Follow button, no OVR breakdown
10. **Live Match Center** — Zone A match state, scorecard tab, ball-by-ball tab, share link, waitlist CTA (public URL, no login)
11. **Notifications List** — log of past notifications with tap-to-navigate
12. **Settings** — name, city, role, notifications toggle, subscription status, sign out

**Screens to Build — Organizer Web/Mobile**

1. **Create League** — name, logo, format, city
2. **Create Season** — season name, dates
3. **Add Teams** — team name, logo (up to 16 teams)
4. **Register Players** — name + jersey number per team, CSV bulk import, phone link to existing account
5. **Assign Co-Organizer** — phone/email entry, invite sent
6. **Create Fixture** — date, time, venue, home team, away team, scorer (optional at creation)
7. **Publish Season** — pre-publish checklist (2+ teams, 1+ fixture, co-organizer assigned)
8. **Organizer Dashboard** — standings, upcoming fixtures, pending confirmations, player correction queue
9. **Correction Mode** — match list → innings → ball-by-ball log → tap delivery to edit
10. **Tournament Creation** — name, format (bracket or round-robin), activate (¥6,000 payment)
11. **Tournament Bracket** — match results and upcoming matches

**OVR Computation (Background Job, runs on match confirmation)**

Trigger: organizer confirms match result (or friendly auto-confirms).

```python
# Pseudocode — implement as a queued background job (e.g., Bull + Redis)

def compute_player_rating(player_id, after_match_id):
    deliveries = fetch_all_deliveries_for_player(player_id)
    # Separate by match_weight:
    # match.type == FRIENDLY: weight_multiplier = 0.5
    # match.type == LEAGUE: weight_multiplier = 1.0
    # match.type == TOURNAMENT and match result == WIN for player's team: weight_multiplier = 2.0
    # match.type == TOURNAMENT, FINAL, WIN: weight_multiplier = 1.3 (separate from tournament win 2x — see Note)
    # Note: Tournament Final Win = base 1.0 × tournament activation 2.0 × final boost 1.3 = 2.6× effective
    # self_scored deliveries: × 0.7 on top of above

    # Recency windows:
    # last 5 matches: 40% weight
    # matches 6–15: 35% weight
    # career beyond: 25% weight

    bat = compute_bat_rating(deliveries, role)  # see domain formula below
    bowl = compute_bowl_rating(deliveries, role)
    field = compute_field_rating(deliveries, role)
    ovr = compute_ovr(bat, bowl, field, role)

    # Bayesian shrinkage by match count
    caps = count_verified_matches(player_id)
    ovr = apply_shrinkage(ovr, caps)
    # 0-4 matches: OVR not computed (None)
    # 5-9: clamp to [42, 68]
    # 10-19: clamp to [36, 80]
    # 20+: clamp to [30, 95]

    hot_streak = compute_hot_streak(player_id)
    store(PlayerRating, player_id, ovr, bat, bowl, field, hot_streak, caps, after_match_id)
    trigger_notifications(player_id, old_rating, new_rating)
```

**BAT Rating Formula:**
```
batting_average = runs_scored / max(dismissals, 1)   # no inf on not outs
strike_rate_relative = (strike_rate / format_benchmark_sr) * 50  # normalized to 50
consistency = pct_innings_with_15plus_runs * 99
big_innings_rate = (fifties + hundreds * 2) / max(innings, 1) * 10

BAT_raw = batting_average * 0.35 + strike_rate_relative * 0.25 + consistency * 0.20 + big_innings_rate * 0.15 + recent_form_bat * 0.05
BAT = normalize(BAT_raw, 1, 99)

# Format benchmarks:
# T20: SR benchmark = 120
# 10-over: SR benchmark = 130
# 5-over: SR benchmark = 150
# ODI/40+ overs: SR benchmark = 80
```

**BOWL Rating Formula:**
```
bowling_average = runs_conceded / max(wickets, 0.5)  # floor at 0.5 to avoid inf
economy_relative = (format_benchmark_econ / economy_rate) * 50  # normalized to 50, lower econ = higher score
bowling_sr = balls_bowled / max(wickets, 0.5)
wicket_rate = wickets / max(matches_bowled, 1)

BOWL_raw = bowling_average_score * 0.30 + economy_relative * 0.25 + bowling_sr_score * 0.25 + wicket_rate_score * 0.15 + death_bowling_bonus * 0.05
BOWL = normalize(BOWL_raw, 1, 99)

# Economy benchmarks:
# T20: 8.0 runs/over
# 10-over: 9.0 runs/over
# 5-over: 10.0 runs/over
```

**FIELD Rating Formula:**
```
catches_per_match = total_catches / max(matches_fielded, 1)
run_out_contributions = (direct_hits + (assists * 0.5)) / max(matches_fielded, 1)
stumpings_per_match = stumpings / max(matches_fielded, 1)  # WKB only

FIELD_raw = catches_per_match * 40 + run_out_contributions * 35 + stumpings_per_match * 25  # WKB
FIELD_raw = catches_per_match * 60 + run_out_contributions * 40  # non-WKB
FIELD = normalize(FIELD_raw, 1, 99)
# FIELD marked "estimated" in UI until 10+ matches
# FIELD influence on OVR reduced by 30% for players with <10 matches
```

**OVR by Role:**
```
Pure Batter:          OVR = BAT*0.75 + FIELD*0.20 + BOWL*0.05
Pure Bowler:          OVR = BOWL*0.75 + FIELD*0.20 + BAT*0.05
Batting All-rounder:  OVR = BAT*0.55 + BOWL*0.30 + FIELD*0.15
Bowling All-rounder:  OVR = BOWL*0.55 + BAT*0.30 + FIELD*0.15
Wicketkeeper-Batter:  OVR = BAT*0.50 + FIELD*0.35 + BOWL*0.15
```

**Hot Streak Computation:**
```python
def compute_hot_streak(player_id):
    matches = fetch_matches_for_player(player_id, ordered_by='date DESC')
    career_avg = compute_career_batting_average(player_id)
    career_econ = compute_career_economy(player_id)
    role = get_player_role(player_id)

    streak = 0
    for match in matches:
        above_average = False
        if role in (PB, BAR, WKB):
            if match.runs_scored >= career_avg and match.balls_faced >= 6:
                above_average = True
        if role in (PBOW, BOAR):
            if (match.economy <= career_econ or match.wickets >= 1) and match.overs_bowled >= 1:
                above_average = True
        if role in (BAR, BOAR):  # all-rounders: either criterion
            if batting_above or bowling_above:
                above_average = True

        if above_average:
            streak += 1
        else:
            break  # streak is over

    return streak
```

**Notification Triggers (post-OVR computation):**
- OVR changed by 1+ points: send
- Rank changed by 1+ positions within ±5 of current rank: send
- Hot Streak extended to 3, 5, 7, 10: send
- Hot Streak reset from 3+: send
- MVP awarded: send
- Match milestone within 30 runs or 5 wickets: send
- Upcoming match 2 hours away: send

**Server-Side Card Generation:**
- Library: `@napi-rs/canvas` (Node.js) or Puppeteer with HTML template
- Resolution: 1080×1080px, exported as JPEG at 85% quality
- Free card: white background, system font (San Francisco / Roboto), CrickRise teal (#00B4CC) header strip
- Pro card: `#0A0F1E` to `#1A2744` linear gradient background, gold accent (#F5C842) for OVR number, teal (#00B4CC) for domain scores and rank, white for names
- Generated on match confirmation, cached at CDN with match ID as cache key
- URL format: `cdn.crickrise.com/cards/{match_id}/{player_id}.jpg`

**Anti-Gaming Enforcement (ingestion-time):**
1. Batter faces < 6 deliveries → batting stats marked `ovr_ineligible: true`
2. Bowler bowls < 1 complete over → bowling stats marked `ovr_ineligible: true`
3. Scorer is player in their own match → all their deliveries marked `self_scored: true`, weighted at 0.7×
4. Impossible stats check: batter > 200 runs in T20, bowler > 10 wickets in match → match status set to `PENDING_VERIFICATION`, OVR excluded until organizer manually confirms
5. Friendly marker: `match.match_type == FRIENDLY` → `weight_multiplier = 0.5` applied to all OVR calculations from this match

---

### V1.5 — Ships Within 60 Days of V1.0 Launch

**Items that do NOT ship in V1.0 but are built immediately after:**

1. **Push notifications infrastructure** — Firebase Cloud Messaging, notification preference settings, all triggers from Section 2
2. **Pro subscription payment** — Stripe (web) and Apple/Google IAP (mobile), payment status stored in `Subscription` table (player_id, status, expires_at, provider, provider_subscription_id)
3. **Pro card generation** — dark gradient version of the card, triggered when player has active Pro subscription
4. **OVR breakdown text** — plain-English generator: compare each domain's top input against a league percentile, produce one sentence per domain ("Your batting average is top 20% in your league, but your strike rate is below the league median — bat faster.")
5. **OVR trend graph** — match-by-match PlayerRating history, rendered as SVG line chart, shown on Pro profile
6. **Nepali language support** — all UI strings extracted to i18n keys, Nepali (Devanagari) translations added
7. **Waitlist backend** — city + phone collection, organizer notification with nearby waitlist count, automated player notification when a league starts in their city
8. **Tournament activation payment** — Stripe Checkout for ¥6,000, tournament activated on webhook receipt

---

### V2 — Not in First 60 Days

Cross-league rankings (regional, country-wide), team OVR (aggregate of squad), team profile page with season history, season summary "Your Cricket Year" annual card, advanced OVR trend analytics for Pro users, web admin dashboard with aggregate league analytics, head-to-head stats between specific players, umpire management, player search/scouting by OVR and role.

**Never:** AI commentary, live streaming, merchandise store, fantasy cricket, coaching plans, academy management, rivalries feature (needs multi-season history), Player of the Week (politically toxic in small communities), social feed.

---

## 10. THE ONE THING

**The two-point gap.**

Not the OVR reveal. The reveal is a one-time moment. You cannot be surprised by your own number twice. The product cannot sustain itself on first impressions.

The one thing CrickRise is remembered for — the one UX moment, the one emotional experience, the one product decision that everything else serves — is the feeling of knowing that Bikash is two OVR points ahead of you, that you play in the same league, that you've faced each other, and that the gap is specific and visible and **reachable**.

That feeling does not require a full leaderboard. It does not require regional rankings. It does not require advanced analytics. It requires three rows on a home screen, a number, and a name.

The scorer UX exists to produce accurate data. Accurate data makes the OVR trustworthy. A trustworthy OVR makes the gap real. A real gap makes the rivalry personal. A personal rivalry makes a player open the app before and after every match, share their card when the gap closes, and pay ¥1,980 because they need to understand what is holding their OVR below Bikash's.

Every feature decision must answer one question: **Does this make the two-point gap more real, more personal, and more urgent?**

If yes, build it. If no, cut it.

Build everything around the moment a Nepali cricketer in Okinawa opens the app after a match, sees the gap to Bikash has closed from 4 to 2, and feels the particular electric feeling of a rivalry on the edge of resolution. That feeling is the product. Everything else is infrastructure.

---

*Document produced: August 2026*
*Authors: CrickRise Founding Product Team — Definitive Synthesis*
*Status: Final. This document supersedes CRICKRISE_PRODUCT_STRATEGY.md and CRICKRISE_FINAL_REDESIGN.md for all feature and design decisions. Refer to this document and this document only when making build decisions.*
