"use client";
import { useActionState, useState } from "react";
import { Eye, EyeOff, ArrowRight } from "lucide-react";
import { login, forgot, changePassword, type ActionState } from "@/app/actions";
import { Button } from "./ui/button";
export function LoginForm({
  mode = "login",
}: {
  mode?: "login" | "recovery" | "password";
}) {
  const [show, setShow] = useState(false);
  const [state, action, pending] = useActionState<ActionState, FormData>(
    mode === "recovery" ? forgot : mode === "password" ? changePassword : login,
    {},
  );
  return (
    <form
      action={action}
      className={mode === "login" ? "form-stack portal-form" : "form-stack"}
    >
      {mode !== "password" && (
        <label>
          Email address
          <div className={mode === "login" ? "portal-input" : undefined}>
          <input
            name="email"
            type="email"
            autoComplete="email"
            required
          />
          </div>
        </label>
      )}
      {mode !== "recovery" && (
        <label>
          {mode === "password" ? "New password" : "Password"}
          <div className={mode === "login" ? "password-field portal-input" : "password-field"}>
            <input
              name="password"
              type={show ? "text" : "password"}
              autoComplete={
                mode === "password" ? "new-password" : "current-password"
              }
              minLength={mode === "password" ? 12 : 1}
              required
            />
            <button
              type="button"
              aria-label={show ? "Hide password" : "Show password"}
              onClick={() => setShow(!show)}
            >
              {show ? <EyeOff size={18} /> : <Eye size={18} />}
            </button>
          </div>
        </label>
      )}
      {mode === "login" && (
        <label className="show-password">
          <input
            type="checkbox"
            checked={show}
            onChange={(event) => setShow(event.target.checked)}
          />
          Show password
        </label>
      )}
      {state.error && (
        <p role="alert" className="error-message">
          {state.error}
        </p>
      )}
      {state.success && (
        <p role="status" className="success-message">
          {state.success}
        </p>
      )}
      <Button disabled={pending}>
        {pending
          ? "Please wait..."
          : mode === "recovery"
            ? "Send link"
            : mode === "password"
              ? "Update password"
              : "Sign in"}
        {mode !== "login" && <ArrowRight size={17} />}
      </Button>
    </form>
  );
}
