import * as React from "react";
import { cn } from "@/lib/utils";

export interface SkeletonProps extends React.HTMLAttributes<HTMLDivElement> {
  variant?: "rectangular" | "circular" | "text" | "rounded" | "pill";
  shimmer?: boolean;
}

export function Skeleton({
  className,
  variant = "rectangular",
  shimmer = true,
  ...props
}: SkeletonProps) {
  return (
    <div
      aria-hidden="true"
      className={cn(
        "skeleton",
        variant === "circular" && "skeleton-circle",
        variant === "text" && "skeleton-text",
        variant === "rounded" && "skeleton-rounded",
        variant === "pill" && "skeleton-pill",
        !shimmer && "skeleton-no-shimmer",
        className,
      )}
      {...props}
    />
  );
}

