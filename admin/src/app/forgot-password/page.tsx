import { LoginForm } from "@/components/login-form";
import Link from "next/link";
export default function Page() {
  return (
    <main className="auth-simple">
      <h1>Recover your account</h1>
      <LoginForm mode="recovery" />
      <Link href="/login">Back to login</Link>
    </main>
  );
}
