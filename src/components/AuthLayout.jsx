import React from "react";

export default function AuthLayout({ icon: Icon, title, subtitle, footer, children }) {
  return (
    <div className="relative min-h-screen flex items-center justify-center bg-background px-4 grid-backdrop">
      <div className="absolute inset-0 pointer-events-none" style={{
        background: "radial-gradient(900px 420px at 50% -10%, hsl(var(--amber) / 0.07), transparent 65%)",
      }} />
      <div className="relative w-full max-w-md">
        <div className="text-center mb-10">
          <div className="inline-flex items-center justify-center w-14 h-14 rounded-2xl bg-gradient-to-b from-primary to-primary/60 shadow-lg shadow-primary/25 mb-4">
            <Icon className="w-7 h-7 text-primary-foreground" aria-hidden="true" />
          </div>
          <h1 className="text-3xl font-display font-semibold tracking-tight text-foreground">{title}</h1>
          {subtitle && <p className="text-sm text-muted-foreground mt-2">{subtitle}</p>}
        </div>
        <div className="rounded-3xl border border-border/70 bg-card/80 shadow-[0_20px_60px_rgba(0,0,0,0.45)] backdrop-blur-xl p-8">
          {children}
        </div>
        {footer && (
          <p className="text-center text-sm text-muted-foreground mt-6">{footer}</p>
        )}
      </div>
    </div>
  );
}