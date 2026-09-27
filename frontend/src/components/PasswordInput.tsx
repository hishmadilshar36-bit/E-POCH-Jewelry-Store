import { useState } from "react";
import Icon from "./Icon";

type Props = { name: string; label: string; autoComplete: string; minLength?: number; hint?: string };

export default function PasswordInput({ name, label, autoComplete, minLength, hint }: Props) {
  const [show, setShow] = useState(false);
  return (
    <label className="field">
      <span className="field-label">{label}</span>
      <span className="input-wrap">
        <input name={name} type={show ? "text" : "password"} required minLength={minLength} autoComplete={autoComplete} />
        <button type="button" className="input-icon" aria-label={show ? "Hide password" : "Show password"} onClick={() => setShow(!show)}>
          <Icon name={show ? "eyeOff" : "eye"} size={18} />
        </button>
      </span>
      {hint && <span className="field-hint">{hint}</span>}
    </label>
  );
}
