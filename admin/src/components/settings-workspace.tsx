import { database } from "@/lib/supabase";
import { LoginForm } from "./login-form";
import { Mail, ShieldCheck, UserRound } from "lucide-react";

export async function SettingsWorkspace({connected}:{connected:boolean}) {
  const user=connected?(await(await database()).auth.getUser()).data.user:null;
  const name=String(user?.user_metadata?.full_name??user?.user_metadata?.name??"Administrator");
  const lastSignIn=user?.last_sign_in_at?new Date(user.last_sign_in_at).toLocaleString("en-PH",{timeZone:"Asia/Manila"}):"Not recorded";
  return <div className="settings-workspace">
    <div className="page-heading"><div><span className="eyebrow">YOUR WORKSPACE</span><h1>Settings</h1><p>Manage your account and security.</p></div></div>
    <section className="panel settings-profile"><div className="settings-avatar"><UserRound size={30}/></div><div><h2>{name}</h2><p><Mail size={15}/>{user?.email??"No account connected"}</p><span className="user-account-status is-active">{user?"Signed in":"Setup preview"}</span></div></section>
    <div className="settings-grid"><section className="panel"><div className="user-section-heading"><ShieldCheck size={20}/><h2>Account activity</h2></div><p className="flood-levels-help">Last sign-in: {lastSignIn}</p></section>
    <section className="panel"><h2>Password &amp; security</h2><p className="user-section-description">Choose a password with at least 12 characters.</p>{connected?<LoginForm mode="password"/>:<p>Sign in after connecting the database.</p>}</section>
    </div>
  </div>;
}
