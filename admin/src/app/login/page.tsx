import Link from "next/link";
import Image from "next/image";
import { LoginForm } from "@/components/login-form";
import { configured } from "@/lib/supabase";

export default function Login() {
  return (
    <main className="login-portal">
      <div className="login-topo-bg" aria-hidden="true" />
      <div className="login-frame">
        <section className="portal-card" aria-labelledby="login-title">
          <div className="portal-brand portal-artwork">
            <Image
              src="/login-logov3-centered.png"
              alt="BAHAlerto Admin - flood awareness landscape"
              fill
              sizes="(max-width: 740px) 100vw, 440px"
              priority
            />
          </div>
          <div className="portal-content">
            <h1 id="login-title">Login Portal</h1>
            <LoginForm />
            <p className="portal-recovery">
              Forgot your password?{" "}
              <Link href="/forgot-password">Reset it here</Link>
            </p>
          </div>
        </section>
        {!configured() && (
          <p className="portal-setup">
            Supabase is not connected.{" "}
            <Link href="/admin/dashboard">View setup preview</Link>
          </p>
        )}
      </div>
    </main>
  );
}
