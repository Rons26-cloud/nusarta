import { brand } from "@nusarta/config";

interface LogoProps {
  variant?: "mark" | "horizontal" | "icon";
  tone?: "light" | "dark";
  className?: string;
}

const LOGO_SRC = "/logo.png";

function LogoImage({
  alt,
  className = "",
}: {
  alt: string;
  className?: string;
}) {
  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={LOGO_SRC}
      alt={alt}
      width={36}
      height={36}
      className={`h-9 w-9 object-contain ${className}`}
    />
  );
}

export function Logo({
  variant = "horizontal",
  tone = "dark",
  className = "",
}: LogoProps) {
  if (variant === "icon" || variant === "mark") {
    return (
      <span className={`inline-flex items-center ${className}`}>
        <LogoImage alt={brand.name} />
      </span>
    );
  }

  const textColor = tone === "light" ? "text-on-brand" : "text-foreground";

  return (
    <span className={`inline-flex items-center gap-2.5 ${className}`}>
      <LogoImage alt="" />
      <span className="flex flex-col leading-none">
        <span
          className={`font-display text-xl font-bold tracking-[0.08em] ${textColor}`}
        >
          {brand.name}
        </span>
        <span
          className={`mt-0.5 text-[10px] tracking-[0.28em] uppercase ${
            tone === "light" ? "text-on-brand/80" : "text-muted-foreground"
          }`}
        >
          Keuangan Pribadi
        </span>
      </span>
    </span>
  );
}