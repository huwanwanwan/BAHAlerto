"use client";

import { useActionState } from "react";
import Image from "next/image";
import { linkGoogleAccount, signInWithGoogle, type ActionState } from "@/app/actions";

export function GoogleAuthButton({ mode }: { mode: "login" | "link" }) {
  const actionToRun = mode === "login" ? signInWithGoogle : linkGoogleAccount;
  const [state, action, pending] = useActionState<ActionState, FormData>(
    actionToRun,
    {},
  );
  return (
    <div className="google-auth-control">
      <form action={action}>
        <button className="google-auth-button" type="submit" disabled={pending}>
          <Image src="/google-logo.png" alt="" width={24} height={24}/>
          {pending
            ? "Connecting..."
            : mode === "login"
              ? "Continue with Google"
              : "Connect Google account"}
        </button>
      </form>
      {state.error && <p className="error-message" role="alert">{state.error}</p>}
    </div>
  );
}
