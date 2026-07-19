/**
 * StillScout — Award-Winning UI Concept
 *
 * Stack: React 18 · Tailwind CSS · Framer Motion · Lucide React
 *
 * Install:
 *   npm i framer-motion lucide-react
 *   (Tailwind must be configured in your project)
 *
 * Usage: Drop this file into any React + Tailwind project and render <StillScoutApp />.
 */

import React, { useState, useRef, useEffect, useCallback } from "react";
import { motion, AnimatePresence, useSpring, useMotionValue, useTransform } from "framer-motion";
import {
  Crosshair, Sparkles, ChevronRight, Play, Search, Star, Download, Share2,
  Eye, Sun, Frame, Layers, X, Check, ArrowLeft, Zap, Wifi, WifiOff,
  Camera, Film, Image, RotateCcw, BarChart2, Award, Infinity, Clock,
} from "lucide-react";

// ─── Design tokens ────────────────────────────────────────────────────────────

const T = {
  void:   "#050508",
  slate:  "#141418",
  film:   "#1C1C22",
  light:  "#28282F",
  chalk:  "#F5F5F0",
  silver: "#9A9A9F",
  muted:  "#4A4A52",
  accent: "#E8C97A",
  purple: "#B8A4FF",
  green:  "#5CDB95",
  red:    "#FF6B6B",
  glow: (color: string, alpha = 0.25, blur = 24) =>
    `0 0 ${blur}px ${color}${Math.round(alpha * 255).toString(16).padStart(2, "0")}`,
};

// ─── Placeholder data ─────────────────────────────────────────────────────────

type Frame = {
  id: string; score: number; blur: number; lighting: number;
  eyes: number; composition: number; rank: number;
  gradient: string; locked: boolean; summary?: string;
};

const DEMO_FRAMES: Frame[] = [
  { id: "f1", score: 9.2, blur: 94, lighting: 88, eyes: 96, composition: 91, rank: 0, locked: false,
    gradient: "from-amber-900/40 to-stone-900/60",
    summary: "Sharp focus on subject with excellent eye contact and warm, even lighting." },
  { id: "f2", score: 8.7, blur: 91, lighting: 85, eyes: 88, composition: 87, rank: 1, locked: false,
    gradient: "from-slate-800/40 to-zinc-900/60" },
  { id: "f3", score: 8.1, blur: 82, lighting: 90, eyes: 79, composition: 84, rank: 2, locked: false,
    gradient: "from-stone-800/40 to-gray-900/60" },
  { id: "f4", score: 7.6, blur: 78, lighting: 81, eyes: 76, composition: 78, rank: 3, locked: true,
    gradient: "from-zinc-800/40 to-neutral-900/60" },
  { id: "f5", score: 7.2, blur: 74, lighting: 76, eyes: 71, composition: 75, rank: 4, locked: true,
    gradient: "from-gray-800/40 to-slate-900/60" },
  { id: "f6", score: 6.8, blur: 70, lighting: 72, eyes: 68, composition: 71, rank: 5, locked: true,
    gradient: "from-neutral-800/40 to-stone-900/60" },
];

// ─── Utility helpers ──────────────────────────────────────────────────────────

function scoreTier(s: number) {
  if (s >= 8.0) return T.green;
  if (s >= 6.0) return T.accent;
  if (s >= 4.0) return T.silver;
  return T.red;
}

function scoreLabel(s: number) {
  return s >= 10 ? "10" : s.toFixed(1);
}

// ─── Micro-interaction primitives ─────────────────────────────────────────────

function PressScale({ children, scale = 0.96, className = "", onClick }: {
  children: React.ReactNode; scale?: number;
  className?: string; onClick?: () => void;
}) {
  return (
    <motion.div
      className={className}
      whileTap={{ scale }}
      transition={{ type: "spring", stiffness: 600, damping: 30 }}
      onClick={onClick}
    >
      {children}
    </motion.div>
  );
}

function FadeUp({ children, delay = 0, className = "" }: {
  children: React.ReactNode; delay?: number; className?: string;
}) {
  return (
    <motion.div
      className={className}
      initial={{ opacity: 0, y: 16 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -8 }}
      transition={{ type: "spring", stiffness: 300, damping: 28, delay }}
    >
      {children}
    </motion.div>
  );
}

// ─── Score ring ───────────────────────────────────────────────────────────────

function ScoreRing({ score, size = 52, strokeWidth = 3.5 }: {
  score: number; size?: number; strokeWidth?: number;
}) {
  const r = (size - strokeWidth * 2) / 2;
  const circ = 2 * Math.PI * r;
  const progress = useMotionValue(0);
  const dash = useTransform(progress, (v) => `${v * circ} ${circ}`);
  const color = scoreTier(score);
  const fontSize = size <= 40 ? 11 : size <= 56 ? 14 : 20;

  useEffect(() => {
    const ctrl = progress.set(score / 10);
    return ctrl;
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  useEffect(() => {
    const timeout = setTimeout(() => {
      const anim = { from: 0, to: score / 10 };
      let start: number | null = null;
      const duration = 900;
      function step(ts: number) {
        if (!start) start = ts;
        const t = Math.min((ts - start) / duration, 1);
        const ease = 1 - Math.pow(1 - t, 3);
        progress.set(anim.from + (anim.to - anim.from) * ease);
        if (t < 1) requestAnimationFrame(step);
      }
      requestAnimationFrame(step);
    }, 120);
    return () => clearTimeout(timeout);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [score]);

  return (
    <div className="relative flex items-center justify-center" style={{ width: size, height: size }}>
      <svg width={size} height={size} style={{ transform: "rotate(-90deg)" }}>
        <circle cx={size / 2} cy={size / 2} r={r} fill="none"
          stroke={color + "22"} strokeWidth={strokeWidth} />
        <motion.circle
          cx={size / 2} cy={size / 2} r={r} fill="none"
          stroke={color} strokeWidth={strokeWidth}
          strokeLinecap="round"
          strokeDasharray={dash as any}
        />
      </svg>
      <span className="absolute font-black tabular-nums" style={{ color, fontSize }}>
        {scoreLabel(score)}
      </span>
    </div>
  );
}

// ─── Glass card ───────────────────────────────────────────────────────────────

function GlassCard({ children, className = "", glow = false, accent = false }: {
  children: React.ReactNode; className?: string; glow?: boolean; accent?: boolean;
}) {
  return (
    <div
      className={`relative rounded-2xl overflow-hidden ${className}`}
      style={{
        background: "rgba(255,255,255,0.035)",
        backdropFilter: "blur(20px)",
        border: `1px solid ${accent ? T.accent + "50" : "rgba(255,255,255,0.08)"}`,
        boxShadow: glow ? T.glow(T.accent, 0.15, 32) : undefined,
      }}
    >
      {children}
    </div>
  );
}

// ─── Primary button ───────────────────────────────────────────────────────────

function PrimaryButton({ label, icon: Icon, onClick, loading = false, wide = false }: {
  label: string; icon?: React.ElementType;
  onClick?: () => void; loading?: boolean; wide?: boolean;
}) {
  return (
    <PressScale onClick={onClick} className={wide ? "w-full" : undefined}>
      <button
        disabled={loading}
        className={`flex items-center justify-center gap-2 rounded-xl font-semibold text-sm tracking-wide transition-opacity ${wide ? "w-full" : "px-5"}`}
        style={{
          height: 48,
          background: T.accent,
          color: T.void,
          boxShadow: `0 6px 20px ${T.accent}44`,
          minWidth: wide ? undefined : 120,
          paddingLeft: wide ? undefined : 20,
          paddingRight: wide ? undefined : 20,
          opacity: loading ? 0.6 : 1,
        }}
      >
        {loading ? (
          <motion.div
            className="w-4 h-4 rounded-full border-2"
            style={{ borderColor: T.void + "40", borderTopColor: T.void }}
            animate={{ rotate: 360 }}
            transition={{ repeat: Infinity, duration: 0.7, ease: "linear" }}
          />
        ) : (
          <>
            {Icon && <Icon size={16} />}
            <span>{label}</span>
          </>
        )}
      </button>
    </PressScale>
  );
}

function SecondaryButton({ label, icon: Icon, onClick }: {
  label: string; icon?: React.ElementType; onClick?: () => void;
}) {
  return (
    <PressScale onClick={onClick}>
      <button
        className="flex items-center justify-center gap-2 rounded-xl font-medium text-sm px-5"
        style={{
          height: 48,
          color: T.chalk,
          background: "transparent",
          border: `1px solid rgba(255,255,255,0.18)`,
          paddingLeft: 20,
          paddingRight: 20,
        }}
      >
        {Icon && <Icon size={15} style={{ color: T.silver }} />}
        <span>{label}</span>
      </button>
    </PressScale>
  );
}

// ─── Score breakdown modal ────────────────────────────────────────────────────

const SUB_ROWS = [
  { key: "blur",        label: "Sharpness",   icon: Layers },
  { key: "lighting",    label: "Lighting",    icon: Sun },
  { key: "eyes",        label: "Expression",  icon: Eye },
  { key: "composition", label: "Composition", icon: Frame },
] as const;

function BreakdownModal({ frame, onClose }: { frame: Frame; onClose: () => void }) {
  return (
    <motion.div
      className="absolute inset-0 z-50 flex items-end"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="absolute inset-0 bg-black/70 backdrop-blur-sm" onClick={onClose} />
      <motion.div
        className="relative w-full rounded-t-3xl overflow-hidden p-6 pb-8"
        style={{ background: T.slate, border: `1px solid rgba(255,255,255,0.08)`, borderBottom: "none" }}
        initial={{ y: "100%" }}
        animate={{ y: 0 }}
        exit={{ y: "100%" }}
        transition={{ type: "spring", stiffness: 400, damping: 40 }}
      >
        {/* Handle */}
        <div className="w-10 h-1 rounded-full mx-auto mb-6" style={{ background: T.muted }} />

        {/* Header */}
        <div className="flex items-center gap-4 mb-6">
          <ScoreRing score={frame.score} size={56} strokeWidth={4} />
          <div>
            <p className="font-bold text-base" style={{ color: T.chalk }}>Score breakdown</p>
            <p className="text-xs mt-0.5" style={{ color: T.silver }}>On-device ML · Apple Vision</p>
          </div>
        </div>

        {/* Sub-scores */}
        <div className="space-y-4">
          {SUB_ROWS.map(({ key, label, icon: Icon }, i) => {
            const val = frame[key as keyof Frame] as number;
            const color = scoreTier(val / 10);
            return (
              <motion.div
                key={key}
                className="flex items-center gap-3"
                initial={{ opacity: 0, x: -12 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.05 * i, type: "spring", stiffness: 300, damping: 28 }}
              >
                <Icon size={16} style={{ color, flexShrink: 0 }} />
                <span className="w-24 text-sm font-medium" style={{ color: T.chalk }}>{label}</span>
                <div className="flex-1 rounded-full overflow-hidden" style={{ height: 5, background: color + "22" }}>
                  <motion.div
                    className="h-full rounded-full"
                    style={{ background: color }}
                    initial={{ width: "0%" }}
                    animate={{ width: `${val}%` }}
                    transition={{ delay: 0.05 * i + 0.1, duration: 0.7, ease: [0.16, 1, 0.3, 1] }}
                  />
                </div>
                <span className="w-8 text-right text-xs font-bold tabular-nums" style={{ color }}>
                  {(val / 10).toFixed(1)}
                </span>
              </motion.div>
            );
          })}
        </div>

        {/* AI summary */}
        {frame.summary && (
          <motion.div
            className="mt-5 rounded-xl p-4"
            style={{ background: T.accent + "12", border: `1px solid ${T.accent}28` }}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.3 }}
          >
            <div className="flex gap-2">
              <Sparkles size={14} style={{ color: T.accent, flexShrink: 0, marginTop: 1 }} />
              <p className="text-xs leading-relaxed" style={{ color: T.chalk }}>{frame.summary}</p>
            </div>
          </motion.div>
        )}
      </motion.div>
    </motion.div>
  );
}

// ─── Paywall sheet ────────────────────────────────────────────────────────────

const PRO_FEATURES = [
  { icon: Sparkles,  title: "Deeper AI analysis",      sub: "Cloud model picks the single best frame" },
  { icon: Image,     title: "10 Top Picks per scout",  sub: "See all ranked keepers, not just 3" },
  { icon: Infinity,  title: "Unlimited scouts daily",  sub: "No daily cap on free scouting sessions" },
  { icon: Download,  title: "Native 4K saves",         sub: "Full-resolution re-extract from source" },
  { icon: Clock,     title: "Exact timecodes",         sub: "Copy timestamps to find moments in editor" },
];

function PaywallSheet({ onClose, onPurchase }: { onClose: () => void; onPurchase: () => void }) {
  const [yearly, setYearly] = useState(true);
  const [purchasing, setPurchasing] = useState(false);

  const handlePurchase = () => {
    setPurchasing(true);
    setTimeout(() => { setPurchasing(false); onPurchase(); }, 1600);
  };

  return (
    <motion.div
      className="absolute inset-0 z-50 flex items-end"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
    >
      <div className="absolute inset-0 bg-black/75 backdrop-blur-sm" onClick={onClose} />
      <motion.div
        className="relative w-full rounded-t-3xl overflow-hidden"
        style={{ background: T.void, border: `1px solid rgba(255,255,255,0.07)`, borderBottom: "none", maxHeight: "92dvh" }}
        initial={{ y: "100%" }}
        animate={{ y: 0 }}
        exit={{ y: "100%" }}
        transition={{ type: "spring", stiffness: 380, damping: 40 }}
      >
        <div className="overflow-y-auto px-6 pb-10 pt-3">
          {/* Handle */}
          <div className="w-10 h-1 rounded-full mx-auto mb-6" style={{ background: T.muted }} />

          {/* Hero badge */}
          <div className="flex justify-center mb-4">
            <div className="relative w-16 h-16 rounded-full flex items-center justify-center"
              style={{ background: T.accent + "18", border: `1.5px solid ${T.accent}60`, boxShadow: T.glow(T.accent, 0.3, 28) }}>
              <Star size={28} style={{ color: T.accent }} fill={T.accent} />
            </div>
          </div>

          <h2 className="text-3xl font-black text-center tracking-tight mb-1" style={{ color: T.chalk }}>
            StillScout AI Pro
          </h2>
          <p className="text-sm text-center mb-6" style={{ color: T.accent }}>
            AI finds your best moment and turns it into a professional photo.
          </p>

          {/* Features */}
          <div className="rounded-2xl overflow-hidden mb-5" style={{ border: `1px solid rgba(255,255,255,0.07)`, background: T.film }}>
            {PRO_FEATURES.map(({ icon: Icon, title, sub }, i) => (
              <motion.div
                key={title}
                className="flex items-center gap-3 px-4 py-3"
                style={{ borderBottom: i < PRO_FEATURES.length - 1 ? `1px solid rgba(255,255,255,0.05)` : undefined }}
                initial={{ opacity: 0, x: -10 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.04 * i + 0.1 }}
              >
                <div className="w-8 h-8 rounded-lg flex items-center justify-center flex-shrink-0"
                  style={{ background: T.accent + "18" }}>
                  <Icon size={15} style={{ color: T.accent }} />
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-sm font-semibold leading-tight" style={{ color: T.chalk }}>{title}</p>
                  <p className="text-xs mt-0.5" style={{ color: T.silver }}>{sub}</p>
                </div>
                <Check size={14} style={{ color: T.green, flexShrink: 0 }} />
              </motion.div>
            ))}
          </div>

          {/* Plan toggle */}
          <div className="flex rounded-xl overflow-hidden mb-5 p-1" style={{ background: T.film }}>
            {[false, true].map((isYearly) => (
              <PressScale key={String(isYearly)} className="flex-1" onClick={() => setYearly(isYearly)}>
                <div className="relative flex flex-col items-center py-3 rounded-lg transition-colors"
                  style={{ background: yearly === isYearly ? T.accent : "transparent" }}>
                  {isYearly && (
                    <div className="absolute -top-1 left-1/2 -translate-x-1/2">
                      <span className="text-[9px] font-bold px-1.5 py-0.5 rounded-full tracking-widest"
                        style={{ background: T.void, color: T.accent }}>BEST VALUE</span>
                    </div>
                  )}
                  <p className="text-xs font-semibold mt-1"
                    style={{ color: yearly === isYearly ? T.void : T.chalk }}>
                    {isYearly ? "Yearly" : "Monthly"}
                  </p>
                  <p className="text-sm font-black tabular-nums"
                    style={{ color: yearly === isYearly ? T.void : T.chalk }}>
                    {isYearly ? "$39.99/yr" : "$4.99/mo"}
                  </p>
                  {isYearly && (
                    <p className="text-[10px]" style={{ color: yearly ? T.void + "99" : T.silver }}>
                      $3.33 / month
                    </p>
                  )}
                </div>
              </PressScale>
            ))}
          </div>

          {/* CTA */}
          <PressScale onClick={handlePurchase} className="w-full">
            <button className="w-full rounded-xl h-14 flex items-center justify-center gap-2 font-bold text-base"
              style={{ background: T.accent, color: T.void, boxShadow: `0 8px 24px ${T.accent}44` }}>
              {purchasing ? (
                <motion.div className="w-5 h-5 rounded-full border-2"
                  style={{ borderColor: T.void + "40", borderTopColor: T.void }}
                  animate={{ rotate: 360 }}
                  transition={{ repeat: Infinity, duration: 0.7, ease: "linear" }} />
              ) : (
                <>
                  <Zap size={18} />
                  <span>Start Pro · {yearly ? "$39.99/yr" : "$4.99/mo"}</span>
                </>
              )}
            </button>
          </PressScale>

          <p className="text-center text-[10px] mt-3" style={{ color: T.muted }}>
            Cancel anytime in Settings → Apple ID → Subscriptions
          </p>
        </div>
      </motion.div>
    </motion.div>
  );
}

// ─── Empty / home state ───────────────────────────────────────────────────────

const TIPS = [
  "Ranked stills. Instant offline.",
  "Apple Vision scores every frame.",
  "6 free scouts per day.",
  "4K exports with AI Pro.",
];

function HomeScreen({ onPickVideo }: { onPickVideo: () => void }) {
  const [tipIdx, setTipIdx] = useState(0);

  useEffect(() => {
    const t = setInterval(() => setTipIdx((i) => (i + 1) % TIPS.length), 2800);
    return () => clearInterval(t);
  }, []);

  return (
    <FadeUp className="flex flex-col h-full">
      {/* Hero area */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 gap-6">
        {/* Animated logo mark */}
        <div className="relative">
          <motion.div
            className="w-24 h-24 rounded-3xl flex items-center justify-center"
            style={{ background: T.film, border: `1.5px solid ${T.accent}40`, boxShadow: T.glow(T.accent, 0.2, 32) }}
            animate={{ boxShadow: [T.glow(T.accent, 0.15, 24), T.glow(T.accent, 0.30, 40), T.glow(T.accent, 0.15, 24)] }}
            transition={{ repeat: Infinity, duration: 3, ease: "easeInOut" }}
          >
            <Crosshair size={40} style={{ color: T.accent }} />
          </motion.div>
          {/* Orbit dot */}
          <motion.div
            className="absolute w-2.5 h-2.5 rounded-full"
            style={{ background: T.accent, top: 4, right: -2, boxShadow: T.glow(T.accent, 0.6, 8) }}
            animate={{ scale: [1, 1.4, 1], opacity: [1, 0.6, 1] }}
            transition={{ repeat: Infinity, duration: 2.2, ease: "easeInOut" }}
          />
        </div>

        {/* Headline */}
        <div className="text-center space-y-2">
          <h1 className="text-4xl font-black tracking-tighter leading-none" style={{ color: T.chalk }}>
            Still.<br />
            <span style={{ color: T.accent }}>Scout.</span><br />
            Post.
          </h1>
          {/* Rotating tip */}
          <div className="h-5 overflow-hidden">
            <AnimatePresence mode="wait">
              <motion.p
                key={tipIdx}
                className="text-sm"
                style={{ color: T.silver }}
                initial={{ y: 12, opacity: 0 }}
                animate={{ y: 0, opacity: 1 }}
                exit={{ y: -12, opacity: 0 }}
                transition={{ duration: 0.3 }}
              >
                {TIPS[tipIdx]}
              </motion.p>
            </AnimatePresence>
          </div>
        </div>

        {/* Source cards */}
        <div className="w-full grid grid-cols-2 gap-3">
          {[
            { icon: Camera, label: "Camera", sub: "Record now", accent: T.purple },
            { icon: Film,   label: "Library", sub: "Pick a video", accent: T.accent },
          ].map(({ icon: Icon, label, sub, accent }) => (
            <PressScale key={label} onClick={onPickVideo}>
              <GlassCard className="p-4 cursor-pointer active:scale-95">
                <div className="w-10 h-10 rounded-xl flex items-center justify-center mb-3"
                  style={{ background: accent + "1A" }}>
                  <Icon size={20} style={{ color: accent }} />
                </div>
                <p className="font-semibold text-sm" style={{ color: T.chalk }}>{label}</p>
                <p className="text-xs mt-0.5" style={{ color: T.silver }}>{sub}</p>
              </GlassCard>
            </PressScale>
          ))}
        </div>
      </div>

      {/* Bottom stats strip */}
      <div className="px-5 pb-6">
        <GlassCard className="px-5 py-3">
          <div className="flex justify-between items-center">
            {[
              { val: "6", label: "scouts today" },
              { val: "On-device", label: "ML scoring" },
              { val: "Free", label: "offline use" },
            ].map(({ val, label }) => (
              <div key={label} className="text-center">
                <p className="text-sm font-bold" style={{ color: T.accent }}>{val}</p>
                <p className="text-[10px] mt-0.5" style={{ color: T.muted }}>{label}</p>
              </div>
            ))}
          </div>
        </GlassCard>
      </div>
    </FadeUp>
  );
}

// ─── Pre-flight screen ────────────────────────────────────────────────────────

const CONTEXTS = [
  { id: "auto",      label: "Auto",      icon: Sparkles },
  { id: "portrait",  label: "Portrait",  icon: Eye },
  { id: "action",    label: "Action",    icon: Zap },
  { id: "landscape", label: "Landscape", icon: Image },
] as const;

function PreFlightScreen({ onStart }: { onStart: () => void }) {
  const [ctx, setCtx] = useState<string>("auto");

  return (
    <FadeUp className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto px-5 py-4 space-y-4">
        {/* Video ready card */}
        <GlassCard className="p-5" glow>
          <div className="flex items-center gap-4">
            <div className="w-16 h-16 rounded-xl flex items-center justify-center flex-shrink-0"
              style={{ background: T.green + "18", border: `1px solid ${T.green}40` }}>
              <Check size={28} style={{ color: T.green }} />
            </div>
            <div>
              <p className="font-bold text-base" style={{ color: T.chalk }}>Video ready</p>
              <p className="text-xs mt-0.5" style={{ color: T.silver }}>birthday_clip.mov · 1:42</p>
              <p className="text-xs mt-1" style={{ color: T.silver }}>~102 frames to rank</p>
            </div>
          </div>
        </GlassCard>

        {/* Context picker */}
        <div>
          <p className="text-xs font-semibold mb-2 px-1" style={{ color: T.silver, letterSpacing: "0.08em" }}>
            WHAT'S THIS VIDEO?
          </p>
          <div className="grid grid-cols-4 gap-2">
            {CONTEXTS.map(({ id, label, icon: Icon }) => {
              const active = ctx === id;
              return (
                <PressScale key={id} onClick={() => setCtx(id)}>
                  <div className="flex flex-col items-center gap-1.5 py-3 rounded-xl transition-all"
                    style={{
                      background: active ? T.accent + "1A" : T.film,
                      border: `1px solid ${active ? T.accent + "60" : "rgba(255,255,255,0.06)"}`,
                    }}>
                    <Icon size={16} style={{ color: active ? T.accent : T.silver }} />
                    <span className="text-[10px] font-medium" style={{ color: active ? T.accent : T.silver }}>
                      {label}
                    </span>
                  </div>
                </PressScale>
              );
            })}
          </div>
        </div>

        {/* Quota display */}
        <GlassCard className="px-4 py-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <Wifi size={14} style={{ color: T.green }} />
              <span className="text-xs" style={{ color: T.chalk }}>Free · On-device AI</span>
            </div>
            <span className="text-xs font-semibold" style={{ color: T.accent }}>5 scouts left today</span>
          </div>
        </GlassCard>
      </div>

      {/* CTA */}
      <div className="px-5 pb-6 space-y-3 pt-2">
        <PressScale onClick={onStart} className="w-full">
          <button className="w-full h-14 rounded-2xl flex items-center justify-center gap-2 font-bold text-base"
            style={{ background: T.accent, color: T.void, boxShadow: `0 8px 28px ${T.accent}44` }}>
            <Search size={18} />
            Start Scout
          </button>
        </PressScale>
        <SecondaryButton label="Pick a different video" icon={RotateCcw} />
      </div>
    </FadeUp>
  );
}

// ─── Processing screen ────────────────────────────────────────────────────────

function ProcessingScreen({ onDone }: { onDone: () => void }) {
  const [progress, setProgress] = useState(0);
  const [phase, setPhase] = useState<"extracting" | "scoring">("extracting");
  const [liveCount, setLiveCount] = useState(0);

  useEffect(() => {
    let p = 0;
    const interval = setInterval(() => {
      p += Math.random() * 4 + 1;
      if (p >= 50 && phase === "extracting") setPhase("scoring");
      if (p >= 100) { clearInterval(interval); p = 100; setTimeout(onDone, 400); }
      setProgress(Math.min(p, 100));
      setLiveCount((c) => Math.min(c + Math.floor(Math.random() * 2), 12));
    }, 180);
    return () => clearInterval(interval);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const GRADIENTS = [
    "from-amber-800 to-orange-900", "from-slate-700 to-gray-900",
    "from-stone-700 to-zinc-900", "from-neutral-700 to-stone-900",
    "from-zinc-700 to-slate-900", "from-gray-700 to-neutral-900",
  ];

  return (
    <FadeUp className="flex flex-col h-full items-center justify-center px-6 gap-8">
      {/* Pulsing ring */}
      <div className="relative">
        <motion.div
          className="w-28 h-28 rounded-full"
          style={{ border: `2px solid ${T.accent}40` }}
          animate={{ scale: [1, 1.12, 1], opacity: [0.4, 0.8, 0.4] }}
          transition={{ repeat: Infinity, duration: 2, ease: "easeInOut" }}
        />
        <div className="absolute inset-0 flex items-center justify-center">
          <div className="w-20 h-20 rounded-full flex items-center justify-center"
            style={{ background: T.film, border: `1.5px solid ${T.accent}50`, boxShadow: T.glow(T.accent, 0.25, 24) }}>
            <Crosshair size={28} style={{ color: T.accent }} />
          </div>
        </div>
      </div>

      {/* Labels */}
      <div className="text-center space-y-1">
        <AnimatePresence mode="wait">
          <motion.p
            key={phase}
            className="font-bold text-lg" style={{ color: T.chalk }}
            initial={{ opacity: 0, y: 8 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0, y: -8 }}
          >
            {phase === "extracting" ? "Extracting frames…" : "Ranking with AI…"}
          </motion.p>
        </AnimatePresence>
        <p className="text-sm" style={{ color: T.silver }}>
          {liveCount > 0 ? `${liveCount} frames analysed` : "Scanning video…"}
        </p>
      </div>

      {/* Progress bar */}
      <div className="w-full">
        <div className="flex justify-between text-xs mb-1.5" style={{ color: T.silver }}>
          <span>{Math.round(progress)}%</span>
          <span>{phase === "extracting" ? "Frame extraction" : "AI scoring"}</span>
        </div>
        <div className="w-full h-1.5 rounded-full overflow-hidden" style={{ background: T.light }}>
          <motion.div
            className="h-full rounded-full"
            style={{ background: `linear-gradient(90deg, ${T.accent}, ${T.accent}BB)` }}
            animate={{ width: `${progress}%` }}
            transition={{ ease: "easeOut" }}
          />
        </div>
      </div>

      {/* Live strip */}
      {liveCount > 0 && (
        <div className="w-full overflow-hidden">
          <p className="text-[10px] mb-2 font-semibold tracking-wider" style={{ color: T.muted }}>LIVE FRAMES</p>
          <div className="flex gap-2">
            {Array.from({ length: Math.min(liveCount, 5) }).map((_, i) => (
              <motion.div
                key={i}
                className={`flex-1 rounded-lg bg-gradient-to-br ${GRADIENTS[i % GRADIENTS.length]}`}
                style={{ height: 52, border: "1px solid rgba(255,255,255,0.07)" }}
                initial={{ opacity: 0, scale: 0.85 }}
                animate={{ opacity: 1, scale: 1 }}
                transition={{ type: "spring", stiffness: 400, damping: 28 }}
              />
            ))}
          </div>
        </div>
      )}

      {/* Cancel */}
      <button className="text-sm mt-2" style={{ color: T.silver }}>Cancel scout</button>
    </FadeUp>
  );
}

// ─── Results gallery ──────────────────────────────────────────────────────────

function ResultsGallery({ onUpgrade, onBack }: { onUpgrade: () => void; onBack: () => void }) {
  const [breakdown, setBreakdown] = useState<Frame | null>(null);

  return (
    <div className="flex flex-col h-full relative">
      {/* Completion hero */}
      <FadeUp className="px-4 pt-2 pb-3">
        <GlassCard className="p-4" glow accent>
          <div className="flex items-center gap-3">
            {/* Pulsing gold badge */}
            <motion.div
              className="w-14 h-14 rounded-full flex items-center justify-center flex-shrink-0"
              style={{ background: T.accent + "18", border: `2px solid ${T.accent}80` }}
              animate={{ boxShadow: [T.glow(T.accent, 0.2, 16), T.glow(T.accent, 0.45, 28), T.glow(T.accent, 0.2, 16)] }}
              transition={{ repeat: Infinity, duration: 2.4, ease: "easeInOut" }}
            >
              <span className="text-xl font-black tabular-nums" style={{ color: T.accent }}>
                {scoreLabel(DEMO_FRAMES[0].score)}
              </span>
            </motion.div>
            <div className="flex-1">
              <p className="font-bold text-sm" style={{ color: T.accent }}>Scout complete</p>
              <p className="text-xs mt-0.5" style={{ color: T.chalk }}>3 saves left this scout</p>
              <p className="text-[10px] mt-0.5" style={{ color: T.silver }}>
                102 frames ranked instantly · upgrade for AI Pro
              </p>
            </div>
            <Sparkles size={18} style={{ color: T.accent, opacity: 0.8 }} />
          </div>
        </GlassCard>
      </FadeUp>

      {/* Top picks carousel */}
      <div className="px-4 mb-4">
        <p className="text-[10px] font-bold tracking-widest mb-3" style={{ color: T.muted }}>
          TOP PICKS
        </p>
        <div className="flex gap-3 overflow-x-auto pb-1 no-scrollbar">
          {DEMO_FRAMES.slice(0, 3).map((frame, i) => (
            <motion.div
              key={frame.id}
              className="flex-shrink-0 relative rounded-2xl overflow-hidden cursor-pointer"
              style={{
                width: i === 0 ? 180 : 130,
                height: i === 0 ? 220 : 158,
                border: i === 0 ? `1.5px solid ${T.accent}60` : "1px solid rgba(255,255,255,0.08)",
                boxShadow: i === 0 ? T.glow(T.accent, 0.2, 24) : undefined,
              }}
              initial={{ opacity: 0, scale: 0.9, y: 12 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              transition={{ delay: 0.06 * i, type: "spring", stiffness: 300, damping: 26 }}
              whileTap={{ scale: 0.97 }}
              onClick={() => !frame.locked && setBreakdown(frame)}
            >
              <div className={`w-full h-full bg-gradient-to-br ${frame.gradient}`} />
              {i === 0 && (
                <div className="absolute top-2 left-2">
                  <div className="flex items-center gap-1 px-1.5 py-0.5 rounded-full"
                    style={{ background: T.accent + "22", border: `1px solid ${T.accent}50` }}>
                    <Award size={9} style={{ color: T.accent }} />
                    <span className="text-[9px] font-bold tracking-wide" style={{ color: T.accent }}>TOP PICK</span>
                  </div>
                </div>
              )}
              <div className="absolute bottom-2 right-2">
                <ScoreRing score={frame.score} size={i === 0 ? 44 : 36} strokeWidth={3} />
              </div>
            </motion.div>
          ))}
        </div>
      </div>

      {/* All frames grid */}
      <div className="flex-1 overflow-y-auto px-4">
        <p className="text-[10px] font-bold tracking-widest mb-3" style={{ color: T.muted }}>
          ALL FRAMES
        </p>
        <div className="grid grid-cols-3 gap-2 pb-6">
          {DEMO_FRAMES.map((frame, i) => (
            <motion.div
              key={frame.id}
              className="relative rounded-xl overflow-hidden aspect-[3/4] cursor-pointer"
              style={{
                border: "1px solid rgba(255,255,255,0.07)",
                filter: frame.locked ? "blur(3px)" : undefined,
              }}
              initial={{ opacity: 0, scale: 0.85 }}
              animate={{ opacity: 1, scale: 1 }}
              transition={{ delay: 0.04 * i, type: "spring", stiffness: 320, damping: 28 }}
              whileTap={{ scale: 0.96 }}
              onClick={() => frame.locked ? onUpgrade() : setBreakdown(frame)}
            >
              <div className={`w-full h-full bg-gradient-to-br ${frame.gradient}`} />
              {frame.locked && (
                <div className="absolute inset-0 flex items-center justify-center"
                  style={{ background: "rgba(0,0,0,0.55)", backdropFilter: "blur(2px)" }}>
                  <div className="text-center">
                    <div className="w-7 h-7 rounded-full flex items-center justify-center mx-auto mb-1"
                      style={{ background: T.accent + "22", border: `1px solid ${T.accent}60` }}>
                      <Star size={12} style={{ color: T.accent }} />
                    </div>
                    <p className="text-[9px] font-bold" style={{ color: T.accent }}>PRO</p>
                  </div>
                </div>
              )}
              {!frame.locked && (
                <div className="absolute bottom-1.5 right-1.5">
                  <ScoreRing score={frame.score} size={32} strokeWidth={2.5} />
                </div>
              )}
            </motion.div>
          ))}
        </div>
      </div>

      {/* Export bar */}
      <div className="px-4 pb-5 pt-2" style={{ borderTop: "1px solid rgba(255,255,255,0.07)" }}>
        <div className="flex gap-2">
          <PressScale className="flex-1" onClick={onUpgrade}>
            <button className="w-full h-12 rounded-xl flex items-center justify-center gap-2 font-semibold text-sm"
              style={{ background: T.accent + "18", border: `1px solid ${T.accent}50`, color: T.accent }}>
              <Download size={15} />
              Save
            </button>
          </PressScale>
          <PressScale className="flex-1" onClick={onUpgrade}>
            <button className="w-full h-12 rounded-xl flex items-center justify-center gap-2 font-semibold text-sm"
              style={{ background: T.film, border: "1px solid rgba(255,255,255,0.1)", color: T.chalk }}>
              <Share2 size={15} />
              Share
            </button>
          </PressScale>
          <PressScale onClick={onUpgrade}>
            <button className="h-12 px-4 rounded-xl flex items-center justify-center gap-1.5 font-bold text-sm"
              style={{ background: T.accent, color: T.void, boxShadow: T.glow(T.accent, 0.3, 16) }}>
              <Star size={14} />
              Pro
            </button>
          </PressScale>
        </div>
      </div>

      {/* Breakdown modal */}
      <AnimatePresence>
        {breakdown && <BreakdownModal frame={breakdown} onClose={() => setBreakdown(null)} />}
      </AnimatePresence>
    </div>
  );
}

// ─── Navigation bar ───────────────────────────────────────────────────────────

type Screen = "home" | "preflight" | "processing" | "results";

function TopBar({ screen, onBack }: { screen: Screen; onBack?: () => void }) {
  const showBack = screen !== "home";
  return (
    <div className="flex items-center px-4 pt-3 pb-2 flex-shrink-0"
      style={{ borderBottom: "1px solid rgba(255,255,255,0.05)" }}>
      <div className="w-8">
        <AnimatePresence>
          {showBack && (
            <motion.button
              initial={{ opacity: 0, x: -8 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -8 }}
              onClick={onBack}
            >
              <ArrowLeft size={20} style={{ color: T.silver }} />
            </motion.button>
          )}
        </AnimatePresence>
      </div>
      <div className="flex-1 flex items-center justify-center gap-2">
        <div className="w-5 h-5 rounded-md flex items-center justify-center"
          style={{ background: T.accent + "22", border: `1px solid ${T.accent}50` }}>
          <Crosshair size={11} style={{ color: T.accent }} />
        </div>
        <span className="text-sm font-black tracking-[0.2em]" style={{ color: T.chalk }}>STILLSCOUT</span>
      </div>
      <div className="w-8 flex justify-end">
        <button><BarChart2 size={18} style={{ color: T.silver }} /></button>
      </div>
    </div>
  );
}

// ─── Root app ─────────────────────────────────────────────────────────────────

export default function StillScoutApp() {
  const [screen, setScreen] = useState<Screen>("home");
  const [showPaywall, setShowPaywall] = useState(false);
  const [isPro, setIsPro] = useState(false);

  const handlePurchase = useCallback(() => {
    setIsPro(true);
    setShowPaywall(false);
  }, []);

  return (
    <div
      className="flex items-center justify-center min-h-screen"
      style={{ background: "#0A0A0E", fontFamily: "'Inter', 'SF Pro Display', system-ui, sans-serif" }}
    >
      {/* Phone shell */}
      <div
        className="relative overflow-hidden flex flex-col"
        style={{
          width: 390,
          height: 844,
          background: T.void,
          borderRadius: 44,
          border: "1px solid rgba(255,255,255,0.08)",
          boxShadow: "0 40px 120px rgba(0,0,0,0.8), 0 0 0 1px rgba(255,255,255,0.04) inset",
        }}
      >
        {/* Status bar */}
        <div className="flex items-center justify-between px-7 pt-3 pb-1 flex-shrink-0">
          <span className="text-xs font-semibold" style={{ color: T.chalk }}>9:41</span>
          <div className="w-28 h-7 rounded-full" style={{ background: T.void }} /> {/* notch */}
          <div className="flex items-center gap-1">
            <Wifi size={12} style={{ color: T.chalk }} />
            <span className="text-xs font-semibold" style={{ color: T.chalk }}>100%</span>
          </div>
        </div>

        {/* Navigation */}
        <TopBar
          screen={screen}
          onBack={() => {
            if (screen === "results") setScreen("preflight");
            else if (screen === "preflight" || screen === "processing") setScreen("home");
          }}
        />

        {/* Screen body */}
        <div className="flex-1 overflow-hidden relative">
          <AnimatePresence mode="wait">
            {screen === "home" && (
              <motion.div key="home" className="absolute inset-0"
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.22 }}>
                <HomeScreen onPickVideo={() => setScreen("preflight")} />
              </motion.div>
            )}
            {screen === "preflight" && (
              <motion.div key="preflight" className="absolute inset-0"
                initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }}
                transition={{ duration: 0.22 }}>
                <PreFlightScreen onStart={() => setScreen("processing")} />
              </motion.div>
            )}
            {screen === "processing" && (
              <motion.div key="processing" className="absolute inset-0"
                initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }}
                transition={{ duration: 0.22 }}>
                <ProcessingScreen onDone={() => setScreen("results")} />
              </motion.div>
            )}
            {screen === "results" && (
              <motion.div key="results" className="absolute inset-0"
                initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} exit={{ opacity: 0 }}
                transition={{ duration: 0.28 }}>
                <ResultsGallery
                  onUpgrade={() => setShowPaywall(true)}
                  onBack={() => setScreen("preflight")}
                />
              </motion.div>
            )}
          </AnimatePresence>

          {/* Paywall overlay */}
          <AnimatePresence>
            {showPaywall && (
              <PaywallSheet onClose={() => setShowPaywall(false)} onPurchase={handlePurchase} />
            )}
          </AnimatePresence>
        </div>

        {/* Home indicator */}
        <div className="flex justify-center pb-2 pt-1 flex-shrink-0">
          <div className="w-32 h-1 rounded-full" style={{ background: "rgba(255,255,255,0.2)" }} />
        </div>
      </div>

      {/* Screen labels — outside phone */}
      <div className="absolute bottom-6 left-1/2 -translate-x-1/2 flex gap-2">
        {(["home", "preflight", "processing", "results"] as Screen[]).map((s) => (
          <PressScale key={s} onClick={() => setScreen(s)}>
            <div className="px-3 py-1.5 rounded-full cursor-pointer transition-colors text-xs font-medium"
              style={{
                background: screen === s ? T.accent : "rgba(255,255,255,0.06)",
                color: screen === s ? T.void : T.silver,
                border: "1px solid rgba(255,255,255,0.08)",
              }}>
              {s}
            </div>
          </PressScale>
        ))}
      </div>
    </div>
  );
}
