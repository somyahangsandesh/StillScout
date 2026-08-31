# CRICKRISE — COMPLETE PRODUCT STRATEGY
### Independent Founding Team Analysis | August 2026

> *This document treats CrickRise as if real money and two years of development are on the line. It challenges the original brief, removes weak ideas, strengthens good ones, and produces the most realistic path to a successful product.*

---

## TABLE OF CONTENTS

1. [Executive Verdict](#1-executive-verdict)
2. [Market Research](#2-market-research)
3. [Competitive Landscape](#3-competitive-landscape)
4. [What Is Wrong With The Original Idea](#4-what-is-wrong-with-the-original-idea)
5. [The Redesigned CrickRise Concept](#5-the-redesigned-crickrise-concept)
6. [Core User Loop](#6-core-user-loop)
7. [Organizer Experience](#7-organizer-experience)
8. [Team Experience](#8-team-experience)
9. [Player Experience](#9-player-experience)
10. [Scorer Experience](#10-scorer-experience)
11. [Live Match Experience](#11-live-match-experience)
12. [OVR / Rating System](#12-ovr--rating-system)
13. [Rankings](#13-rankings)
14. [Player Retention](#14-player-retention)
15. [Viral Loop](#15-viral-loop)
16. [Monetization](#16-monetization)
17. [Pricing](#17-pricing)
18. [Unit Economics](#18-unit-economics)
19. [V1 — What To Build](#19-v1--what-to-build)
20. [Future Roadmap](#20-future-roadmap)
21. [Technical Architecture Considerations](#21-technical-architecture-considerations)
22. [Growth Strategy](#22-growth-strategy)
23. [Long-Term Moat](#23-long-term-moat)
24. [Biggest Risks](#24-biggest-risks)
25. [Final Product Positioning](#25-final-product-positioning)
26. [Final Name / Tagline Recommendations](#26-final-name--tagline-recommendations)
27. [What I Would Build If I Were The Founder](#27-what-i-would-build-if-i-were-the-founder)

---

## 1. EXECUTIVE VERDICT

**The concept has a genuine core.** The OVR system applied to amateur cricket players is the most differentiated idea in this space. No competitor does it properly. It has the potential to create a fundamentally different emotional relationship between a player and an app — the same feeling FIFA cards give football fans, applied to real people playing real matches in real communities.

**But the original brief makes three strategic mistakes that will kill the product before it proves itself:**

**Mistake 1 — Japan as the market, not as the lab.**
Japan has approximately 5,000 regular adult cricket players according to the Japan Cricket Association. Okinawa has significantly fewer — probably 150-400 active players across all clubs. You cannot build a business off 400 players. Japan should be the pilot environment for learning, not the primary market. The primary market is the global Nepali cricket diaspora — an estimated 3.5 million Nepali migrants abroad who brought cricket with them and are deeply underserved by Indian-centric apps.

**Mistake 2 — The monetization trigger is too late.**
The brief imagines a long path from free player to paying subscriber. But the OVR reveal moment — the instant a player sees their first OVR after five matches — is the single highest-intent moment in the entire product. That is when you introduce payment. Build toward that moment from day one.

**Mistake 3 — Over-indexing on feature breadth, under-indexing on data quality.**
A cricket app where the scorer makes errors is a cricket app nobody trusts. The OVR system only works if the underlying data is clean. Scorer UX quality is not a secondary concern — it is the foundation everything else rests on. The brief lists 27 scorer considerations as a list, which suggests they are all equal. They are not. Getting the basic ball entry right under real outdoor conditions is the only thing that matters in V1.

**The verdict:** Build this. The core idea is defensible. CricHeroes has 49 million users and is actively making their user base angry by locking personal stats behind a paywall. The market gap is real. Execute narrowly and precisely — Nepali cricket communities, Japan as the beachhead, diaspora as the expansion. The OVR system is the product's soul. Protect it. Everything else is supporting infrastructure.

---

## 2. MARKET RESEARCH

### Japan Cricket

**Hard numbers:**
- 5,000+ regular adult players (JCA, 2025)
- ~15,000 people who have tried cricket in some form
- 40+ member clubs in the JCA
- Fastest growth segment: Nepali and South Asian migrant community
- The 2026 Asian Games in Nagoya gave the sport national visibility
- The 2028 Los Angeles Olympics (cricket returning for first time since 1900) will help globally

**Nepali cricket in Japan specifically:**
- Multiple Nepali clubs in Tokyo, Sano, Osaka, Fukuoka
- Okinawa has active Nepali worker community with informal cricket groups
- The Seven Samurai United Premier League (March 2025) featured 8 Nepali clubs competing in Shizuoka — a formal, organized, self-funded tournament
- Prize money offered (¥25,000 for first place) shows the community is organized enough to fund themselves

**Assessment:** Japan is viable as a controlled test market because the communities are small enough to know personally and motivated enough to organize their own leagues. But you cannot stay Japan-only.

### Global Nepali Cricket Diaspora

- Nepal has 30 million people; cricket is the #2 sport behind football
- ~3.5 million Nepali workers abroad, predominantly young men of playing age
- Major communities: Qatar (500,000+), UAE (400,000+), Malaysia (400,000+), Japan (120,000+), South Korea (50,000+), UK (50,000+), USA (30,000+)
- These communities form cricket clubs everywhere they settle
- They use WhatsApp and Facebook to organize — there is no digital infrastructure for them
- CricHeroes is India-first in UX, Hindi-heavy in community features, and unfamiliar to Nepali users
- Nepal Cricket Board has no grassroots digital platform for diaspora communities

**Assessment:** The Nepali cricket diaspora is an underserved, cricket-obsessed, digitally active, growing market with no dedicated platform. This is the real addressable market. Japan is the beachhead. Nepal + diaspora is the business.

### Amateur Sports App Market

- The global sports app market is growing toward $13 billion by 2034
- Freemium is the dominant model — free features attract users, premium converts the engaged ones
- Annual subscriptions outperform monthly in the sports/fitness category — they generate 67% of subscription revenue
- Users will pay for advanced analytics and personalized performance data; they will not pay for basic access to their own information
- Conversion rate from free to paid in sports apps: 5-15% of active users, heavily dependent on perceived value
- CricHeroes has publicly stated they have 49 million users — of those, only a small fraction pay for Pro, suggesting the cricket market is not inherently subscription-resistant, but the wrong gate will kill conversion

---

## 3. COMPETITIVE LANDSCAPE

### CricHeroes — The 800-Pound Gorilla

**What they have:**
- 49 million users, 12 million matches scored
- Free league management and scoring
- Player profiles with career statistics
- Leaderboards
- PRO subscription (analytics, ad-free, themes)
- Merchandise store
- 50+ country cricket associations using the platform

**What they charge:**
- Basic: Free
- PRO Annum: ~₹499/year (India), varies internationally
- PRO Infinity: Higher tier with merchandise and live streams
- Sponsor logos: ₹299 per logo (separate from Pro — users are furious about this)

**Their actual weaknesses (from real user complaints):**

1. **They locked personal stats behind a paywall.** Players can no longer see their own batting average and bowling figures without paying. This is causing genuine user revolt. Posts on LinkedIn from active players calling it "ridiculous" and threatening to leave. This is CrickRise's single biggest opening.

2. **Intrusive advertising on the free tier.** "The app is almost unusable without a subscription" is a verbatim complaint. A clean, ad-free experience for free users would immediately feel premium by comparison.

3. **Customer support is non-functional at scale.** Multiple verified complaints of paid subscriptions not activating, no responses on WhatsApp, merchandise not delivered after 6 months. A small startup that actually responds to users has a meaningful advantage.

4. **Score correction is inadequate.** Scorers make mistakes. The correction process is painful. One user describes a scenario where one incorrect run entry caused their entire innings to be attributed to the wrong batter. This is a data integrity failure that destroys the OVR system trust if replicated.

5. **Fake match reporting.** Matches with impossible scores (teams winning by 15 wickets) go undetected. CricHeroes tells users to "sort it out with the organizer." For a platform whose value is verified statistics, this is catastrophic.

6. **No OVR / role-based rating.** They have leaderboards and stats but no holistic player rating. This is the gap CrickRise must occupy.

**Their strengths you cannot beat:**
- Scale: 49 million users creates a global community feel
- India market dominance
- Infrastructure: They handle 16,000+ matches per hour
- Trust: Known brand in cricket

**CrickRise's opening:** Win the communities CricHeroes ignores. Nepali diaspora, Japan, and other non-Indian cricket communities feel like second-class users on CricHeroes. Build the platform that feels like it was built for them.

### CricClubs

**What they have:**
- League management platform (more B2B than consumer)
- 30,000+ leagues in 58+ countries
- Pricing tiers from free to enterprise (~$3-$250/year for leagues)
- Pay-per-match live streaming
- Used by 35+ national governing bodies

**Their weakness:** Organizer-focused, not player-focused. No player career system. Feels like software, not a sports product. No OVR or player ratings. Players are second-class citizens.

**Assessment:** CricClubs is a direct competitor for organizers, not for players. This is actually fine — CrickRise should let organizers compare both and choose. The players will choose based on player experience, not organizer features. If your scorer is easier to use and your player profiles are richer, organizers will adopt CrickRise because their players demand it.

### Other Competitors

- **ESPNcricinfo / Cricbuzz:** Professional cricket coverage, no amateur league tools
- **PlayHQ (Australia):** Strong community sports registration, not cricket-specific scoring
- **Scorecard Cricket:** Basic scoring, no player profiles
- **Japan Cricket Association (CricClubs-powered):** Exists but serves formal JCA leagues, not informal Nepali community groups

**The gap:** No platform is building a player-identity and rating product for the grassroots player. Everyone is building tools for organizers. CrickRise is the first player-first platform.

---

## 4. WHAT IS WRONG WITH THE ORIGINAL IDEA

### Problems to Fix

**1. Japan-first positioning is a strategic trap.**
Starting in Okinawa is tactically correct for learning but strategically incorrect as the primary market claim. Commit to Nepali cricket diaspora as the primary market, with Japan as the initial geographic focus. This changes your messaging, your language support decisions, your community partnerships, and your fundraising story.

**2. The organizer free model needs one important caveat.**
Keeping the organizer experience free is correct — but the brief says "analyze whether some organizer features should eventually be monetized." The answer is yes, one specific thing: organizer verification badges for league results. If you ever build a pathway from grassroots stats to national team consideration, then "verified league" certification creates a tier. But this is version 3, not version 1. For V1 and V2: organizers are free, permanently.

**3. The feature list is far too long for V1.**
Team rivalries, head-to-head, regional rankings, Player of the Week, sponsorships, achievements system, commentary, multiple ranking categories — these are all interesting but most of them are distractions in V1. A focused V1 with one thing done brilliantly (scorer + OVR reveal) will outperform a comprehensive V1 with ten things done adequately.

**4. The OVR system as described is underspecified and potentially gameable.**
"Football-style ratings" is a direction, not a design. Without a proper methodology, the OVR will be (a) gamed immediately by friendly matches with weak teams, (b) distorted by small samples, and (c) distrusted by competitive players who disagree with their number. The rating system needs rigorous design before a single line of code is written. See Section 12.

**5. "Rise Through the Ranks" is a generic tagline.**
Every competitive game uses ascent metaphors. It says nothing specific about what CrickRise uniquely offers. The positioning "Your Cricket Career" is stronger — it captures permanence, identity, and portability. Build the tagline off that.

**6. The monetization gating is wrong.**
The brief considers gating full career history, advanced stats, and rankings behind Pro. This is the exact mistake CricHeroes made. Players will accept paying for *depth* but revolt against paying for *access to their own data*. Redesign the paywall to gate things that extend the experience (shareable cards, detailed trend analysis, cross-league rankings) not things that restrict basic participation.

**7. Social features are listed as potential, not as core architecture.**
The viral sharing mechanism must be designed into the product from day one, not added as a feature later. The shareable OVR card — a single image a player can send on WhatsApp or LINE — is a growth mechanism, not a social feature. It needs to be pixel-perfect, fast to generate, and automatic.

### What Is Genuinely Brilliant and Should Stay

1. **The OVR concept applied to real amateur players.** Brilliant. Keep it and protect it.
2. **Organizer as distribution, player as customer.** This is a correct business model insight.
3. **Player career portability across teams and leagues.** This is the long-term moat.
4. **Jersey-number-first scorer UX.** Simple insight, huge practical value. Keep it.
5. **Starting with one community before scaling.** Correct startup discipline.
6. **Offline-first scoring.** This is non-negotiable given the environments involved.
7. **Post-match automatic record generation.** The moment a match ends and stats update instantly is a product magic moment. Build toward it.

---

## 5. THE REDESIGNED CRICKRISE CONCEPT

### The Single Sentence Product Description

CrickRise is the player identity platform for amateur cricket — it gives every grassroots player a verified, portable career profile, a dynamic OVR rating, and a competitive ranking that grows with them across every league they ever play in.

### The Three Pillars

**PILLAR 1: THE LEAGUE CREATES THE DATA.**
An organizer sets up a league in minutes. A scorer enters every ball. The platform captures everything — every run, every wicket, every catch — as immutable, verified match data. This data belongs to the players, not the league.

**PILLAR 2: THE MATCH CREATES THE MOMENT.**
The live scoring feed, the OVR update after a big innings, the MVP announcement, the shareable scorecard card — these are designed to be emotionally resonant for players and their communities.

**PILLAR 3: THE CAREER CREATES THE LOCK-IN.**
After two seasons of verified matches, a player has a cricket record they cannot replicate elsewhere. Their OVR history, their career averages, their MVP trophies — this data stays with them forever. Moving to a competitor means starting from zero.

### Target User Definition

**Primary:** Nepali male cricketers aged 18-40 living outside Nepal, particularly in Japan, Qatar, UAE, Malaysia, and South Korea. Cricket-passionate, socially active (WhatsApp, Facebook, TikTok), competitive about their game, aspiring to have their career documented.

**Secondary:** Any South Asian or cricket-playing community without a digital platform for their informal leagues (South Asian communities in Japan, Bangladesh/Pakistan communities in various countries).

**Not the primary target for V1:** Japanese-born cricketers, professional or semi-professional players, cricket academies.

---

## 6. CORE USER LOOP

### The Flywheel

```
ORGANIZER creates league + invites players via WhatsApp link
         ↓
PLAYERS join, create profiles, register for their team
         ↓
SCORER enters match ball-by-ball on matchday (offline-capable)
         ↓
MATCH CENTER goes live — players and spectators follow on phones
         ↓
MATCH ENDS — scorecard auto-generates, MVP auto-awards
         ↓
STATS UPDATE — every player's OVR recalculates
         ↓
OVR REVEAL (if first time hitting threshold) — shareable card unlocks
         ↓
PLAYER SHARES CARD on WhatsApp/LINE/Instagram
         ↓
Friends and community members see card, tap link
         ↓
They see the match center and player profiles
         ↓
Some ask organizer: "How do I join next season?"
         ↓
New players → new teams → new organizers → new leagues
```

### Is This a Network Effect or a Growth Loop?

Honest answer: it is primarily a growth loop with data network effects emerging at scale. A pure marketplace network effect (every new user makes the product more valuable for all existing users) does not exist here. But two weaker network effects do:

- **Same-community effect:** More players in your league → more competitive rankings → OVR comparisons are more meaningful → more engagement.
- **Data calibration effect:** More matches across more leagues → better baseline for OVR computation → more trustworthy ratings everywhere.

The true moat is not a network effect — it is **data lock-in**. A player with 50 verified matches on CrickRise has a career record that cannot be transferred to a competitor. That is the defensibility. Network effects come later, if CrickRise becomes the universal cricket ID.

---

## 7. ORGANIZER EXPERIENCE

### Who Is the Organizer?

Typically: one person in the community who loves cricket and is willing to do the administrative work. Often the team captain or a community leader. Not a professional event manager. Usually managing this alongside a day job.

**This person's actual pain today:**
- WhatsApp groups for scheduling (chaotic)
- Paper scorecards or basic Google Sheets for stats
- Arguments over who is the best batter this season
- No way to show the outside world what their league is doing
- Starting from scratch every season

**What CrickRise gives the organizer:**
- A permanent digital home for their league
- Professional-looking fixtures and results
- Automated standings
- A reason for every player in the league to install the app
- Something they can share in the community with pride

### Organizer Feature Set

**Free forever:**
- Create league with name, logo, format (T20, ODI, custom overs)
- Create season
- Add teams (up to limit, generous limit in V1)
- Register players to teams with jersey numbers (bulk or individual)
- Create fixtures with date, time, venue
- Assign official scorer per match
- Publish results
- Standings auto-calculated
- End-of-season awards (MVP, Most Runs, Most Wickets — organizer selects from auto-generated suggestions)
- Correction tools: edit match results, reassign scoring errors, remove duplicate players

**Design principles for organizer:**
- Setup should take under 10 minutes for a 6-team league
- Mobile-first but web admin panel for desktop use when available
- Multilingual from day one: English and Nepali (Roman/Devanagari). Japanese eventually.
- Every action reversible — organizers will make mistakes, judgment-free correction is table stakes

**Why organizers will want every player on CrickRise:**
Because their players will ask them "how do I see my OVR?" And the organizer cannot answer that unless all the matches are scored on CrickRise. The organizer's incentive to maintain data quality is social — their community is watching.

**What organizers will hate if you get it wrong:**
- A setup process that requires technical knowledge
- Fixtures that cannot be rescheduled
- No way to handle late additions to the squad
- Being blamed when a player's stats are wrong because the scorer made a mistake and could not correct it
- Any hidden features that suddenly require payment mid-season

---

## 8. TEAM EXPERIENCE

A team profile should feel like a club's digital home, not a database record.

### Team Profile — Recommended Contents

**Essential:**
- Team name and logo
- Current season roster with jersey numbers and positions
- Current season results (W/L/D, run rate)
- Current standings position
- Season batting and bowling leaders
- Upcoming fixtures

**Important but not V1:**
- Team OVR (aggregate of squad OVRs — fun but needs enough player data)
- Season history (past championships, records)
- Head-to-head vs specific opponents

**Remove from the original list:**
- "Rivalries" — you cannot have rivalries until you have multi-season history and data to show meaningful patterns. Fake rivalries are worse than no rivalries.
- "Championships" in V1 — you need at least one completed season first

### Team OVR

Define Team OVR as the average OVR of the playing XI (players who appeared in more than half the matches). This is simple, defensible, and creates inter-team competition automatically. Show it publicly after Season 1 is complete.

---

## 9. PLAYER EXPERIENCE

### The Player Profile — Final Design

```
┌─────────────────────────────────────────────────────┐
│  #7  ROSHAN KC                                       │
│  Okinawa Warriors · Batting All-rounder             │
│                                                      │
│  ┌─────┐                                            │
│  │ OVR │   BAT   BOWL   FIELD                       │
│  │  86 │    89     78      84                       │
│  └─────┘                                            │
│                                                      │
│  FORM  ↑↑→↑↓  (last 5 match indicators)           │
│                                                      │
│  2026 SEASON                                         │
│  14 matches · 487 runs · 21 wkts · 13 catches      │
│  Avg 38.4 · SR 142 · Econ 6.8 · 3 MVP             │
│                                                      │
│  League Rank #4   Japan Rank #38                    │
│                                                      │
│  CAREER HIGHLIGHTS                                   │
│  3 seasons · 1,240 runs · 58 wickets · 9 MVP       │
│  Peak OVR 88 (2025 Season)                         │
└─────────────────────────────────────────────────────┘
```

**Design principles:**

1. **The OVR number is the hero.** It should be the largest, most visually prominent element on the profile. Everything else supports it.
2. **Form is contextual, not permanent.** Show a 5-match form strip (arrows: up/down/flat) that changes constantly. This creates return visits.
3. **Two career tiers:** Current season (always visible, free) and career total (depth, part of Pro experience).
4. **Rankings are motivating only if they're close.** Show "#4 in your league" not just "#38 in Japan" — the local comparison is more motivating for most players.

### The Player Identity Principle

The player's CrickRise profile belongs to them, not to a league. When a player moves from Okinawa Warriors to a Tokyo team, their full verified history travels with them. The new team sees: "Roshan KC — 86 OVR, 1,240 career runs, ex-Okinawa Warriors." This is the single most important architectural decision in the entire product. Get this right in the data model even if the UI for it is simple in V1.

### What Players Will Love
- Seeing their OVR for the first time
- Their OVR going up after a good innings
- Ranking higher than a friend
- The shareable match card after an MVP performance
- Seeing their career stats grow season over season

### What Players Will Ignore
- Deep statistical sub-categories they don't understand
- Complex comparative analytics in V1
- Commentary features
- Team history before their time

### What Players Will Pay For
- OVR breakdown (which attributes are holding them back)
- Cross-league rankings (am I better than players in Tokyo?)
- Career history visualization (their journey across seasons)
- Premium shareable card design (the "flex" card)
- Ad-free experience

### What Players Will Not Pay For
- Access to their own basic statistics — this must always be free
- Content they don't understand
- Features that feel like they should have been free

---

## 10. SCORER EXPERIENCE

The scorer experience is the most technically and UX-critical part of the product. If scoring is unreliable, every player OVR becomes suspect and the product fails. No feature is more important than this.

### The Scorer Reality

The scorer is standing outside in direct sunlight, possibly holding a water bottle in the other hand, being shouted at by players, with a phone that may have a cracked screen, on a mobile connection that might drop every few minutes. The app will be used by people with no technical background who have never scored a cricket match before.

Design for the hardest case, not the easiest.

### Pre-Match Flow

**Step 1: Match selection**
- Scorer opens app → sees "Today's Matches" → taps their assigned match
- No searching, no typing

**Step 2: Toss**
```
TOSS
Who won? [OKINAWA WARRIORS ▼]
Decision? [BAT FIRST]  [FIELD FIRST]
             [CONFIRM]
```
One screen, three taps maximum.

**Step 3: Playing XI selection**
- See the full squad with jersey numbers as a checklist
- Tap to include/exclude (default: all included)
- 11 players shown with large touch targets
- Can be done in 60 seconds

**Step 4: Batting order (optional but recommended)**
- Drag-and-drop for top 4 at minimum
- Rest can be filled in as wickets fall

### Active Scoring Screen Layout

The screen divides into three zones:

```
┌────────────────────────────────────────────────┐
│  ZONE A — MATCH STATE (top 35% of screen)      │
│                                                 │
│  OKI WARRIORS  127/4   14.2 overs             │
│  ─────────────────────────────────────────    │
│  #7  ROSHAN    58*(39)   on strike             │
│  #18 SANDIP    21*(17)                         │
│  ─────────────────────────────────────────    │
│  Bowling: #23 BIKASH    2/24 (5.2 ov)         │
│  Recent: ● 6 · 1 · 0 · 4 · W · 2             │
├────────────────────────────────────────────────┤
│  ZONE B — PRIMARY ACTIONS (middle 40%)         │
│                                                 │
│  [ 0 ]  [ 1 ]  [ 2 ]  [ 3 ]  [ 4 ]  [ 6 ]    │
│                                                 │
│  [ W ]  [ WD ] [ NB ] [ BYE] [LBY ]           │
│                                                 │
├────────────────────────────────────────────────┤
│  ZONE C — SECONDARY ACTIONS (bottom 25%)       │
│                                                 │
│  [ UNDO ]    [ BOWL CHG ]    [ ··· MORE ]      │
└────────────────────────────────────────────────┘
```

**Touch target sizes:** Minimum 60×60px for primary buttons (0,1,2,3,4,6), 50×50px for secondary (W, WD, NB, BYE, LBY). Never smaller.

**Color coding:**
- Run buttons: Neutral/white background
- Wicket (W): Red
- Extras (WD, NB): Orange
- Byes/Leg-byes: Yellow
- Undo: Gray with clear destructive intent visual

### Wicket Flow

When scorer taps [W]:

```
WICKET — #7 ROSHAN

How out?
[BOWLED] [CAUGHT] [LBW] [RUN OUT] [STUMPED] [HIT WKT] [OTHER]

↓ (after selection, if caught/stumped/run out):
Fielder: 
[#11 AMIT] [#4 SURAJ] [#9 DEV] [#6 PRADEEP] [#2 KUMAR]
[#15 HARI] [#22 RAJAN] [#3 SAGAR] [#8 BIKASH]  ← all fielding team shown
                                                   with jersey numbers

New batter: [#12 ARJUN entering]

[CONFIRM WICKET]
```

Every interaction in the wicket flow should be tappable — no typing. Jersey numbers replace names everywhere.

### UNDO System

- One-level undo only (last delivery)
- Prominently placed, always visible
- Shows exactly what will be undone: "Undo: 4 runs, over 14.2"
- Confirmation tap required
- For deeper corrections: Correction Mode (see below)

### Correction Mode

After a match or mid-match (organizer-level access only):

- Shows ball-by-ball log as a scrollable list
- Tap any delivery to edit
- Changes are flagged as "admin correction" with timestamp
- Stats and OVR recompute automatically after save
- Audit trail maintained (original entry + correction visible to organizer)

This is the CricHeroes gap. Players get locked into wrong stats with no recourse. CrickRise fixes this.

### Bowling Change

```
[BOWL CHG] → 
"Who is bowling next?"
[#4 SURAJ] [#9 DEV] [#6 PRADEEP] [#2 KUMAR] [#8 BIKASH]
             (excludes currently bowling and batters)
```

One tap, done.

### Innings Transition

When 10 wickets fall or overs complete:

```
INNINGS COMPLETE
Okinawa Warriors: 174/9 (20 overs)

TARGET: 175

[CONTINUE TO 2ND INNINGS →]
```

Select fielding team batting order — same flow as pre-match.

### Offline Mode

**Behavior when internet drops:**
1. Banner appears at top: 🔴 OFFLINE — scoring continues locally
2. Every delivery saved to local device storage (AsyncStorage / SQLite)
3. When connection returns: Banner changes to 🟡 SYNCING...
4. After sync complete: ✅ ALL DATA SAVED

**Conflict resolution:** If two scorers (one offline, one online) have entered diverging data, flag for organizer review. Never silently overwrite. Show the conflict explicitly.

**Phone dies mid-match:** If the scorer's phone runs out of battery and another scorer needs to take over:
- Any completed overs are retrievable from the server (online scorers sync per delivery)
- Offline batches sync when the original phone returns
- Organizer can merge or override conflicting entries

### Special Situations

**Wrong batter at crease:**
[···] → "Fix batter" → shows all non-dismissed batters → correct batter selected → stats swap silently

**Wrong bowler:**
[···] → "Fix this over's bowler" → re-assign bowling stats to correct player

**Run-out (both ends):**
Wicket modal: [RUN OUT] → "Which batter?" → [#7 ROSHAN] [#18 SANDIP]

**Retired hurt:**
[···] → "Retired hurt" → player marked as retired, new batter enters, player can return later

**Powerplay tracking:**
[···] → "Start Powerplay" → visual indicator appears on match state

**Super over:**
[···] → "Super Over" → separate innings record created

### Multiple Formats

The system must handle:
- T20 (20 overs per side)
- ODI-style (50 overs or custom)
- Any custom over count (5-over blast, 10-over pairs)
- Organizer defines format at league creation — scorer never needs to configure this

---

## 11. LIVE MATCH EXPERIENCE

### Who Watches?

- Players who are not currently batting/bowling
- Players who are warming up or resting
- Friends and family of players
- Community members who could not attend
- Future opponents checking form

### The Live Match Screen

```
LIVE ● 
Okinawa Warriors vs Tokyo Rhinos

OKI WARRIORS    127/4
14.2 overs

──────────────────────────────
#7  ROSHAN KC    58*(39)  ●
#18 SANDIP       21*(17)
──────────────────────────────
#23 BIKASH       2/24   5.2 ov
──────────────────────────────
Partnership: 67 runs (8.1 ov)
──────────────────────────────
RECENT BALLS:
  6 · 1 · 0 · 4 · W · 2
──────────────────────────────
NEED 175  ·  chase begins after
──────────────────────────────
  [ SCORECARD ]  [ BALL-BY-BALL ]
```

**What to keep:** Live score, current batters, current bowler, partnership, recent balls, required (when chasing). These six pieces of information account for 95% of what anyone watching wants to know.

**What to cut from the live screen in V1:** Live commentary (adds complexity, no AI allowed), video (too complex), detailed match statistics mid-innings (secondary tab is fine).

**The scorecard tab** expands to show full batting and bowling cards for the current innings. Clean, traditional cricket scorecard layout.

**The ball-by-ball tab** shows each delivery chronologically with dots, runs, extras, wickets highlighted.

### Push Notifications for Following Players

"#7 Roshan KC just hit a FIFTY! 50*(31) 🏏" — sent to any user who follows Roshan.

This is a retention driver and a viral mechanism. When a player gets this notification about themselves, they share it. V1 can handle this with basic push notifications — no AI required.

---

## 12. OVR / RATING SYSTEM

This is the product's soul. Design it carefully, transparently, and with specific anti-gaming measures from day one.

### Core Design Principles

1. **Bayesian at heart:** Every new player starts at 50 (league average). As data accumulates, the confidence in the rating increases. Small samples produce ratings that stay close to 50. Large samples allow large deviations.

2. **Role-aware, not generic:** A pure bowler's OVR is not pulled down by a batting average of 8. A wicketkeeper's fielding contribution is valued differently than a non-keeper's.

3. **Recency matters, but not too much:** Recent form has moderate influence. A player who had one bad match does not plummet. A player who had one great match does not rocket.

4. **Anti-gaming by design:** Farming stats in garbage matches against weak opposition should not help much. Context-weighting is essential.

5. **Transparent without being gameable:** Show players which broad factors influence their OVR, but not the exact formula. This maintains trust without creating an exploit guide.

### Player Roles

Assign one primary role per player (organizer sets at registration, player can request change):
- **Pure Batter (PB)**
- **Pure Bowler (PB)**
- **Batting All-rounder (BAR)**
- **Bowling All-rounder (BOAR)**
- **Wicketkeeper-Batter (WKB)**

The system detects inconsistency (e.g., a "pure batter" who has taken 15 wickets in 10 matches) and flags the organizer to review role assignment.

### Rating Domains

**BAT (Batting Rating, 1-99)**

Inputs:
- **Batting Average** (runs per dismissal) — most heavily weighted
- **Strike Rate** relative to format (T20 benchmark ≠ ODI benchmark)
- **Consistency** (% of innings scoring 15+ runs)
- **Big Innings Rate** (50s and 100s per 10 innings)
- **Not-Out Handling** (adjusted average that doesn't overly reward never-batting)

**BOWL (Bowling Rating, 1-99)**

Inputs:
- **Bowling Average** (runs conceded per wicket)
- **Economy Rate** relative to format
- **Strike Rate** (balls per wicket)
- **Wicket Rate** (wickets per match)
- **Pressure Index** (wickets in the last 5 overs, death bowling)

**FIELD (Fielding Rating, 1-99)**

Inputs:
- **Catch Success Rate** (catches taken vs opportunities, estimated from match data)
- **Run-Out Contributions** (direct hits and assists)
- **Wicketkeeping additions** (stumpings count here for WKBs, weighted 2x)

Note: Fielding data in amateur cricket is inherently incomplete. Many chances are never recorded. The FIELD rating should be presented with an "estimated" caveat until enough data accumulates. It should have less influence on OVR than BAT or BOWL, both because it is less data-rich and because amateur fielding quality is more random.

### OVR Calculation by Role

```
Pure Batter (PB):
  OVR = BAT × 0.75 + FIELD × 0.20 + BOWL × 0.05

Pure Bowler (PBOW):
  OVR = BOWL × 0.75 + FIELD × 0.20 + BAT × 0.05

Batting All-rounder (BAR):
  OVR = BAT × 0.55 + BOWL × 0.30 + FIELD × 0.15

Bowling All-rounder (BOAR):
  OVR = BOWL × 0.55 + BAT × 0.30 + FIELD × 0.15

Wicketkeeper-Batter (WKB):
  OVR = BAT × 0.50 + FIELD × 0.35 + BOWL × 0.15
```

### Sample Size Handling

- **0-4 matches:** No OVR displayed. Show "Building Profile..." with a progress bar toward 5 matches.
- **5-9 matches:** OVR displayed with "Developing" label. Rating stays within 40-70 range regardless of actual performance (Bayesian shrinkage toward mean).
- **10-19 matches:** OVR can range 35-80. Label removed.
- **20+ matches:** Full OVR range available (30-95). Rating converges to true performance.

This means a new player who hits a century in their first match does not become OVR 95 immediately. The system is honest about uncertainty. After 20+ matches, the number means something real.

### Recency Weighting

The OVR is a weighted average of performance windows:
- Last 5 matches: 40% weight
- Previous 10 matches: 35% weight
- Career beyond that: 25% weight

This creates a "form-sensitive" OVR that still respects career performance. A single bad match won't destroy a 40-match career OVR. A player who has lost form will see their OVR slide, but slowly.

### Anti-Gaming Measures

1. **Minimum balls faced/bowled per match to count:** A batter must face 6+ balls for batting stats to count from that match. A bowler must bowl 1 complete over. This prevents cameo padding.

2. **Opposition quality context-weight:** This is subtle but important. When a bowler takes 5 wickets against a side with a Team OVR of 42, it counts less than 5 wickets against a side with Team OVR 74. The weight modifier is ±15% at most — enough to matter, not enough to dominate.

3. **Match importance modifier:** Knockout matches and finals carry a small boost (1.1×). Regular league matches are baseline (1.0×). This rewards performing under pressure.

4. **Fraud detection flags:** Impossible statistics (a batter scoring 200 off 20 balls, a bowler taking 12 wickets in a 10-wicket match) trigger an automatic admin review flag. The match is held in "pending verification" state and excluded from OVR calculations until an organizer confirms the result.

5. **No self-scoring boost:** A player cannot serve as the official scorer for their own match. If they do (because no dedicated scorer is available), their own batting/bowling contributions are flagged with lower confidence and weighted at 0.75× in OVR calculations.

### What OVR Bands Mean (communicate this to players)

| OVR | Label | Description |
|-----|-------|-------------|
| 90-99 | Elite | Top performer, exceptional even at national level |
| 80-89 | Excellent | Dominant in any amateur league |
| 70-79 | Very Good | Consistent match-winner |
| 60-69 | Good | Above average, reliable contributor |
| 50-59 | Average | Competitive, holds their own |
| 40-49 | Below Average | Developing, room to grow |
| 30-39 | Beginner | New to competitive cricket |

In a typical amateur league, most players should cluster in the 50-72 range. An OVR of 80 in an amateur community is genuinely impressive. An OVR of 90 should be extremely rare.

### What To Show In The App

**Free:**
- OVR (single number)
- BAT / BOWL / FIELD (three domain numbers)
- Form strip (5-match directional arrows: ↑↓→)
- Current season rank in league

**Pro (paid):**
- What contributed to each domain (breakdown of inputs)
- OVR trend graph over career
- Form detail (which matches drove recent changes)
- Comparison to league average by role
- Season OVR vs Career OVR separately

**Never shown publicly:**
- The exact formula weights
- Raw sub-attribute inputs used in calculation
- Other players' Pro breakdowns

### The Rating System's Critical Failure Mode

The rating system fails if organizers allow friendly matches to count as competitive league matches. A team could arrange to play against a genuinely weak side, score massively, and inflate everyone's OVR.

**The fix:** Organizers must designate matches as either "League" (counts full weight toward OVR) or "Friendly" (counts 0.5× weight). They make this choice when creating the fixture. League matches are distinguished in the app with a badge. Friendlies still create a record but are clearly marked.

---

## 13. RANKINGS

### What to Build and When

**V1 — Only these:**
- League Batting Ranking (by batting rating, within the season)
- League Bowling Ranking (by bowling rating, within the season)
- League OVR Ranking (top players by OVR, all roles)

These three rankings, within one league, are enough to create competition and return visits. Every player knows exactly where they stand vs their teammates and opponents.

**V1.5:**
- Season MVP Ranking (MVPs accumulated)
- Most Improved (OVR gain from start to end of season)

**V2 and beyond:**
- Regional rankings (e.g., all leagues in Okinawa, all leagues in Japan)
- Japan-wide OVR ranking by role
- Cross-country rankings for diaspora leagues

### What to Remove From the Original Brief

- "Form ranking" — redundant with OVR (form is already embedded)
- "Power rankings" — sounds cool but is complex and will confuse amateur users in V1
- "Head-to-head" — needs data depth you won't have in V1
- "Player of the Week" — requires editorial judgment or automation you don't have

### Why Rankings Create Return Visits

Rankings change only when matches are played or when the season ends. This means:
- Every matchday is a potential ranking change event
- Players check rankings before their match (am I still #4?) and after (did I overtake #3?)
- This creates 2-3 app open events around every match the player participates in
- Add push notifications for ranking changes ("You've moved from #5 to #3 in batting!") and you have 4-5 touch points per match

---

## 14. PLAYER RETENTION

### The Retention Calendar

Players do not play cricket every day. A Nepali community league in Japan might play once a week during the season, or every two weeks. That means:

- **Match weeks:** High natural engagement. Scorer app, live feed, post-match OVR update, rankings change.
- **Between-match weeks:** Low natural engagement. This is the retention problem.

**What keeps players coming back between matches:**

1. **Rankings notifications:** "You've been overtaken by #9 Bikash in bowling rankings." — triggers competitive response.
2. **League activity:** When other teams play matches, the league standings and rankings shift. Players want to know.
3. **Upcoming fixture countdown:** "Your next match vs Tokyo Rhinos is in 4 days."
4. **Milestone approach alerts:** "You're 47 runs away from 500 career runs." — this is a powerful pull mechanic.
5. **Season progress:** "8 matches left in the season. You're ranked #4."

### Retention Mechanics to Build

**The Milestone System (V1 version):** A small set of meaningful milestones with no badge spam.

| Milestone | Trigger | Display |
|-----------|---------|---------|
| First Match | Complete first match | Career starts |
| First 50 | Score 50+ in one innings | Batting milestone |
| First Wicket | Take first wicket | Bowling milestone |
| Hat-trick | 3 wickets in 3 balls | Rare, celebrated |
| Century | Score 100+ in one innings | Major achievement |
| 5-for | Take 5+ wickets in one innings | Major achievement |
| First MVP | Win first MVP award | Team contribution |
| 500 Career Runs | Cumulative batting milestone | Career marker |
| 100 Career Wickets | Cumulative bowling milestone | Career marker |
| Champion | Win league | Team milestone |

These 10 milestones are enough. Each should feel earned, not given. Never create a milestone for "created an account" or "watched your first match." Milestone inflation destroys the signal value of all milestones.

### What Players Will Return For That You Haven't Listed

**The leaderboard effect:** Players who are ranked 3rd will check rankings more compulsively than players ranked 1st or 15th. The sweet spot is ranked 2nd-5th — close enough to #1 to feel reachable. Design notifications that tell players about gaps within 3 positions of them, not their absolute rank.

**The career stat ticker:** "Your all-time batting average is 38.4, up from 36.1 last season." Season-over-season improvement is deeply motivating for amateur athletes. Build this post-season summary as a ritual annual experience.

---

## 15. VIRAL LOOP

### The Primary Viral Mechanism: The Match Card

After every match, for every player who participated:
- Auto-generate a shareable image card (1080×1080px, Instagram-ready)
- Card shows: Player photo placeholder / jersey, match performance, OVR, team result
- Single tap to share to WhatsApp, LINE, Instagram, or copy link
- The link goes to the full match scorecard with a CrickRise branding strip

Example card:
```
┌──────────────────────────────────────┐
│  🏏 CRICKRISE MATCH CARD              │
│                                       │
│  #7  ROSHAN KC   OVR 86              │
│  Okinawa Warriors                    │
│                                       │
│  MATCH vs Tokyo Rhinos · WINNER ✓    │
│                                       │
│  58* (39)  3/24               ★ MVP  │
│                                       │
│  [VIEW FULL SCORECARD]               │
│         crickrise.com                │
└──────────────────────────────────────┘
```

Every time a player shares this card, they are distributing a CrickRise advertisement. In WhatsApp communities of 50-200 Nepali cricket players, one MVP card shared generates 10-30 views. Some percentage of those viewers ask how to join.

### The OVR Reveal Card

When a player first reaches the 5-match threshold and their OVR unlocks, treat this as a special moment:
- Animated reveal sequence (not a static screen — a brief animation where the number counts up)
- Auto-generated shareable "First OVR Card": "My cricket career has officially started. OVR 67. Let's rise."
- This is the most shareable moment in the product

### The League Launch Card

When an organizer creates a league, give them:
- A shareable invitation image: "Season 3 of the Okinawa Nepali Cricket League is open! Register your team. [Link]"
- This goes into the same WhatsApp groups and Facebook posts the organizer uses anyway
- The card format makes CrickRise look professional compared to a plain text announcement

### Organic Virality via Live Match Links

During a live match, every spectator who opens the live match center URL:
- Sees real-time scoring with CrickRise branding
- Sees the player profiles of current batters
- Has a one-tap "Follow this player" option
- Has a "Join your next league" CTA at the bottom

The live match center URL is designed to be shared during the match itself ("aye bhai dekhna - live score" / "hey, watch the live score") in WhatsApp groups. This is the most natural viral moment in the entire product.

---

## 16. MONETIZATION

### The Core Decision: What Is Free, What Is Paid

**PERMANENTLY FREE:**
- All organizer features, always. No exceptions. The organizer is the distribution channel, not the customer.
- Player profile (name, team, jersey number)
- Current season stats: matches played, runs scored, wickets taken, catches, MVPs
- OVR number (single number only)
- League standings and fixtures
- Live match feed
- Match scorecards
- Basic milestones (first match, first 50, etc.)
- Shareable match result card (basic version)

**PLAYER PRO (paid):**
- OVR breakdown: BAT / BOWL / FIELD with brief explanation of what's affecting each
- OVR trend over career (graph)
- Full career history (all seasons, all matches)
- Advanced stats: batting average, strike rate trend, economy trend, bowling average
- Cross-league rankings (regional and Japan-wide)
- Premium shareable cards (better design, with OVR prominently)
- Form detail: which specific matches drove your current form
- Ad-free experience
- Season milestone summary (annual "your cricket year" overview)

### Why This Paywall Is Correct

CricHeroes gated *basic personal stats* (career batting average, leaderboard position) behind Pro. Players revolted. CrickRise gates *depth and context* — the story behind the number, not the number itself. Players who are competitive will pay to understand what is pulling their OVR down. Players who want to show off will pay for the premium card. Players who want to compare themselves across leagues will pay for cross-league rankings.

### The Paywall Trigger Moment

**Do not show the paywall on first open.** Show it at the right emotional moment:
- After a player's OVR is first revealed (OVR unlock event): "Want to see what's driving your BAT score? Go Pro."
- After a good match: "You just scored 67 — your batting trend is up. See the full picture."
- When a player tries to access career history beyond current season: natural gate.

### Revenue Model Summary

| Stream | Description | Price |
|--------|-------------|-------|
| Player Pro Annual | Primary revenue | ¥3,980/year (~$26) |
| Player Pro Monthly | Option for hesitant users | ¥480/month (~$3.20) |
| Future — Organizer Verified Badge | Premium certification for formal associations | TBD, V3+ |
| Future — Sponsorship integration | Local sponsor logos on league pages | TBD, V3+ |

### What to Avoid

- **No ads in V1.** Ads in a small-community sports product feel cheap, damage trust, and create exactly the CricHeroes problem you're trying to solve. Revenue from ads at your initial scale is negligible. The brand damage is not.
- **No pay-per-feature microtransactions in V1.** Keep it simple: free or Pro. Complexity in pricing creates hesitation.
- **No charging organizers in V1 or V2.** This is existential — one unhappy organizer in a small community can take the entire league elsewhere.

---

## 17. PRICING

### Japan Market Pricing

**Annual: ¥3,980/year (~$26)**
- Positioned as "less than one cup of coffee per month"
- Should be the first/most prominent option displayed
- 28% savings vs monthly

**Monthly: ¥480/month (~$3.20)**
- For skeptical users who want to try before committing
- Higher per-year cost by design (anchor the annual)

**Free Trial:** 14-day free Pro trial for new users, triggered at OVR unlock. The goal is to have them experience the full OVR breakdown and career analytics during the trial period and convert.

### International Pricing (for diaspora expansion)

| Market | Annual | Monthly |
|--------|--------|---------|
| Nepal | NPR 1,500/year (~$11) | NPR 150/month |
| UAE/Qatar | AED 48/year (~$13) | AED 6/month |
| Malaysia | MYR 60/year (~$13) | MYR 8/month |
| UK | £18/year (~$23) | £2.50/month |
| USA | $24/year | $3/month |

Use Apple/Google platform-suggested pricing as starting points, localized. The Japan price is deliberately positioned higher because Japan is a higher-income market.

### Why Players Pay

The psychological trigger is not financial — it is identity. "I want my cricket profile to be complete." In tight-knit diaspora communities where cricket is both sport and social life, paying ¥3,980 to have a complete, impressive-looking cricket career profile is genuinely compelling. This is less than the cost of one cricket match entry fee in most communities.

---

## 18. UNIT ECONOMICS

### Assumptions

- Active player: played in 1+ matches in current season
- Engaged player: 5+ matches per season, checks the app regularly
- Conversion rate: 10% of engaged players convert to Pro (conservative; industry for sports analytics ranges 5-15%)
- Churn: 20% annual (players stop playing, move away, lose interest)

### Revenue Projections

**At 1,000 registered players (Japan beachhead):**
- Active players (60%): 600
- Engaged players (40% of active): 240
- Pro conversions (10% of engaged): 24
- Annual revenue: 24 × ¥3,980 = ¥95,520 (~$620/year)
- **Verdict:** Pre-revenue stage. Focus on proving retention, not monetization.

**At 5,000 players (Okinawa + other Japan cities):**
- Engaged: ~1,200
- Conversions: ~120
- Revenue: 120 × ¥3,980 = ¥477,600 (~$3,200/year)
- **Verdict:** Proof of concept. Enough to know the model works.

**At 10,000 players (Japan + initial diaspora communities):**
- Engaged: ~2,500
- Conversions: ~300
- Revenue: 300 × ¥3,980 = ¥1,194,000 (~$8,000/year)
- **Verdict:** Still small. The market must expand beyond Japan.

**At 50,000 players (Japan + Nepali diaspora globally, localized pricing):**
- Engaged: ~13,000
- Conversions: ~1,500 (slightly higher conversion with established brand)
- Blended annual ARPU: ~¥3,000 (mix of Japan and lower-price markets)
- Revenue: 1,500 × ¥3,000 = ¥4,500,000 (~$30,000/year)
- **Verdict:** Still modest. Growing. First full-time hire is justifiable.

**At 100,000 players:**
- Engaged: ~26,000
- Conversions: ~3,000
- Blended ARPU: ¥3,000
- Revenue: ¥9,000,000 (~$60,000/year)

**At 500,000 players (full Nepali diaspora + Nepal domestic amateur cricket):**
- This is where it gets interesting
- Engaged: ~130,000
- Conversions: ~15,000
- Revenue: ¥45,000,000+ (~$300,000/year)
- At this scale, enterprise/association deals and sponsorships become real
- Path to $1M+ ARR is clear

### Honest Assessment

This is not a quick-revenue business. The unit economics only become compelling above 100,000 engaged players. That requires expanding well beyond Japan. The growth strategy must include Nepal and the broader diaspora from month 12 onward, or the business will be technically interesting but financially stagnant.

The product should be designed and built to reach 500,000+ players. The business does not work at 10,000.

---

## 19. V1 — WHAT TO BUILD

### The North Star for V1

V1 must prove five things:
1. An organizer will set up their league here and stay
2. A scorer can operate it without training
3. A player returns to the app between matches
4. A player cares enough about their OVR to show it to others
5. A player would consider paying for Pro when the feature unlocks

### MUST HAVE (V1.0)

**Organizer:**
- League creation (name, logo, format, season)
- Team management (add/edit/remove teams)
- Player registration with jersey numbers
- Fixture creation (date, time, venue, teams)
- Scorer assignment per match
- Standings (auto-calculated)
- Match correction/admin override
- Player correction (fix wrong stats, merge duplicate player accounts)

**Scorer:**
- Pre-match: toss, playing XI, batting order (top 4)
- Active scoring: 0/1/2/3/4/6/W/WD/NB/BYE/LBY buttons
- Wicket modal: dismissal type, fielder (jersey number picker)
- Bowling change
- Innings transition
- Undo (last ball)
- Offline mode with auto-sync
- Wrong batter/bowler correction (mid-innings)

**Player:**
- Profile: name, jersey, team, role
- Current season stats: matches, runs, wickets, catches, MVPs
- OVR (shows after 5 matches, with "Developing" label 5-9)
- Form strip (5-match arrows)
- League rank in current season

**Match Experience:**
- Live match feed: score, current batters, current bowler, recent balls
- Post-match scorecard
- MVP auto-suggested (highest batting + bowling contribution), organizer confirms
- Auto-generated match card (shareable image)

**Virality minimum:**
- Shareable match result card (WhatsApp/LINE share)
- Live match URL shareable link
- League invitation link/card

### SHOULD HAVE (V1.5, within 3 months of V1 launch)

- Push notifications (ranking changes, match results, milestone alerts)
- Player Pro subscription (paywall gate, payment processing)
- Basic achievement milestones (first match, first 50, first wicket, first MVP)
- Multi-season player history (career tab on profile)
- Full career stats (runs, wickets, matches across all seasons)
- Jersey number on the shareable card
- Nepali language support (Devanagari)

### LATER (V2, 6+ months in)

- Cross-league rankings (regional, Japan-wide)
- Team OVR (aggregate of squad)
- Team profile with season history
- Season summary / "Your Cricket Year" annual card
- Head-to-head stats (player vs player)
- Advanced analytics for Pro users (trend graphs)
- Organizer league website (public-facing league page)

### NEVER / REMOVE

- **AI commentary generation** — explicitly excluded from V1, and honestly not needed even in V2. Real cricket commentary is better than AI commentary for engaged communities.
- **Live streaming** — CricHeroes has this, it's expensive, complex, and distracts from the core product. The community will use YouTube Live independently.
- **Merchandise store** — This is CricHeroes' attempt at revenue diversification. It is a supply chain business that has nothing to do with your core product and creates support burden (delayed T-shirts are their #1 complaint).
- **Fantasy cricket** — Different product, different audience, different legal complexity by jurisdiction.
- **Academy management** — Different customer (academy owners), different UX, different revenue model. Do not dilute.
- **Umpire management** — Interesting eventually, but informal leagues don't have official umpires. Not V1.
- **Coaching plans** — Not what this product is.
- **Rivalries feature** — Needs at least 2+ seasons of head-to-head history to be meaningful. Do not fake it.
- **Player of the Week feature** — Requires editorial judgment, creates political problems in small communities ("why did Roshan get POTW when I scored more runs?"). Replace with pure data-driven ranking positions.

---

## 20. FUTURE ROADMAP

### Phase 1: Beachhead Proof (Months 1-6)
- One league in Okinawa running on the platform
- All 5 V1 proof points validated
- 50-150 active players
- Scorer UX stress-tested in real outdoor conditions
- OVR system producing ratings that players find believable
- First shareable cards generated and posted in community groups

### Phase 2: Japan Expansion (Months 6-18)
- 5-10 leagues across Japan (Okinawa, Tokyo, Osaka, Fukuoka)
- Pro subscription launched
- First paying subscribers acquired
- Nepali language UI available
- Push notifications live
- 1,000-3,000 players

### Phase 3: Diaspora Expansion (Months 18-36)
- Active community partnerships in Qatar, UAE, Malaysia
- Localized pricing
- Cross-country rankings
- Nepal domestic community leagues onboarded
- 10,000-50,000 players target
- Team and league sponsorship integration (local businesses targeting Nepali community)

### Phase 4: Nepal Domestic (Year 3+)
- Target grassroots cricket in Nepal itself
- Partner with Nepal Cricket Board for youth development pipeline integration
- CrickRise as the verified career record for Nepali club cricket
- 100,000+ player target

### Future Features (Not V1 or V2, but worth designing for)

- **Player marketplace / scouting:** Organizers searching for players by OVR and role. "Available all-rounders in Tokyo with OVR 70+." This becomes a recruiting tool.
- **Nepal national team pipeline integration:** If NCB adopts CrickRise as the official grassroots tracking system, players playing in diaspora leagues can have their records considered for national junior selection.
- **Verified league tiers:** Silver / Gold / Diamond league certification based on data quality, match frequency, and official umpires. Higher tier leagues have higher match importance modifiers.
- **Sponsor targeting:** A local cricket gear shop in Kathmandu wants to reach top-ranked players in diaspora leagues. CrickRise enables this with zero PII sharing.

---

## 21. TECHNICAL ARCHITECTURE CONSIDERATIONS

### What Must Be Designed Correctly From Day One

**1. Player as a first-class entity, not a league member.**
```
Player {
  id: UUID (global, unique, permanent)
  name: string
  dob: date (optional)
  contact: email or phone
  created_at: timestamp
}

TeamMembership {
  player_id: → Player
  team_id: → Team
  jersey_number: int
  role: enum (PB | PBOW | BAR | BOAR | WKB)
  active_from: date
  active_until: date | null
}
```

When a player transfers to a new team, a new TeamMembership record is created. The old one gets an `active_until` date. The player's historical stats remain linked to the original team membership period. Career history is preserved automatically.

**2. Ball-by-ball event log as the immutable source of truth.**
```
Delivery {
  id: UUID
  match_id: → Match
  innings_number: int (1 or 2)
  over_number: int
  ball_number: int (1-6, or 7+ for extras)
  batsman_id: → Player
  non_striker_id: → Player
  bowler_id: → Player
  runs_off_bat: int
  extra_type: enum (none | wide | no_ball | bye | leg_bye)
  extra_runs: int
  wicket: {
    type: enum | null
    dismissed_player_id: → Player | null
    fielder_id: → Player | null
  }
  is_admin_correction: boolean
  original_delivery_id: → Delivery | null (if this is a correction)
}
```

**Never store computed stats.** Batting averages, bowling economy, OVR — all computed from the Delivery log on demand or cached with invalidation. This means any correction automatically propagates to all downstream stats and ratings.

**3. Offline scoring protocol.**
- Scorer app stores deliveries in local SQLite/AsyncStorage immediately on entry
- Transmits to server every completed over (6 deliveries)
- Falls back to: transmit on reconnect
- Server assigns a `received_at` timestamp, not the delivery timestamp
- Deduplication by delivery UUID prevents double-counting on sync

**4. Rating computation as a background job.**
OVR should NOT be computed in real-time on every ball. It should be a background job that runs after each match completes. This decouples scorer latency from rating computation complexity.

### What Can Be Simplified for V1

- **Real-time live feed:** HTTP polling every 5 seconds is fine. WebSockets/SSE can come in V2.
- **Rating computation:** Simplify the Bayesian model for V1 — a weighted average with minimum match thresholds is sufficient. Full Bayesian inference can come in V1.5.
- **Analytics dashboard:** Basic aggregations are fine. Complex trend graphs are Pro V2 features.
- **Multi-timezone support:** For V1 (Japan only), assume JST. Build timezone-awareness into the data model even if you only use one timezone initially.

### Technology Choices (Recommendations for a Small Team)

- **Backend:** Node.js (TypeScript) or Python (FastAPI) — choose what the team knows. Serverless-friendly.
- **Database:** PostgreSQL — relational data with strong referential integrity is important for cricket statistics
- **Mobile:** React Native — single codebase for iOS and Android, important for a small team
- **Offline storage:** WatermelonDB (React Native) — designed for offline-first apps with sync
- **Image generation (match cards):** Server-side canvas rendering (Node canvas or Puppeteer) — generate cards on the server, not the client
- **Hosting:** Initially: a single managed PostgreSQL + Node.js deployment (Railway, Fly.io, or Render). Simple, cheap, manageable by a team of 2.

### Data Model Completeness Check

Entities needed from day one:
- `Player` (global identity)
- `League` (with format config)
- `Season` (within a league)
- `Team` (within a league/season)
- `TeamMembership` (player ↔ team with dates)
- `Match` (within a season, between two teams)
- `Innings` (within a match)
- `Delivery` (ball-by-ball)
- `MatchAward` (MVP, linked to match + player)
- `PlayerRating` (computed, versioned by match)

Entities that can wait:
- `Achievement` (milestone records)
- `Notification`
- `Subscription` (payment)
- `LeagueInvite` (shareable token)

---

## 22. GROWTH STRATEGY

### Month 1-3: Zero-to-One

**The only goal:** Get one complete league season scored on CrickRise with 6+ teams and 50+ players. Do this personally. Be in the community. Help the organizer set up. Sit next to the scorer at the first match. Fix problems in real time.

**Tactics:**
- Identify the most organized cricket person in the Okinawa Nepali community
- Offer to set up their league for them (hands-on onboarding, not a self-serve flow)
- Attend matches. See what breaks. Fix it the same day.
- Create the OVR reveal moment after match 5 for every player in the league
- Capture reactions. Real Nepali community members seeing their OVR for the first time is the marketing content for every future league.

### Month 3-6: Deepen Before Scaling

Do not expand to another city until the Okinawa league runs cleanly through a full season, the scorer can operate without help, and at least 3 players have voluntarily shared their match card on WhatsApp.

**The test:** Can the organizer run a full match day without you? If not, the product is not ready to scale.

### Month 6-12: Adjacent Communities

With proof from Okinawa, approach the organizers of existing leagues in Tokyo (Everest Cricket Club, JCA-affiliated Nepali teams), Osaka, Fukuoka. These communities already know each other — word travels within the Nepali cricket network.

**The pitch to organizers:** "We run a platform for Nepali cricket leagues. Your players get a permanent career profile and an OVR. It's free for you, and your players love it. Want to see what Okinawa is using?"

### Month 12-18: Diaspora Expansion

Target the next largest Nepali cricket communities outside Japan:
- Qatar (through connections with existing Qatar Nepali cricket leagues)
- Malaysia (large Nepali migrant worker community, organized cricket)

Use diaspora media channels: Nepali-language news sites, YouTube channels, Facebook groups popular with overseas Nepali communities.

**Key insight:** The diaspora is a tightly connected social graph. A Nepali cricketer in Qatar and a Nepali cricketer in Japan likely share mutual contacts. When the Qatar players see the Okinawa players sharing OVR cards, they want the same.

---

## 23. LONG-TERM MOAT

### The Real Defensibility

CrickRise's moat is not technology. Any competent team could build the features within 12 months. The moat is **verified historical data owned by players, stored permanently on the platform.**

After 3 years:
- A player who has 80 verified matches on CrickRise has a cricket résumé that is worth something to them
- Moving to a competitor means starting from zero
- The organizer who has run 3 seasons on CrickRise has their entire league archive here — team history, player development stories, the match where #7 Roshan hit the winning runs in the final
- These stories have emotional value that no competitor can migrate

**The second moat:** Community network density. When every cricket-playing Nepali in Japan is on CrickRise, the platform has social value independent of its features. Being the place where "everyone is" has its own gravity.

**The third moat (long-term):** If Nepal Cricket Board or the ICC ever recognizes CrickRise data as official, the verified career records become worth even more. This is a 5-year ambition, not a year-1 objective.

### What CrickRise Could Realistically Become

**Scenario A (most likely success):** The dominant platform for Nepali diaspora cricket globally. 300,000-500,000 players across 20+ countries. Sustainable SaaS revenue at $500K-$2M ARR. Possibly acqui-hired by a cricket data company or sporting media platform.

**Scenario B (ambitious success):** The player identity layer for all of amateur cricket outside India. Analogous to what LinkedIn is for professional identity — a portable verified record that travels with you. Raises venture capital, expands to all cricket-playing countries, competes with CricHeroes directly.

**Scenario C (unexpected success):** The OVR system for grassroots cricket attracts interest from national cricket boards looking to identify talent. CrickRise becomes part of the official player development pipeline in Nepal, then other Associate ICC nations. Institutional revenue changes the business model entirely.

**Scenario D (sports identity platform):** The OVR concept proves so compelling that CrickRise expands beyond cricket into other South Asian diaspora sports (kabaddi, futsal). Becomes a platform for migrant worker sports communities globally.

The highest-probability path to success is Scenario A. Build for it, but design the product to enable Scenario B if you get there.

---

## 24. BIGGEST RISKS

### Risk 1: Okinawa is the ceiling, not the floor.
**The danger:** The founding team gets comfortable with a functioning small community, struggles to expand beyond it, and the business stagnates at 500 players generating ¥2M/year.
**The mitigation:** Set explicit expansion triggers before launch. "When 3 complete seasons are running in Okinawa, begin onboarding in Tokyo." Hardcode the dates. Don't let comfort become a trap.

### Risk 2: CricHeroes builds OVR.
**The danger:** CricHeroes, with 49 million users and engineering capacity, ships a player OVR feature in 6 months, eliminating CrickRise's main differentiator before it gets traction.
**The mitigation:** CricHeroes is India-focused and large. Large companies are slow to serve edge cases. The Nepali diaspora in Japan is not their priority. Also: execution speed and community intimacy matter more than features at this stage. CrickRise in Okinawa can give every organizer a personal phone call. CricHeroes cannot. Win on relationship density, not just feature parity.

### Risk 3: Data quality failure destroys trust.
**The danger:** A scorer makes repeated errors that go uncorrected. Player OVRs are wrong. Players argue about their stats. The community loses faith in the data and stops using the platform.
**The mitigation:** Invest disproportionately in scorer UX and correction tools. Run scorer training for the first 5-10 communities personally. Build fraud detection flags. Make the correction flow so easy that organizers will actually use it.

### Risk 4: The OVR becomes a political problem.
**The danger:** A senior player in the community has a lower OVR than expected, feels disrespected, and causes controversy. "The app says Roshan is better than me? This app is broken." This is especially dangerous in tight-knit communities where hierarchy and respect matter.
**The mitigation:** The transparency framework for OVR is essential — show what inputs go in, explain the sample size uncertainty, use the "Developing" label prominently. Also: frame OVR as a current form indicator, not a judgment of worth as a player. The language around OVR matters enormously. "Your form rating" is less politically charged than "your overall rating."

### Risk 5: Monetization failure — nobody pays.
**The danger:** Even engaged players don't pay because they get enough for free or don't see the Pro value.
**The mitigation:** Talk to 20 players before building the paywall. Ask them directly: "What would you pay ¥3,980/year for?" Let their answers shape the Pro feature set. The Pro features must be visibly compelling during the free trial period. If the 14-day trial doesn't convert, redesign the Pro feature set before scaling.

### Risk 6: The founding team burns out before reaching scale.
**The danger:** Running a community sports platform requires constant community management, support, bug fixing, and personal relationships. This is mentally exhausting for a small technical team.
**The mitigation:** Empower organizers to be the first line of support. Build the product so organizers can solve their own problems without contacting you. Limit the initial community to what you can personally support while building the product.

### Risk 7: Regulatory issues in specific markets.
**The danger:** Payment processing in Japan requires specific business registration. App store in-app purchase rules add 15-30% platform fees. Data privacy regulations in the EU (if expanding there) create compliance burden.
**The mitigation:** Use Stripe (available in Japan, handles tax compliance). Use Apple/Google in-app purchases for mobile — accept the 15-30% fee as the cost of distribution. Design for GDPR-compliance from the start (data export, deletion on request). This is cheap to build in correctly and expensive to retrofit.

---

## 25. FINAL PRODUCT POSITIONING

### The Problem We Solve

Every amateur cricket player's career happens and then disappears. There is no record. No proof. No identity. The match where you hit 78 and your team won the league — it exists in someone's memory and maybe a blurry photograph. Nothing else.

CricHeroes captures data but makes you pay to access your own statistics, drowns you in ads, and was built for India, not for you.

### What CrickRise Is

CrickRise is the first platform that treats the amateur cricket player as a professional athlete deserves to be treated — with a permanent, portable career record, a live rating that reflects their actual form, and a profile that grows with them across every team and league they ever play in.

When you play with CrickRise, you are not just scoring a match. You are writing your cricket career.

### Who We Are For

Nepali cricket players abroad. Pakistani communities in Malaysia. Indian communities in Japan. Any cricket-loving community that formed around the sport, plays regularly, and deserves more than a WhatsApp group to track their results.

We start in Okinawa because we can be there. We build for the world because the world is full of people exactly like the players in Okinawa.

---

## 26. FINAL NAME / TAGLINE RECOMMENDATIONS

### The Name: CRICKRISE

Keep it. It is not brilliant but it is not harmful. It has brand energy, the word "rise" resonates with diaspora aspiration, it is memorable, and it is available as a domain. Do not change it unless you have something clearly better.

**One legitimate concern:** "Crick" is a regional term for cricket — it works in cricket communities but may be confusing for Japanese non-cricket players. For the initial target market (Nepali cricket community), this is not a problem.

### The Positioning: "Your Cricket Career."

Keep this. It is direct, true, player-first, and differentiated from every competitor who positions around leagues or scoring. It implies permanence and identity, which is the product's core value proposition.

### Tagline Options

**Original:** "Rise Through the Ranks." — Generic. Every competitive app uses ascent language.

**Proposed alternatives (ranked by quality):**

1. **"Play. Rise. Be Remembered."** — Best option. Captures the full loop (play cricket → improve your OVR → leave a legacy). The word "Remembered" addresses the core emotional need: I want my cricket career to matter.

2. **"Your game. Your legacy."** — Clean, powerful. Works across cultures. The word "legacy" is strong for diaspora communities.

3. **"Cricket never forgets."** — Surprising and specific to the career archive value proposition. May be too abstract.

4. **"Where every ball counts."** — Cricket-specific phrase, speaks to stat tracking value. Good but slightly too literal.

**Recommendation:** Use "Play. Rise. Be Remembered." as the hero tagline. Use "Your Cricket Career." as the positioning statement. Both can coexist.

---

## 27. WHAT I WOULD BUILD IF I WERE THE FOUNDER

If I were the founder with full conviction, here is what I would actually do — with no hedging.

### The Non-Negotiable Decision

I would not call this a Japan product. I would call it a Nepali cricket diaspora product that is **starting in Japan**. This reframing changes everything — the community I partner with, the language I speak to them in, the media I use to reach them, and the fundraising story I tell. "Okinawa to Tokyo to Japan" is a slow growth path. "Every Nepali cricket community in the world" is a market.

### The 12-Month Plan With ¥10 Million

**¥10M ≈ ~$65,000 USD at current rates — this is a seed/friends-and-family budget, not a Series A.**

**Month 1-2: Pre-launch (¥1.5M / ~$10,000)**
- Hire one senior React Native developer (contract, part-time)
- Founder handles product, design, community, backend
- Build the minimum scorer + player profile + OVR reveal loop
- Do not build anything not in the V1 MUST HAVE list
- Weekly sprints, ship a testable version within 6 weeks

**Month 2-3: Okinawa pilot (¥500K / ~$3,300)**
- Fly to Okinawa. Meet every organizer. Identify the best one.
- Set up their league manually if needed — get data into the system
- Attend every match. Sit with the scorer. Fix bugs live.
- After 5 matches per player: facilitate the OVR reveal moment
- Record video reactions. These are the marketing assets.
- Goal: 3 matches scored cleanly, 50+ players with OVR, 5+ players share their card

**Month 3-6: Build what V1 actually needs (¥3M / ~$20,000)**
- Pro subscription launch (Apple/Google IAP + Stripe web)
- Push notifications
- Career history (multi-season)
- Basic milestone system
- Nepali language UI
- Shareable card generation (server-side)
- Fix everything the Okinawa pilot exposed

**Month 6-9: Japan expansion (¥2M / ~$13,000)**
- Target 5 more leagues in Tokyo, Osaka, Fukuoka through direct community outreach
- Partner with existing Nepali cricket associations in Japan
- Goal: 500-1,000 players, first paying Pro users
- Watch the conversion rate obsessively. If below 5%, redesign the Pro offer before continuing.

**Month 9-12: Diaspora outreach (¥2M / ~$13,000)**
- Identify the 2-3 most organized Nepali cricket communities outside Japan (Qatar, Malaysia most likely)
- Offer same hands-on onboarding as Okinawa
- Localize pricing for their market
- Find a community ambassador in each market — a well-respected organizer who champions the platform
- Goal: 2 active leagues outside Japan, 200+ international players

**Remaining ¥1M: Reserve for app store fees, server costs, travel, unexpected costs**

### What I Would Measure Obsessively

1. **Scorer completion rate:** What % of matches started on the scorer app reach a completed result? Target 90%+.
2. **OVR unlock rate:** What % of registered players reach 5 matches and get their OVR? Target 60%+ by end of first season.
3. **OVR card share rate:** What % of players who unlock their OVR share their card? Target 20%+.
4. **30-day retention after OVR unlock:** Target 50%+.
5. **Pro trial conversion:** Target 15%+ of players who start the 14-day free trial.

### What I Would Not Build in Year 1

- Live streaming (too expensive, too distracting)
- A web admin panel with fancy dashboards (basic mobile-first admin is fine)
- AI features of any kind
- Merchandise
- Social feed (not yet — community happens on WhatsApp, let it stay there until you're big enough to compete with WhatsApp)
- Complex achievement systems
- Player search / discovery marketplace

### The Critical Product Belief

**The OVR reveal is the product's most important moment.** Every decision — scorer UX, data quality, anti-gaming, design — should be evaluated by whether it makes the OVR more trustworthy, more exciting, and more worth sharing.

If a player's OVR of 74 means something real to them — if they feel pride when they show it, competitive hunger when they see a rival at 76, and motivation to train when they see their bowling score at 62 — then the product is working.

If the OVR feels random, unfair, or meaningless, the product is dead regardless of how good the scorer UX is.

**Build everything in service of one moment: the moment a Nepali cricketer in Okinawa, Japan looks at their phone and sees their OVR for the first time and says: "That's me."**

---

## FINAL ANSWER: THE ¥10M / 12-MONTH QUESTION

*"If I gave you ¥10 million and 12 months to make CrickRise succeed, exactly what would you build, who would you target first, how would you launch it, and how would you make money?"*

---

**What I would build:**

The absolute minimum product that delivers the OVR reveal experience at the end of a real cricket match, scored in real outdoor conditions by a real person using one hand. That means: jersey-number-first scorer interface, offline scoring, five-match OVR threshold, player profile with BAT/BOWL/FIELD/OVR, and a WhatsApp-shareable card that looks good enough to make someone proud.

Nothing else in V1. Literally nothing else.

**Who I would target first:**

The single best-organized Nepali cricket community leader I can find in Japan — probably in Tokyo but ideally Okinawa for the manageable size. Not because Okinawa is the market, but because if you can make 80 people in Okinawa love your product, you understand exactly what 800,000 people in 40 countries need. Okinawa is the lab. The diaspora is the market.

Simultaneously — and this is crucial — I would be talking to the equivalent organizer in Qatar. Not to launch there immediately, but to have them as an early reference when I expand. The Nepali cricket diaspora is a small world. The Okinawa organizer knows the Doha organizer. Use that.

**How I would launch:**

Not with a Product Hunt post or press coverage. I would launch by sitting next to the scorer at the first match of the Okinawa Nepali Cricket League and making sure every ball was entered correctly. I would be at that match in person.

The real launch happens at match 5, when the first player's OVR unlocks. That is the product launch. I would film it. That video — a real person seeing their cricket OVR for the first time, their reaction, maybe holding their phone up to show their teammates — is the only marketing I need for the next 6 months. Send it to every Nepali cricket community group on Facebook. Post it on the community YouTube channels. Let the community spread it.

**How I would make money:**

Not immediately. In the first 6 months, I would not charge a single yen. I would get to 500 genuinely engaged players with at least 3 complete league seasons recorded. Then I would introduce Player Pro at ¥3,980/year with a 14-day free trial.

My first revenue target is not a number — it is a conversion rate. If 10%+ of engaged players (players with 5+ matches) convert to Pro, the model is working and I can scale confidently. If it's below 5%, I redesign the Pro feature set before touching the growth pedal.

The honest answer is that ¥10 million will not generate ¥10 million in return within 12 months. This is not a 12-month path to revenue — it is a 12-month path to product-market fit with a defined, passionate community. The money story comes when you have 10,000 players in 5 countries and the conversion math starts compounding.

But here is what I believe: **A Nepali cricketer who has played 3 seasons on CrickRise and has 80 matches of verified career history will not leave.** That data is too valuable to them. That career is too real. And once you have the Nepali diaspora cricket community locked in globally, you have the proof to expand to every South Asian cricket community in the world.

The business is not a ¥10 million bet. It is a 5-year bet on becoming the verified cricket identity for 500 million amateur cricketers who are completely invisible to the cricket world right now.

Start in Okinawa. Build for the world.

---

*Document produced: August 2026*
*Authors: CrickRise Founding Product Team*
*Status: Pre-execution strategy — all projections are estimates based on comparable market research and should be validated with primary user research before committing to development*
