import React from "react";
import { Image } from "@/components/ui/image";

// the app's "Dummy Phone" brush-stroke wordmark (uploaded artwork on black,
// which blends straight into the app's black background)
const LOGO_URL = "https://media.base44.com/images/public/6aadcd9ec1ee05040e66de73/83204be93_CFCBE4D7-CBA2-40A7-B425-6A8BE5C8A2D7.jpeg";

export default function BrandLogo() {
  return (
    <div>
      <Image
        src={LOGO_URL}
        alt="Dummy Phone"
        fittingType="fit"
        className="h-14 w-[201px]"
      />
      <div className="text-[10px] font-body uppercase tracking-[0.25em] text-muted-foreground -mt-1.5 ml-8">
        props mastertool
      </div>
    </div>
  );
}