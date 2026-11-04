import { database } from "@/lib/supabase";
import { LoginForm } from "./login-form";
import { Mail, ShieldCheck, UserRound } from "lucide-react";
import { GoogleAuthButton } from "./google-auth-button";
import Image from "next/image";

export async function SettingsWorkspace({connected,googleStatus}:{connected:boolean;googleStatus?:string}) {
  const user=connected?(await(await database()).auth.getUser()).data.user:null;
  const google=user?.identities?.filter(identity=>identity.provider==="google")??[];
  const name=String(user?.user_metadata?.full_name??user?.user_metadata?.name??"Administrator");
  const lastSignIn=user?.last_sign_in_at?new Date(user.last_sign_in_at).toLocaleString("en-PH",{timeZone:"Asia/Manila"}):"Not recorded";
  const googleMessage=googleStatus==="linked"?"Google account connected successfully.":googleStatus==="error"?"Google account could not be connected. Try again or check the Supabase OAuth settings.":undefined;
  return <div className="settings-workspace">
    <div className="page-heading"><div><span className="eyebrow">YOUR WORKSPACE</span><h1>Settings</h1><p>Manage your account, connected sign-in methods and security.</p></div></div>
    <section className="panel settings-profile"><div className="settings-avatar"><UserRound size={30}/></div><div><h2>{name}</h2><p><Mail size={15}/>{user?.email??"No account connected"}</p><span className="user-account-status is-active">{user?"Signed in":"Setup preview"}</span></div></section>
    <div className="settings-grid"><section className="panel"><div className="user-section-heading"><ShieldCheck size={20}/><h2>Connected Google accounts</h2></div><p className="user-section-description">Google identities linked to this administrator login.</p>{google.length?google.map(identity=><div className="google-account-card" key={identity.identity_id}><Image className="google-account-logo" src="/google-logo.png" alt="" width={38} height={38}/><div><strong>{String(identity.identity_data?.name??name)}</strong><p>{String(identity.identity_data?.email??user?.email??"Email unavailable")}</p></div><span className="user-account-status is-active">Connected</span></div>):<div className="settings-account-empty"><p>No Google account is linked to this login.</p><small>Your current sign-in method: {user?.app_metadata?.provider??"Not connected"}.</small></div>}{googleMessage&&<p className={googleStatus==="linked"?"success-message":"error-message"} role={googleStatus==="linked"?"status":"alert"}>{googleMessage}</p>}{google.length===0&&connected&&<GoogleAuthButton mode="link"/>}<p className="flood-levels-help">Last sign-in: {lastSignIn}</p></section>
    <section className="panel"><h2>Password &amp; security</h2><p className="user-section-description">Choose a password with at least 12 characters.</p>{connected?<LoginForm mode="password"/>:<p>Sign in after connecting the database.</p>}</section>
    </div>
  </div>;
}
