import { FormEvent, useState } from "react";
import { Link, useLocation, useNavigate } from "react-router-dom";
import { useAuth } from "../context/AuthContext";
import AuthShell from "../components/AuthShell";
import PasswordInput from "../components/PasswordInput";

export default function Login() {
  const { login } = useAuth();
  const nav = useNavigate();
  const from = (useLocation().state as { from?: string } | null)?.from ?? "/";
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      const u = await login(String(f.get("email")), String(f.get("password")));
      nav(u.role === "ADMIN" ? "/admin" : from, { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Sign in"
      subtitle="Welcome back. Sign in to see your orders and saved try-ons."
      aside={<><h2>See it on before you buy</h2><p>Try any piece on a model or your own photo, then order in a few taps.</p></>}
    >
      <form onSubmit={submit} className="form" noValidate={false}>
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="email" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="current-password" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
      </form>
      <p className="auth-switch">New here? <Link to="/register" state={{ from }}>Create an account</Link></p>
      <p className="auth-switch"><Link to="/">Continue as guest</Link></p>
    </AuthShell>
  );
}
