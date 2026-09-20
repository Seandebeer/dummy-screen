import React from "react";
import { Image } from "@/components/ui/image";

// the app's "Dummy Phone" brush-stroke wordmark (uploaded artwork on black,
// which blends straight into the app's black background)
const LOGO_URL = "https://media.base44.com/images/public/6aadcd9ec1ee05040e66de73/9835aaea1_CFCBE4D7-CBA2-40A7-B425-6A8BE5C8A2D7.jpeg";

export default function BrandLogo() {
  return (
    <Image
      src={LOGO_URL}
      alt="Dummy Phone"
      fittingType="fit"
      className="h-10 w-[144px]"
    />
  );
}