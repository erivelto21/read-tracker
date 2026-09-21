import { describe, it, expect } from "vitest";
import { screen } from "@testing-library/react";
import { TitleTable } from "@/features/titles/components/TitleTable";
import { renderWithProviders } from "@/utils/test-utils";
import type { Title } from "@/features/titles/types";

const mockTitles: Title[] = [
  { id: "1", name: "Naruto", type: "manga", chapter: 127 },
  { id: "2", name: "The Hobbit", type: "book", chapter: 1, page: 214 },
];

describe("TitleTable", () => {
  it("renders a row for each title", () => {
    renderWithProviders(<TitleTable titles={mockTitles} />);

    const rows = screen.getAllByTestId("title-row");
    expect(rows).toHaveLength(2);
    expect(screen.getByText("Naruto")).toBeInTheDocument();
    expect(screen.getByText("The Hobbit")).toBeInTheDocument();
  });

  it("shows a dash when both chapter and page are absent", () => {
    const titles: Title[] = [{ id: "3", name: "Article X", type: "article" }];
    renderWithProviders(<TitleTable titles={titles} />);

    expect(screen.getByText("—")).toBeInTheDocument();
  });

  it("formats progress as Ch. X, P. Y when both are present", () => {
    renderWithProviders(<TitleTable titles={mockTitles} />);
    expect(screen.getByText("Ch. 1, P. 214")).toBeInTheDocument();
  });

  it("formats progress as Ch. X when only chapter is present", () => {
    renderWithProviders(<TitleTable titles={mockTitles} />);
    expect(screen.getByText("Ch. 127")).toBeInTheDocument();
  });

  it("shows hardcoded Reading status for every row", () => {
    renderWithProviders(<TitleTable titles={mockTitles} />);

    const statusCells = screen.getAllByText("Reading");
    expect(statusCells).toHaveLength(mockTitles.length);
  });

  it("shows empty-state message when titles array is empty", () => {
    renderWithProviders(<TitleTable titles={[]} />);

    expect(screen.getByTestId("title-table-empty")).toBeInTheDocument();
    expect(screen.getByText("No titles found.")).toBeInTheDocument();
  });
});
