import { FormEvent, useState } from "react";
import { Navigate, useNavigate } from "react-router-dom";
import { useAuth } from "../../context/AuthContext";
import AuthShell from "../../components/AuthShell";
import PasswordInput from "../../components/PasswordInput";

export default function AdminLogin() {
  const { user, login, logout } = useAuth();
  const nav = useNavigate();
  const [err, setErr] = useState("");
  const [busy, setBusy] = useState(false);

  if (user?.role === "ADMIN") return <Navigate to="/admin" replace />;

  const submit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    const f = new FormData(e.currentTarget);
    setBusy(true); setErr("");
    try {
      const u = await login(String(f.get("email")), String(f.get("password")));
      if (u.role !== "ADMIN") {
        logout();
        throw new Error("This account doesn't have admin access.");
      }
      nav("/admin", { replace: true });
    } catch (e) {
      setErr((e as Error).message);
    } finally {
      setBusy(false);
    }
  };

  return (
    <AuthShell
      title="Admin sign in"
      subtitle="Manage products, orders and reports."
      aside={<><h2>Shop admin</h2><p>Confirm orders, update stock and see today's sales in one place.</p></>}
    >
      <form onSubmit={submit} className="form">
        <label className="field">
          <span className="field-label">Email</span>
          <input name="email" type="email" required autoComplete="username" />
        </label>
        <PasswordInput name="password" label="Password" autoComplete="current-password" />
        {err && <p className="form-error" role="alert">{err}</p>}
        <button className="btn btn-primary btn-block" disabled={busy}>{busy ? "Signing in…" : "Sign in"}</button>
      </form>
    </AuthShell>
  );
}
