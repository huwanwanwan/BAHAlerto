"use client";
export default function ErrorPage({ reset }: { reset: () => void }) {
  return (
    <section className="panel">
      <h1>Workspace unavailable</h1>
      <p>
        Check your administrator permissions, database setup and connection. No
        data has been substituted.
      </p>
      <button className="button" onClick={reset}>
        Try again
      </button>
      <a href="/login">Return to login</a>
    </section>
  );
}
