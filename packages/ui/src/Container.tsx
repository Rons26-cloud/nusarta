import type { ReactNode } from "react";

interface ContainerProps {
  className?: string;
  children: ReactNode;
}

export function Container({ className = "", children }: ContainerProps) {
  return (
    <div className={`mx-auto w-full max-w-7xl px-4 sm:px-6 lg:px-8 ${className}`}>
      {children}
    </div>
  );
}
