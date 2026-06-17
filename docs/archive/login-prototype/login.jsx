// Inspectley login screen — iOS 17 style, Hebrew RTL, LTR email field
const { useState, useEffect, useRef } = React;

// ─── Logo mark ────────────────────────────────────────────────────────────
// Original geometric mark: a blueprint-style "checkmark in a chamfered square"
// evoking inspection + approval. Not a copy of any real brand.
function InspectleyMark({ size = 64, accent = '#2F6FE5' }) {
  const s = size;
  return (
    <svg width={s} height={s} viewBox="0 0 64 64" fill="none" aria-hidden>
      <defs>
        <linearGradient id="mk-bg" x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={accent} stopOpacity="1" />
          <stop offset="1" stopColor={accent} stopOpacity="0.82" />
        </linearGradient>
      </defs>
      {/* chamfered square */}
      <path
        d="M14 6 H50 L58 14 V50 L50 58 H14 L6 50 V14 Z"
        fill="url(#mk-bg)" />
      
      {/* inner rule line */}
      <path d="M14 44 H50" stroke="rgba(255,255,255,0.35)" strokeWidth="1" />
      {/* small tick marks (ruler feel) */}
      <g stroke="rgba(255,255,255,0.5)" strokeWidth="1" strokeLinecap="round">
        <line x1="20" y1="44" x2="20" y2="48" />
        <line x1="26" y1="44" x2="26" y2="47" />
        <line x1="32" y1="44" x2="32" y2="48" />
        <line x1="38" y1="44" x2="38" y2="47" />
        <line x1="44" y1="44" x2="44" y2="48" />
      </g>
      {/* checkmark */}
      <path
        d="M19 32 L28 40 L46 22"
        stroke="#ffffff"
        strokeWidth="4.5"
        strokeLinecap="round"
        strokeLinejoin="round"
        fill="none" />
      
    </svg>);

}

// ─── Field ────────────────────────────────────────────────────────────────
function Field({
  label, value, onChange, type = 'text', placeholder, ltr = false,
  icon, error, autoComplete, focused, onFocus, onBlur, onKeyDown
}) {
  const borderColor = error ?
  '#E5484D' :
  focused ?
  'rgba(47,111,229,0.55)' :
  'rgba(60,60,67,0.18)';
  const shadow = focused ?
  '0 0 0 4px rgba(47,111,229,0.12)' :
  'none';

  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
      <label
        style={{
          fontSize: 13,
          fontWeight: 500,
          color: '#6B7280',
          letterSpacing: 0.1,
          paddingInline: 4
        }}>
        
        {label}
      </label>
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 10,
          height: 52,
          padding: '0 14px',
          borderRadius: 14,
          background: '#FFFFFF',
          border: `1px solid ${borderColor}`,
          boxShadow: shadow,
          transition: 'border-color 120ms ease, box-shadow 120ms ease',
          direction: ltr ? 'ltr' : 'rtl'
        }}>
        
        {icon &&
        <span style={{ color: focused ? '#2F6FE5' : '#9CA3AF', display: 'flex', flexShrink: 0 }}>
            {icon}
          </span>
        }
        <input
          type={type}
          value={value}
          onChange={(e) => onChange(e.target.value)}
          onFocus={onFocus}
          onBlur={onBlur}
          onKeyDown={onKeyDown}
          placeholder={placeholder}
          autoComplete={autoComplete}
          dir={ltr ? 'ltr' : 'rtl'}
          style={{
            flex: 1,
            minWidth: 0,
            border: 'none',
            outline: 'none',
            background: 'transparent',
            fontSize: 17,
            lineHeight: '22px',
            color: '#111827',
            fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
            textAlign: ltr ? 'left' : 'right'
          }} />
        
      </div>
    </div>);

}

// ─── Icons (hairline, SF-style) ───────────────────────────────────────────
const MailIcon = () =>
<svg width="18" height="18" viewBox="0 0 20 20" fill="none">
    <rect x="2.5" y="4.5" width="15" height="11" rx="2.5" stroke="currentColor" strokeWidth="1.5" />
    <path d="M3 6 L10 11 L17 6" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" strokeLinejoin="round" />
  </svg>;

const LockIcon = () =>
<svg width="18" height="18" viewBox="0 0 20 20" fill="none">
    <rect x="3.5" y="9" width="13" height="8.5" rx="2.5" stroke="currentColor" strokeWidth="1.5" />
    <path d="M6.5 9 V6.5 a3.5 3.5 0 0 1 7 0 V9" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
  </svg>;

const EyeIcon = ({ off }) =>
<svg width="18" height="18" viewBox="0 0 20 20" fill="none">
    <path d="M2 10 C4 6 6.8 4.5 10 4.5 C13.2 4.5 16 6 18 10 C16 14 13.2 15.5 10 15.5 C6.8 15.5 4 14 2 10 Z"
  stroke="currentColor" strokeWidth="1.5" strokeLinejoin="round" />
    <circle cx="10" cy="10" r="2.5" stroke="currentColor" strokeWidth="1.5" />
    {off && <line x1="3" y1="3" x2="17" y2="17" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />}
  </svg>;

const AlertIcon = () =>
<svg width="16" height="16" viewBox="0 0 16 16" fill="none">
    <circle cx="8" cy="8" r="7" stroke="#E5484D" strokeWidth="1.4" />
    <line x1="8" y1="4.5" x2="8" y2="9" stroke="#E5484D" strokeWidth="1.5" strokeLinecap="round" />
    <circle cx="8" cy="11.5" r="0.9" fill="#E5484D" />
  </svg>;


// ─── Primary button ───────────────────────────────────────────────────────
function PrimaryButton({ children, onClick, loading, disabled, accent }) {
  const [pressed, setPressed] = useState(false);
  const inactive = disabled || loading;
  return (
    <button
      onClick={onClick}
      disabled={inactive}
      onPointerDown={() => setPressed(true)}
      onPointerUp={() => setPressed(false)}
      onPointerLeave={() => setPressed(false)}
      style={{
        width: '100%',
        height: 54,
        borderRadius: 14,
        border: 'none',
        background: inactive ? '#C8D3E8' : accent,
        color: '#ffffff',
        fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
        fontSize: 17,
        fontWeight: 600,
        letterSpacing: 0.1,
        cursor: inactive ? 'default' : 'pointer',
        boxShadow: inactive ?
        'none' :
        pressed ?
        `0 1px 2px ${hexA(accent, 0.25)}` :
        `0 4px 14px ${hexA(accent, 0.32)}, 0 1px 2px ${hexA(accent, 0.2)}`,
        transform: pressed && !inactive ? 'translateY(1px) scale(0.995)' : 'none',
        transition: 'transform 80ms ease, box-shadow 120ms ease, background 120ms ease',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 10
      }}>
      
      {loading ? <Spinner /> : children}
    </button>);

}

function Spinner() {
  return (
    <div
      style={{
        width: 20, height: 20, borderRadius: '50%',
        border: '2.2px solid rgba(255,255,255,0.35)',
        borderTopColor: '#ffffff',
        animation: 'ispin 0.8s linear infinite'
      }} />);


}

// hex with alpha
function hexA(hex, a) {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r},${g},${b},${a})`;
}

// ─── Backdrop (subtle construction pattern) ───────────────────────────────
function Backdrop({ variant, accent }) {
  if (variant === 'none') return null;
  if (variant === 'blueprint') {
    return (
      <svg
        width="100%" height="100%"
        style={{ position: 'absolute', inset: 0, zIndex: 0, opacity: 0.5 }}
        aria-hidden>
        
        <defs>
          <pattern id="grid" x="0" y="0" width="28" height="28" patternUnits="userSpaceOnUse">
            <path d="M28 0 H0 V28" stroke="rgba(17,24,39,0.045)" strokeWidth="1" fill="none" />
          </pattern>
          <radialGradient id="fade" cx="50%" cy="20%" r="70%">
            <stop offset="0%" stopColor="#fff" stopOpacity="0" />
            <stop offset="100%" stopColor="#fff" stopOpacity="1" />
          </radialGradient>
        </defs>
        <rect width="100%" height="100%" fill="url(#grid)" />
        <rect width="100%" height="100%" fill="url(#fade)" />
      </svg>);

  }
  if (variant === 'glow') {
    return (
      <div
        style={{
          position: 'absolute', inset: 0, zIndex: 0, pointerEvents: 'none',
          background: `radial-gradient(90% 55% at 50% 8%, ${hexA(accent, 0.10)} 0%, rgba(255,255,255,0) 60%)`
        }} />);


  }
  return null;
}

// ─── Main screen ──────────────────────────────────────────────────────────
function LoginScreen({ tweaks }) {
  const accent = tweaks.accent === 'orange' ? '#E8702A' : '#2F6FE5';
  const [email, setEmail] = useState(tweaks.prefill ? 'avishai@iter.co.il' : '');
  const [password, setPassword] = useState(tweaks.prefill ? '••••••••' : '');
  const [showPwd, setShowPwd] = useState(false);
  const [focused, setFocused] = useState(null);
  const [loading, setLoading] = useState(tweaks.state === 'loading');
  const [errorMsg, setErrorMsg] = useState(
    tweaks.state === 'error' ? 'אימייל או סיסמה שגויים. אנא נסה שוב.' : ''
  );

  useEffect(() => {
    setLoading(tweaks.state === 'loading');
    setErrorMsg(tweaks.state === 'error' ? 'אימייל או סיסמה שגויים. אנא נסה שוב.' : '');
  }, [tweaks.state]);

  useEffect(() => {
    if (tweaks.prefill) {
      setEmail('avishai@iter.co.il');
      setPassword('••••••••');
    }
  }, [tweaks.prefill]);

  const canSubmit = email.trim().length > 0 && password.length > 0 && !loading;

  function handleSubmit() {
    if (!canSubmit) return;
    setErrorMsg('');
    setLoading(true);
    setTimeout(() => {
      setLoading(false);
      if (!email.includes('@')) {
        setErrorMsg('כתובת האימייל אינה תקינה.');
      } else if (password.length < 4) {
        setErrorMsg('אימייל או סיסמה שגויים. אנא נסה שוב.');
      } else {
        setErrorMsg('');
      }
    }, 1400);
  }

  return (
    <div
      data-screen-label="Login"
      style={{
        position: 'relative',
        width: '100%',
        height: '100%',
        background: '#FAFAF9',
        direction: 'rtl',
        fontFamily: '-apple-system, "SF Pro Text", "SF Pro Display", system-ui, sans-serif',
        color: '#111827',
        overflow: 'hidden',
        display: 'flex',
        flexDirection: 'column'
      }}>
      
      <Backdrop variant={tweaks.backdrop} accent={accent} />

      <div
        style={{
          position: 'relative',
          zIndex: 1,
          flex: 1,
          display: 'flex',
          flexDirection: 'column',
          padding: '24px 28px 36px',
          minHeight: 0
        }}>
        
        {/* Top: app icon + subtitle (wordmark is inside the icon) */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            alignItems: 'center',
            gap: 18,
            paddingTop: 36,
            paddingBottom: 40
          }}>
          
          <img
            src="assets/inspectley-icon.png"
            alt="Inspectley"
            width={132}
            height={132}
            style={{
              width: 132,
              height: 132,
              borderRadius: 30,
              display: 'block',
              boxShadow:
              '0 18px 40px rgba(12, 24, 52, 0.22), 0 4px 10px rgba(12, 24, 52, 0.10)'
            }} />
          
          <div
            style={{
              fontSize: 15.5,
              color: '#6B7280',
              fontWeight: 400,
              textAlign: 'center',
              letterSpacing: 0.1
            }}>מערכת לניהול דוחות


          </div>
        </div>

        {/* Form card */}
        <div
          style={{
            display: 'flex',
            flexDirection: 'column',
            gap: 14
          }}>
          
          <Field
            label="אימייל"
            value={email}
            onChange={setEmail}
            type="email"
            autoComplete="email"
            placeholder="name@company.com"
            ltr
            icon={<MailIcon />}
            focused={focused === 'email'}
            onFocus={() => setFocused('email')}
            onBlur={() => setFocused(null)}
            onKeyDown={(e) => e.key === 'Enter' && handleSubmit()} />
          

          {/* Password field with eye toggle */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <label
              style={{
                fontSize: 13,
                fontWeight: 500,
                color: '#6B7280',
                letterSpacing: 0.1,
                paddingInline: 4
              }}>
              
              סיסמה
            </label>
            <div
              style={{
                display: 'flex',
                alignItems: 'center',
                gap: 10,
                height: 52,
                padding: '0 14px',
                borderRadius: 14,
                background: '#FFFFFF',
                border: `1px solid ${
                errorMsg ?
                '#E5484D' :
                focused === 'pwd' ?
                'rgba(47,111,229,0.55)' :
                'rgba(60,60,67,0.18)'}`,

                boxShadow: focused === 'pwd' ? '0 0 0 4px rgba(47,111,229,0.12)' : 'none',
                transition: 'border-color 120ms ease, box-shadow 120ms ease',
                direction: 'ltr'
              }}>
              
              <span style={{ color: focused === 'pwd' ? accent : '#9CA3AF', display: 'flex' }}>
                <LockIcon />
              </span>
              <input
                type={showPwd ? 'text' : 'password'}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                onFocus={() => setFocused('pwd')}
                onBlur={() => setFocused(null)}
                onKeyDown={(e) => e.key === 'Enter' && handleSubmit()}
                autoComplete="current-password"
                dir="ltr"
                style={{
                  flex: 1,
                  minWidth: 0,
                  border: 'none',
                  outline: 'none',
                  background: 'transparent',
                  fontSize: 17,
                  color: '#111827',
                  fontFamily: '-apple-system, "SF Pro Text", system-ui, sans-serif',
                  textAlign: 'left',
                  letterSpacing: showPwd ? 0 : 2
                }} />
              
              <button
                onClick={() => setShowPwd((v) => !v)}
                aria-label={showPwd ? 'הסתר סיסמה' : 'הצג סיסמה'}
                style={{
                  border: 'none',
                  background: 'transparent',
                  padding: 4,
                  cursor: 'pointer',
                  color: '#9CA3AF',
                  display: 'flex'
                }}>
                
                <EyeIcon off={showPwd} />
              </button>
            </div>
          </div>

          {/* Error */}
          <div
            style={{
              minHeight: 24,
              display: 'flex',
              alignItems: 'center',
              gap: 8,
              paddingInline: 4,
              opacity: errorMsg ? 1 : 0,
              transform: errorMsg ? 'translateY(0)' : 'translateY(-2px)',
              transition: 'opacity 160ms ease, transform 160ms ease'
            }}>
            
            {errorMsg &&
            <>
                <AlertIcon />
                <span
                style={{
                  fontSize: 13.5,
                  color: '#C4232A',
                  fontWeight: 500
                }}>
                
                  {errorMsg}
                </span>
              </>
            }
          </div>

          {/* Submit */}
          <div style={{ marginTop: 4 }}>
            <PrimaryButton
              onClick={handleSubmit}
              loading={loading}
              disabled={!email || !password}
              accent={accent}>
              
              {loading ? 'מתחבר…' : 'התחברות'}
            </PrimaryButton>
          </div>

          {/* Helper text */}
          <div
            style={{
              marginTop: 6,
              textAlign: 'center',
              fontSize: 13.5,
              color: '#8A94A6'
            }}>
            
            נתקלת בבעיה?{' '}
            <span style={{ color: accent, fontWeight: 500 }}>
              פנה למנהל המערכת
            </span>
          </div>
        </div>

        {/* Footer spacer + version */}
        <div style={{ flex: 1 }} />
        <div
          style={{
            textAlign: 'center',
            fontSize: 11,
            color: '#B8BEC9',
            letterSpacing: 0.4,
            textTransform: 'uppercase',
            direction: 'ltr'
          }}>
          
          v1.0 · Secure sign-in
        </div>
      </div>
    </div>);

}

// ─── App root ─────────────────────────────────────────────────────────────
const DEFAULTS = /*EDITMODE-BEGIN*/{
  "accent": "blue",
  "state": "idle",
  "backdrop": "glow",
  "prefill": false,
  "dark": false
} /*EDITMODE-END*/;

function App() {
  const [tweaks, setTweak] = useTweaks(DEFAULTS);

  return (
    <div style={{
      width: '100%', minHeight: '100vh',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      padding: 24, boxSizing: 'border-box',
      background: 'radial-gradient(80% 60% at 50% 30%, #F2F2EE 0%, #E6E5E0 100%)'
    }}>
      <IOSDevice width={402} height={874} dark={false}>
        <IOSStatusBar dark={false} />
        <LoginScreen tweaks={tweaks} />
      </IOSDevice>

      <TweaksPanel title="Tweaks">
        <TweakSection label="Appearance">
          <TweakRadio
            label="Accent"
            value={tweaks.accent}
            onChange={(v) => setTweak('accent', v)}
            options={[
            { value: 'blue', label: 'Blue' },
            { value: 'orange', label: 'Orange' }]
            } />
          
          <TweakRadio
            label="Backdrop"
            value={tweaks.backdrop}
            onChange={(v) => setTweak('backdrop', v)}
            options={[
            { value: 'none', label: 'None' },
            { value: 'glow', label: 'Glow' },
            { value: 'blueprint', label: 'Blueprint' }]
            } />
          
        </TweakSection>
        <TweakSection label="State">
          <TweakRadio
            label="Button state"
            value={tweaks.state}
            onChange={(v) => setTweak('state', v)}
            options={[
            { value: 'idle', label: 'Idle' },
            { value: 'loading', label: 'Loading' },
            { value: 'error', label: 'Error' }]
            } />
          
          <TweakToggle
            label="Prefill fields"
            value={tweaks.prefill}
            onChange={(v) => setTweak('prefill', v)} />
          
        </TweakSection>
      </TweaksPanel>
    </div>);

}

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<App />);