import React from "react";
import { Image } from "@/components/ui/image";

// Dummy Screen wordmark. White artwork on black, blended into the home header.
const LOGO_URL = "/brand/dummy-screen-logo.jpg";

export default function BrandLogo() {
  return (
    <div>
      <Image
        src={LOGO_URL}
        alt="Dummy Screen"
        fittingType="fit"
        className="brand-logo-art h-14 w-auto max-w-[320px]"
      />
      <div className="brand-logo-tagline text-[7.5px] font-body uppercase tracking-[0.25em] text-foreground -mt-2 ml-8">
        props mastertool
      </div>
    </div>
  );
}
