import { describe, expect, it, vi } from "vitest";
import { render, screen } from "@testing-library/react";
import { Logo } from "@nusarta/ui";

describe("Logo", () => {
  it("renders the NUSARTA wordmark", () => {
    render(<Logo variant="horizontal" />);
    expect(screen.getByText("NUSARTA")).toBeInTheDocument();
  });

  it("renders icon-only mark with accessible name", () => {
    render(<Logo variant="icon" />);
    expect(screen.getByRole("img")).toHaveAttribute("alt", "NUSARTA");
  });
});

vi.mock("next/font/google", () => ({
  Inter: () => ({ variable: "--font-inter" }),
  Plus_Jakarta_Sans: () => ({ variable: "--font-plus-jakarta" }),
}));