import { FormEvent, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import AuthShell from "../components/AuthShell";
import PasswordInput from "../components/PasswordInput";

export default function Register() {
  const { register } = useAuth();
  const nav = useNavigate();
  const from = (useLocation().state as { from?: string } | null)?.from ?? "/";
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      await register({
        name: String(f.get("name")),
        email: String(f.get("email")),
        phone: String(f.get("phone") || "") || undefined,
        password: String(f.get("password")),
      });
      nav(from, { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Create your account"
      subtitle="Track orders, keep a wishlist and save your AI try-ons."
      aside={<><h2>Your jewellery, your way</h2><p>Mix earrings, necklaces and bangles into a full look, and see it on before you order.</p></>}
    >
      <form onSubmit={submit} className="form">
        <label className="field">
          <span className="field-label">Full name</span>
          <input name="name" required minLength={2} autoComplete="name" />
        </label>
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="email" />
        </label>
        <label className="field">
          <span className="field-label">Mobile number <span className="optional">(optional)</span></span>
          <input name="phone" type="tel" placeholder="07XXXXXXXX" pattern="0\d{9}" autoComplete="tel" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="new-password" minLength={6} hint="At least 6 characters" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Creating account…" : "Create account"}</button>
      </form>
      <p className="auth-switch">Already have an account? <Link to="/login" state={{ from }}>Sign in</Link></p>
    </AuthShell>
  );
}
