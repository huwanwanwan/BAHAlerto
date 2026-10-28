"use client";
import { useActionState } from "react";
import { review, type ActionState } from "@/app/actions";
import { Button } from "./ui/button";
export function ReviewForm({
  id,
  disabled,
}: {
  id: string;
  disabled: boolean;
}) {
  const [state, action, pending] = useActionState<ActionState, FormData>(
    review,
    {},
  );
  return (
    <form
      action={action}
      className="form-stack"
      onSubmit={(e) => {
        if (
          !confirm(
            "Record this review decision? Published observations are managed separately.",
          )
        )
          e.preventDefault();
      }}
    >
      <input name="id" type="hidden" value={id} />
      <label>
        Review decision
        <select name="decision" disabled={disabled}>
          <option value="verified">Verify report</option>
          <option value="rejected">Reject report</option>
          <option value="clarification">Request clarification</option>
        </select>
      </label>
      <label>
        Review reason / clarification request
        <textarea
          name="reason"
          minLength={5}
          maxLength={2000}
          required
          disabled={disabled}
        />
      </label>
      <p>
        Verification confirms review of the report. It does not convert
        estimated depth into a precise measurement or publish it automatically.
      </p>
      {state.error && (
        <p className="error-message" role="alert">
          {state.error}
        </p>
      )}
      {state.success && (
        <p className="success-message" role="status">
          {state.success}
        </p>
      )}
      <Button disabled={pending || disabled}>
        {pending ? "Saving..." : "Save decision"}
      </Button>
    </form>
  );
}
