"use client";

import { ArrowLeft } from "lucide-react";
import { usePathname, useRouter } from "next/navigation";
import { useEffect, useRef } from "react";

export function BackNavigation() {
  const pathname = usePathname();
  const router = useRouter();
  const routes = useRef<string[]>([]);

  useEffect(() => {
    const history = routes.current;
    if (history[history.length - 1] === pathname) return;
    if (history.length > 1 && history[history.length - 2] === pathname) {
      history.pop();
    } else {
      history.push(pathname);
    }
  }, [pathname]);

  if (pathname === "/") return null;

  function goBack() {
    if (routes.current.length > 1) {
      router.back();
    } else {
      router.push("/");
    }
  }

  return (
    <div className="border-b border-border bg-background">
      <div className="mx-auto w-full max-w-7xl px-4 py-2 sm:px-6 lg:px-8">
        <button
          type="button"
          onClick={goBack}
          className="inline-flex min-h-11 items-center gap-2 rounded-lg px-3 text-sm font-medium text-muted-foreground transition-colors hover:bg-muted hover:text-foreground"
        >
          <ArrowLeft aria-hidden="true" className="h-4 w-4" />
          Kembali
        </button>
      </div>
    </div>
  );
}
